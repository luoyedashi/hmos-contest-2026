/**
 * 家人守护通知模块
 * 通过PushKit向绑定家属推送预警，支持碰一碰绑定
 */
import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CheckRecord, GuardianRelation, RiskLevel } from '../engine/Types';
import { relationalStore } from '@kit.ArkData';

const TAG = 'FamilyNotifier';

export class FamilyNotifier {
  private static instance: FamilyNotifier;

  static getInstance(): FamilyNotifier {
    if (!FamilyNotifier.instance) {
      FamilyNotifier.instance = new FamilyNotifier();
    }
    return FamilyNotifier.instance;
  }

  /**
   * 通知所有绑定的家属
   */
  async notifyGuardian(record: CheckRecord): Promise<void> {
    hilog.info(0x0000, TAG, `Notifying guardians for record: ${record.id}`);

    try {
      const guardians = await this.getGuardians();

      if (guardians.length === 0) {
        hilog.info(0x0000, TAG, 'No guardians bound, skip notification');
        return;
      }

      const riskLabel = this.getRiskLabel(record.riskLevel);

      for (const guardian of guardians) {
        await this.sendPushNotification(guardian, {
          id: record.id,
          riskLevel: record.riskLevel,
          sourceTitle: this.truncateText(record.originalText, 30),
          riskLabel: riskLabel,
          timestamp: record.checkTime,
          details: record.summary
        });
      }

      hilog.info(0x0000, TAG, `Notified ${guardians.length} guardians`);
    } catch (err) {
      hilog.error(0x0000, TAG, `Notify guardians failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 通过PushKit发送推送通知
   */
  private async sendPushNotification(guardian: GuardianRelation, alert: {
    id: string;
    riskLevel: RiskLevel;
    sourceTitle: string;
    riskLabel: string;
    timestamp: number;
    details: string;
  }): Promise<void> {
    const notificationTitle = alert.riskLevel >= RiskLevel.HIGH
      ? '⚠️ 父母遇到可疑信息'
      : '🔍 父母查看了一条可疑信息';

    const notificationBody = `"${alert.sourceTitle}" 被判为${alert.riskLabel}`;

    try {
      await pushService.sendMessage({
        target: guardian.guardianId,
        notification: {
          title: notificationTitle,
          body: notificationBody,
          clickAction: {
            actionType: pushService.ActionType.OPEN_ABILITY,
            abilityName: 'GuardianAlertAbility',
            parameters: {
              alertId: alert.id,
              riskLevel: alert.riskLevel.toString(),
              details: alert.details
            }
          }
        },
        data: {
          alertId: alert.id,
          riskLevel: alert.riskLevel.toString(),
          timestamp: alert.timestamp.toString()
        },
        priority: pushService.PushPriority.HIGH
      });

      hilog.info(0x0000, TAG, `Push sent to guardian: ${guardian.guardianPhone}`);
    } catch (err) {
      hilog.error(0x0000, TAG, `Push send failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 获取绑定的家属列表
   */
  private async getGuardians(): Promise<GuardianRelation[]> {
    try {
      const store = await this.getStore();
      const predicates = new relationalStore.RdbStorePredicates('guardian_relations');
      predicates.equalTo('elderId', this.getDeviceId());

      const resultSet = await store.query(predicates, ['*']);
      const guardians: GuardianRelation[] = [];

      while (resultSet.goToNextRow()) {
        guardians.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          elderId: resultSet.getString(resultSet.getColumnIndex('elderId')),
          guardianId: resultSet.getString(resultSet.getColumnIndex('guardianId')),
          elderPhone: resultSet.getString(resultSet.getColumnIndex('elderPhone')),
          guardianPhone: resultSet.getString(resultSet.getColumnIndex('guardianPhone')),
          bindTime: resultSet.getLong(resultSet.getColumnIndex('bindTime')),
          alertEnabled: resultSet.getLong(resultSet.getColumnIndex('alertEnabled')) === 1,
          weeklyReport: resultSet.getLong(resultSet.getColumnIndex('weeklyReport')) === 1
        });
      }
      resultSet.close();

      return guardians;
    } catch (err) {
      hilog.error(0x0000, TAG, `Query guardians failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 初始化家人数据库
   */
  private async getStore(): Promise<relationalStore.RdbStore> {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'infoguard.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    return await relationalStore.getRdbStore(undefined as unknown as relationalStore.StoreConfig, storeConfig);
  }

  // 工具方法
  private getRiskLabel(level: RiskLevel): string {
    const labels: Record<number, string> = {
      [RiskLevel.SAFE]: '内容可信',
      [RiskLevel.LOW]: '部分不实',
      [RiskLevel.MEDIUM]: '高度可疑',
      [RiskLevel.HIGH]: '确认不实',
      [RiskLevel.CRITICAL]: '诈骗信息'
    };
    return labels[level] || '可疑信息';
  }

  private truncateText(text: string, maxLen: number): string {
    return text.length > maxLen ? text.substring(0, maxLen) + '...' : text;
  }

  private getDeviceId(): string {
    // 实际项目中从系统获取设备ID
    return 'local_device_id';
  }
}