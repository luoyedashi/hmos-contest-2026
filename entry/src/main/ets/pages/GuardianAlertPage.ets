/**
 * 家属预警详情页
 */
import { router } from '@kit.ArkUI';
import { RiskLevel } from '../engine/Types';

@Entry
@Component
struct GuardianAlertPage {
  @State alertTitle: string = '⚠️ 父母遇到可疑信息';
  @State alertBody: string = '';
  @State riskLevel: number = 0;

  aboutToAppear(): void {
    const params = (router.getParams() || {}) as Record<string, Object>;
    this.alertBody = (params['details'] as string) || '';
    this.riskLevel = parseInt((params['riskLevel'] as string) || '0');
  }

  build() {
    Column() {
      Text('⚠️')
        .fontSize(80)
        .margin({ top: 80, bottom: 20 });

      Text(this.alertTitle)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);

      Text(this.alertBody)
        .fontSize(22)
        .fontColor('#7F8C8D')
        .textAlign(TextAlign.Center)
        .margin({ top: 16, left: 24, right: 24 });

      Blank();

      Button('📞 给父母打电话')
        .fontSize(24)
        .width('80%')
        .height(60)
        .backgroundColor('#E74C3C')
        .borderRadius(30)
        .margin({ bottom: 12 })
        .onClick(() => {
          // TODO: 直接拨号
        });

      Button('📋 查看完整报告')
        .fontSize(24)
        .width('80%')
        .height(60)
        .backgroundColor('#2E86DE')
        .borderRadius(30)
        .margin({ bottom: 12 })
        .onClick(() => {
          router.back(undefined);
        });

      Button('✅ 我知道了')
        .fontSize(24)
        .width('80%')
        .height(60)
        .backgroundColor('#95A5A6')
        .borderRadius(30)
        .margin({ bottom: 40 })
        .onClick(() => {
          router.back(undefined);
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF8F0');
  }
}

export default GuardianAlertPage;