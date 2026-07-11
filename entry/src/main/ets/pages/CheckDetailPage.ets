/**
 * 核查详情页 - 展示完整核查报告
 */
import { router } from '@kit.ArkUI';
import { CheckRecord, RiskLevel, CheckCategory, FactSource } from '../engine/Types';

@Entry
@Component
struct CheckDetailPage {
  @State record: CheckRecord = {
    id: '',
    originalText: '',
    checkTime: Date.now(),
    riskLevel: RiskLevel.SAFE,
    score: 0,
    category: CheckCategory.GENERAL,
    summary: '',
    sources: [],
    suggestions: ''
  };
  @State riskColor: string = '#4CAF50';
  @State riskIcon: string = '✅';
  @State riskLabel: string = '内容可信';

  aboutToAppear(): void {
    // 从路由参数获取核查记录
    const params = (router.getParams() || {}) as Record<string, Object>;
    this.record.id = (params['recordId'] as string) || '';
    this.record.riskLevel = parseInt((params['riskLevel'] as string) || '0');
    this.record.summary = (params['summary'] as string) || '';
    this.updateRiskDisplay();
  }

  updateRiskDisplay(): void {
    switch (this.record.riskLevel) {
      case RiskLevel.SAFE:
        this.riskColor = '#4CAF50'; this.riskIcon = '✅'; this.riskLabel = '内容可信'; break;
      case RiskLevel.LOW:
        this.riskColor = '#F39C12'; this.riskIcon = '🟡'; this.riskLabel = '部分不实'; break;
      case RiskLevel.MEDIUM:
        this.riskColor = '#E67E22'; this.riskIcon = '🟠'; this.riskLabel = '高度可疑'; break;
      case RiskLevel.HIGH:
        this.riskColor = '#E74C3C'; this.riskIcon = '🔴'; this.riskLabel = '确认不实'; break;
      case RiskLevel.CRITICAL:
        this.riskColor = '#C0392B'; this.riskIcon = '⚠️'; this.riskLabel = '已确认诈骗'; break;
    }
  }

  build() {
    Column() {
      // 顶部风险标识
      Column() {
        Text(this.riskIcon)
          .fontSize(64)
          .margin({ bottom: 8 });
        Text(this.riskLabel)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.riskColor);
        Text(`可信度 ${this.record.score} 分`)
          .fontSize(22)
          .fontColor('#7F8C8D')
          .margin({ top: 4 });
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .padding(24)
      .margin({ top: 16, bottom: 16 });

      // 原文内容
      Column() {
        Text('原文内容')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 });
        Text(this.record.originalText)
          .fontSize(20)
          .fontColor('#34495E')
          .maxLines(6)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .padding(16)
      .margin({ bottom: 12 });

      // 核查结论
      Column() {
        Text('📋 核查结论')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 });
        Text(this.record.summary)
          .fontSize(20)
          .fontColor('#2C3E50')
          .lineHeight(28);
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .padding(16)
      .margin({ bottom: 12 });

      // 事实来源
      if (this.record.sources && this.record.sources.length > 0) {
        Column() {
          Text('📖 信息来源')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });

          ForEach(this.record.sources, (source: FactSource) => {
            Row() {
              Column() {
                Text(source.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium);
                Text(source.quote)
                  .fontSize(16)
                  .fontColor('#7F8C8D')
                  .maxLines(2);
              }
              .layoutWeight(1);
            }
            .width('100%')
            .padding(8)
            .border({ width: 1, color: '#ECF0F1' })
            .borderRadius(8)
            .margin({ bottom: 6 });
          });
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .padding(16)
        .margin({ bottom: 12 });
      }

      // 底部操作
      Row() {
        Button('📞 通知家人')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .width('45%')
          .height(56)
          .backgroundColor('#E74C3C')
          .borderRadius(28)
          .onClick(() => {
            // TODO: 通知家人
          });

        Button('返回首页')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .width('45%')
          .height(56)
          .backgroundColor('#95A5A6')
          .borderRadius(28)
          .onClick(() => {
            router.back(undefined);
          });
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16, bottom: 24 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF8F0');
  }
}

// 路由组件导出
export default CheckDetailPage;