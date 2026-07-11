/**
 * 预警管理模块 - 全屏弹窗 + 语音播报 + 实况窗
 */
import { notificationManager } from '@kit.NotificationKit';
import { WantAgent, common } from '@kit.AbilityKit';
import { textToSpeech } from '@kit.AIKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CheckRecord, RiskLevel } from '../engine/Types';

const TAG = 'AlertManager';
const BUNDLE_NAME = 'com.infoguard.app';

export class AlertManager {
  /**
   * 显示全屏风险预警弹窗（红色/高危）
   */
  static async showRiskAlert(record: CheckRecord): Promise<void> {
    hilog.info(0x0000, TAG, `Showing RISK alert for: ${record.id}`);

    // 1. 构建跳转意图：点击通知 → 核查详情页
    const wantAgent = await AlertManager.createWantAgent('CheckDetailAbility', {
      recordId: record.id,
      riskLevel: record.riskLevel.toString(),
      summary: record.summary
    });

    // 2. 发布全屏通知（不可忽略）
    const notificationRequest: notificationManager.NotificationRequest = {
      id: Date.now(),
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: record.riskLevel >= RiskLevel.CRITICAL
            ? '⚠️ 检测到诈骗信息！'
            : '🔴 这条消息可能不实',
          text: record.summary.substring(0, 100)
        },
        locked: {
          title: record.riskLevel >= RiskLevel.CRITICAL
            ? '⚠️ 诈骗预警'
            : '🔴 不实信息预警',
          text: record.summary.substring(0, 100)
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      isOngoing: true,           // 常驻通知
      isUnremovable: true,       // 不可滑动删除
      showDeliveryTime: true,
      wantAgent: wantAgent,
      color: 0xFF4444,           // 红色
      isFloatingIcon: true       // 悬浮图标
    };

    try {
      await notificationManager.publish(notificationRequest);
      hilog.info(0x0000, TAG, 'Risk notification published');
    } catch (err) {
      hilog.error(0x0000, TAG, `Publish failed: ${JSON.stringify(err)}`);
    }

    // 3. 语音播报（异步，不阻塞）
    AlertManager.speakAlert(record);

    // 4. 震动反馈
    try {
      const vibrator = await import('@ohos.vibrator');
      vibrator.vibrate(200);
    } catch (e) {
      // 震动非必需
    }
  }

  /**
   * 显示建议提醒弹窗（橙色/中度风险）
   */
  static showSuggestAlert(record: CheckRecord): void {
    hilog.info(0x0000, TAG, `Showing SUGGEST alert for: ${record.id}`);

    // 轻量通知，不打断操作
    notificationManager.publish({
      id: Date.now(),
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '🔍 该消息可能不可靠',
          text: record.summary.substring(0, 80)
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      isOngoing: false,
      isUnremovable: false
    });
  }

  /**
   * 显示核查通过轻提示
   */
  static showSafePass(): void {
    hilog.info(0x0000, TAG, 'Showing safe pass toast');
    // 使用简短通知（3秒后消失）
    notificationManager.publish({
      id: Date.now(),
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '✅ 核查通过',
          text: '该内容可信，可以放心分享'
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      isOngoing: false,
      isUnremovable: false
    });
  }

  /**
   * 语音播报核查结果
   */
  private static async speakAlert(record: CheckRecord): Promise<void> {
    try {
      const ttsEngine = await textToSpeech.createEngine({
        language: 'zh-CN',
        person: 1,     // 温和女声
        speed: 0.8,    // 0.8倍速
        volume: 1.0,
        pitch: 1.0
      });

      const speechText = AlertManager.buildSpeechText(record);
      await ttsEngine.speak(speechText);
    } catch (err) {
      hilog.error(0x0000, TAG, `TTS failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 构建语音文本（银龄友好：结论前置）
   */
  private static buildSpeechText(record: CheckRecord): string {
    if (record.riskLevel >= RiskLevel.CRITICAL) {
      return '请注意！这是一个诈骗信息，已经帮您拦截了。建议不要转发。如果需要，我可以帮您通知家人。';
    } else if (record.riskLevel >= RiskLevel.HIGH) {
      return '您好，这条消息被核实为不实信息。' + record.summary + '建议您不要转发。';
    } else if (record.riskLevel >= RiskLevel.MEDIUM) {
      return '您好，这条消息可能不太可靠。' + record.summary + '您要了解一下详细情况吗？';
    }
    return '经过核实，这条信息是可以相信的。您可以放心分享。';
  }

  /**
   * 创建WantAgent用于通知点击跳转
   */
  private static async createWantAgent(abilityName: string, params: Record<string, string>): Promise<WantAgent.WantAgent> {
    const wantAgentInfo: WantAgent.WantAgentInfo = {
      wants: [{
        bundleName: BUNDLE_NAME,
        abilityName: abilityName,
        parameters: params
      }],
      operationType: WantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [WantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    return await WantAgent.getWantAgent(wantAgentInfo);
  }
}