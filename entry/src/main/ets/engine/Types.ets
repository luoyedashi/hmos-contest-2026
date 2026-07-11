/**
 * 信息卫士 - 核心数据类型定义
 */

// 风险等级枚举
export enum RiskLevel {
  SAFE = 0,       // 绿色 - 可信
  LOW = 1,        // 黄色 - 部分不实
  MEDIUM = 2,     // 橙色 - 高度可疑
  HIGH = 3,       // 红色 - 确认谣言/诈骗
  CRITICAL = 4    // 红色 - 已确认诈骗
}

// 核查分类
export enum CheckCategory {
  HEALTH = 'health',         // 健康信息
  FINANCE = 'finance',       // 金融信息
  POLICY = 'policy',         // 政策法规
  GENERAL = 'general',       // 一般谣言
  SCAM = 'scam'             // 网络诈骗
}

// 核查记录
export interface CheckRecord {
  id: string;
  originalText: string;       // 原文内容
  sourceApp?: string;         // 来源App
  checkTime: number;          // 核查时间戳
  riskLevel: RiskLevel;       // 风险等级
  score: number;              // 可信度评分 0-100
  category: CheckCategory;    // 分类
  summary: string;            // 核查结论摘要
  sources: FactSource[];      // 事实来源
  suggestions: string;        // 建议操作
  correctedInfo?: string;     // 正确信息
}

// 事实来源
export interface FactSource {
  name: string;               // 来源名称
  url?: string;               // 来源链接
  quote: string;              // 引用内容
  date: string;               // 发布日期
}

// 本地规则命中结果
export interface LocalRuleResult {
  isHit: boolean;
  riskLevel: RiskLevel;
  category: CheckCategory;
  matchedKeywords: string[];
  matchedPatterns: string[];
}

// 云端AI核查结果
export interface CloudCheckResult {
  score: number;
  riskLevel: RiskLevel;
  summary: string;
  sources: FactSource[];
  correctedInfo?: string;
}

// 家人守护关系
export interface GuardianRelation {
  id: string;
  elderId: string;           // 长辈设备ID
  guardianId: string;        // 子女设备ID
  elderPhone: string;        // 长辈手机号
  guardianPhone: string;     // 子女手机号
  bindTime: number;          // 绑定时间
  alertEnabled: boolean;     // 预警开关
  weeklyReport: boolean;     // 周报开关
}

// 预警通知
export interface RiskAlert {
  id: string;
  elderId: string;
  recordId: string;
  riskLevel: RiskLevel;
  sourceTitle: string;
  riskLabel: string;
  timestamp: number;
  details: string;
}