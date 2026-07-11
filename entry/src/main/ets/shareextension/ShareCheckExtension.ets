/**
 * 分享拦截Extension - 在用户分享时自动核查内容
 * 注册为系统分享目标，拦截分享数据并触发核查流程
 */
import { UIExtensionAbility, UIExtensionContentSession, UIExtensionAbilityWant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LocalRuleEngine } from '../engine/LocalRuleEngine';
import { CloudCheckEngine } from '../engine/CloudCheckEngine';
import { RiskLevel, CheckCategory, CheckRecord } from '../engine/Types';
import { AlertManager } from '../notification/AlertManager';
import { FamilyNotifier } from '../family/FamilyNotifier';

const TAG = 'ShareCheckExtension';

export default class ShareCheckExtension extends UIExtensionAbility {
  onCreate(): void {
    hilog.info(0x0000, TAG, 'ShareCheckExtension onCreate');
    // 确保引擎已初始化
    LocalRuleEngine.getInstance().initialize();
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'ShareCheckExtension onDestroy');
  }

  /**
   * 当用户选择"核查后分享"时触发
   */
  onSessionCreate(session: UIExtensionContentSession): void {
    hilog.info(0x0000, TAG, 'onSessionCreate - share data received');

    // 从分享数据中提取内容
    const shareData = session.getShareData();

    if (!shareData) {
      // 没有数据，直接放行
      session.terminateSelf();
      return;
    }

    // 获取分享文本
    const text = shareData.getPrimaryText() || '';
    const title = shareData.getTitle() || '';

    if (!text && !title) {
      // 只有图片/链接无文本，放行
      session.terminateSelf();
      return;
    }

    // 组合核查内容
    const contentToCheck = `${title} ${text}`.trim();

    // 启动核查流程
    this.handleShareCheck(session, contentToCheck);
  }

  /**
   * 核查主流程：本地规则 → 云端AI → 弹窗
   */
  private async handleShareCheck(session: UIExtensionContentSession, content: string): Promise<void> {
    try {
      // 第1层：本地规则引擎（<100ms）
      const localResult = LocalRuleEngine.getInstance().check(content);

      if (!localResult.isHit || localResult.riskLevel === RiskLevel.SAFE) {
        // 安全内容，直接放行
        hilog.info(0x0000, TAG, 'Content safe, pass through');
        // 显示"核查通过"轻提示
        AlertManager.showSafePass();
        session.terminateSelf();
        return;
      }

      // 创建核查记录
      const record: CheckRecord = {
        id: this.generateId(),
        originalText: content,
        checkTime: Date.now(),
        riskLevel: localResult.riskLevel,
        score: 0,
        category: localResult.category,
        summary: '',
        sources: [],
        suggestions: ''
      };

      // 高危内容直接弹窗，不等待云端
      if (localResult.riskLevel >= RiskLevel.HIGH) {
        record.summary = `本地规则检测到${LocalRuleEngine.getInstance().getRiskLabel(localResult.riskLevel)}：匹配关键词"${localResult.matchedKeywords.join('、')}"`;
        await AlertManager.showRiskAlert(record);
        session.terminateSelf();
        return;
      }

      // 中等风险：发起云端AI深度核查
      hilog.info(0x0000, TAG, 'Starting cloud check...');
      const cloudResult = await CloudCheckEngine.getInstance().deepCheck(
        content,
        localResult.category,
        3000 // 3秒超时
      );

      // 合并本地+云端结果
      record.riskLevel = Math.max(localResult.riskLevel, cloudResult.riskLevel);
      record.score = cloudResult.score;
      record.summary = cloudResult.summary;
      record.sources = cloudResult.sources;
      record.suggestions = record.riskLevel >= RiskLevel.HIGH ? '强烈建议不要分享' : '建议核实后再分享';
      record.correctedInfo = cloudResult.correctedInfo;

      // 根据风险等级展示不同弹窗
      if (record.riskLevel >= RiskLevel.HIGH) {
        await AlertManager.showRiskAlert(record);
        // 红色/橙色预警 → 通知家属
        await FamilyNotifier.getInstance().notifyGuardian(record);
      } else if (record.riskLevel === RiskLevel.MEDIUM) {
        AlertManager.showSuggestAlert(record);
      } else {
        AlertManager.showSafePass();
      }

    } catch (err) {
      hilog.error(0x0000, TAG, `Share check error: ${JSON.stringify(err)}`);
      // 出错时放行，避免阻断用户
      AlertManager.showSafePass();
    } finally {
      session.terminateSelf();
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    hilog.info(0x0000, TAG, 'onSessionDestroy');
  }

  private generateId(): string {
    return `ck_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}