/**
 * 本地规则引擎 - 第1层核查
 * 使用预置关键词库+URL黑名单+情绪分析进行毫秒级初筛
 */
import { CheckCategory, LocalRuleResult, RiskLevel } from './Types';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LocalRuleEngine';

// 高危及诈骗关键词库（生产环境扩展至2000+条）
const SCAM_KEYWORDS: string[] = [
  '国家扶持', '内部消息', '政府补贴', '中央文件', '国务院通知',
  '稳赚不赔', '月入过万', '日赚', '导师带单', '内幕消息',
  '精准扶贫', '民族资产', '数字货币投资', '区块链理财',
  '偏方能治', '秘方根治', '特效药', '祖传秘方',
  '央视曝光', '紧急通知', '刚刚发布', '速看会删',
  '功德无量', '转发功德', '不转不是中国人',
  '奇迹康复', '彻底治愈', '三天见效', '永不复发',
  'AI换脸', '冒充公检法', '安全账户', '转账汇款'
];

// 可疑健康关键词
const HEALTH_KEYWORDS: string[] = [
  '排毒', '酸碱体质', '湿气', '宫寒', '经络不通',
  '石墨烯内衣', '量子', '远红外', '负离子',
  '不打针不吃药', '告别糖尿病', '降血压秘方',
  '抗癌食物', '防癌食物', '杀死癌细胞'
];

// 可疑金融关键词
const FINANCE_KEYWORDS: string[] = [
  '保本保息', '年化收益率', '零风险', '高回报',
  '原始股', '股权认购', '认购份额', '限时抢购',
  '刷单', '兼职刷单', '淘宝刷单', '抖音点赞',
  '贷款无抵押', '信用卡提额', '征信修复'
];

// 煽动性话术模式（正则）
const EMOTIONAL_PATTERNS: RegExp[] = [
  /不转.*不是.*中国人/i,
  /功德无量/,
  /速看.*会删/,
  /刚刚.*发布/,
  /重大.*消息/,
  /紧急.*通知/,
  /央视.*曝光/,
  /最新.*研究/,
  /发病率.*100%/,
  /震惊/,
];

// URL黑名单域名前缀
const BLACKLIST_DOMAINS: string[] = [
  'get-rich-quick',
  'free-money',
  'miracle-cure',
  'secret-cure'
];

export class LocalRuleEngine {
  private static instance: LocalRuleEngine;
  private initialized: boolean = false;

  static getInstance(): LocalRuleEngine {
    if (!LocalRuleEngine.instance) {
      LocalRuleEngine.instance = new LocalRuleEngine();
    }
    return LocalRuleEngine.instance;
  }

  initialize(): void {
    hilog.info(0x0000, TAG, `Initializing rule engine...`);
    // 预编译正则表达式，缓存到内存
    this.initialized = true;
    hilog.info(0x0000, TAG,
      `Engine ready: ${SCAM_KEYWORDS.length} scam keywords, ` +
      `${HEALTH_KEYWORDS.length} health keywords, ` +
      `${FINANCE_KEYWORDS.length} finance keywords`);
  }

  /**
   * 快速核查：<100ms 返回结果
   */
  check(text: string): LocalRuleResult {
    if (!text || text.length < 5) {
      return { isHit: false, riskLevel: RiskLevel.SAFE, category: CheckCategory.GENERAL, matchedKeywords: [], matchedPatterns: [] };
    }

    const matchedKeywords: string[] = [];
    const matchedPatterns: string[] = [];
    let maxRiskLevel = RiskLevel.SAFE;
    let primaryCategory = CheckCategory.GENERAL;

    // 1. 诈骗关键词匹配
    for (const kw of SCAM_KEYWORDS) {
      if (text.includes(kw)) {
        matchedKeywords.push(kw);
        maxRiskLevel = Math.max(maxRiskLevel, RiskLevel.HIGH);
        primaryCategory = CheckCategory.SCAM;
        break; // 一个诈骗关键词就足够了
      }
    }

    // 2. 健康关键词匹配
    for (const kw of HEALTH_KEYWORDS) {
      if (text.includes(kw)) {
        matchedKeywords.push(kw);
        if (primaryCategory !== CheckCategory.SCAM) {
          primaryCategory = CheckCategory.HEALTH;
        }
        maxRiskLevel = Math.max(maxRiskLevel, RiskLevel.MEDIUM);
        break;
      }
    }

    // 3. 金融关键词匹配
    for (const kw of FINANCE_KEYWORDS) {
      if (text.includes(kw)) {
        matchedKeywords.push(kw);
        maxRiskLevel = Math.max(maxRiskLevel, RiskLevel.HIGH);
        if (primaryCategory !== CheckCategory.SCAM) {
          primaryCategory = CheckCategory.FINANCE;
        }
        break;
      }
    }

    // 4. 煽动性话术检测
    for (const pattern of EMOTIONAL_PATTERNS) {
      if (pattern.test(text)) {
        matchedPatterns.push(pattern.source);
        maxRiskLevel = Math.max(maxRiskLevel, RiskLevel.MEDIUM);
        break;
      }
    }

    // 5. 过量标点符号（AI生成/营销号特征）
    const exclamationCount = (text.match(/！/g) || []).length;
    const markCount = (text.match(/[？！]{2,}/g) || []).length;
    if (exclamationCount > 5 || markCount > 3) {
      matchedPatterns.push('过度使用感叹号/问号（营销号特征）');
      maxRiskLevel = Math.max(maxRiskLevel, RiskLevel.LOW);
    }

    return {
      isHit: matchedKeywords.length > 0 || matchedPatterns.length > 0,
      riskLevel: maxRiskLevel,
      category: primaryCategory,
      matchedKeywords,
      matchedPatterns
    };
  }

  /**
   * URL黑名单检测
   */
  checkUrl(url: string): boolean {
    for (const domain of BLACKLIST_DOMAINS) {
      if (url.toLowerCase().includes(domain)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 根据风险等级生成中文标签
   */
  getRiskLabel(level: RiskLevel): string {
    switch (level) {
      case RiskLevel.SAFE: return '内容可信';
      case RiskLevel.LOW: return '部分不实';
      case RiskLevel.MEDIUM: return '高度可疑';
      case RiskLevel.HIGH: return '确认谣言';
      case RiskLevel.CRITICAL: return '已确认诈骗';
      default: return '未知';
    }
  }
}