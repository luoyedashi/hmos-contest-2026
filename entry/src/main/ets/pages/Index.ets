/**
 * 信息卫士首页
 * 安全分展示 + 核查记录时间线 + 一键语音核查
 */
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State safetyScore: number = 92;
  @State weeklyStatus: string = '良好';
  @State checkRecords: Array<CheckRecordItem> = [];

  aboutToAppear(): void {
    // 加载核查记录
    this.loadRecords();
  }

  loadRecords(): void {
    // TODO: 从本地数据库加载
    this.checkRecords = [
      { id: '1', time: '3小时前', level: 'high', icon: '⚠️', title: '"养老金上调"不实信息', desc: '已帮您拦截' },
      { id: '2', time: '昨天', level: 'safe', icon: '✅', title: '"三伏天养生建议"', desc: '已验证，内容可信' },
      { id: '3', time: '7月8日', level: 'critical', icon: '🔴', title: '"高回报投资理财"', desc: '确认为诈骗，已通知女儿' }
    ];
  }

  build() {
    Column() {
      // 顶部安全分卡片
      Column() {
        Text('🛡️')
          .fontSize(48)
          .margin({ bottom: 8 });
        Text(this.safetyScore.toString())
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2E86DE');
        Text(`本周信息安全状态：${this.weeklyStatus}`)
          .fontSize(22)
          .fontColor('#7F8C8D')
          .margin({ top: 4 });
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .padding(24)
      .shadow({ radius: 8, color: '#00000010' })
      .margin({ top: 16, bottom: 16 });

      // 快捷操作
      Row() {
        Button() {
          Column() {
            Text('📋').fontSize(32);
            Text('手动核查').fontSize(20);
          }
        }
        .width('45%')
        .height(100)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ManualCheck' });
        });

        Button() {
          Column() {
            Text('📚').fontSize(32);
            Text('防骗课堂').fontSize(20);
          }
        }
        .width('45%')
        .height(100)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .onClick(() => {
          router.pushUrl({ url: 'pages/LearningCenter' });
        });
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 16 });

      // 核查记录时间线
      Text('最近核查记录')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .margin({ left: '5%', bottom: 8 });

      Column() {
        ForEach(this.checkRecords, (record: CheckRecordItem) => {
          Row() {
            Text(record.icon)
              .fontSize(28)
              .width(40);
            Column() {
              Text(record.title)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
              Row() {
                Text(record.time)
                  .fontSize(16)
                  .fontColor('#95A5A6');
                Text(' · ')
                  .fontSize(16)
                  .fontColor('#95A5A6');
                Text(record.desc)
                  .fontSize(16)
                  .fontColor('#7F8C8D');
              };
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ bottom: 8 });
        });
      }
      .width('90%');

      // 底部语音按钮
      Button() {
        Row() {
          Text('🎙️')
            .fontSize(28)
            .margin({ right: 8 });
          Text('按住说话，小艺帮您核查')
            .fontSize(24)
            .fontWeight(FontWeight.Medium);
        };
      }
      .width('90%')
      .height(64)
      .backgroundColor('#2E86DE')
      .borderRadius(32)
      .margin({ top: 16, bottom: 16 })
      .onClick(() => {
        // TODO: 启动小艺语音核查
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF8F0');
  }
}

interface CheckRecordItem {
  id: string;
  time: string;
  level: string;
  icon: string;
  title: string;
  desc: string;
}