import { weatherUiPalette, WeatherUiPalette } from '../utils/WeatherTheme';

/** 独立组件：避免 @Builder 内对父组件状态的追踪异常导致指标不刷新 */
@Component
export struct KeyMetricTileView {
  @Prop emoji: string = '';
  @Prop caption: string = '';
  @Prop detail: string = '';
  @Prop weatherCode: number = -1;

  private palette(): WeatherUiPalette {
    return weatherUiPalette(this.weatherCode);
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.emoji)
          .fontSize(22)
        Column({ space: 4 }) {
          Text(this.caption)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textMuted)
            .width('100%')
          Text(this.detail)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().metricsTitle)
            .lineHeight(22)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .constraintSize({ minHeight: 96 })
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(this.palette().hourlyPillBg)
    .borderRadius(14)
    .borderWidth(1)
    .borderColor(this.palette().hourlyPillBorder)
    .shadow({ radius: 8, color: this.palette().shadowSoft, offsetX: 0, offsetY: 2 })
  }
}
