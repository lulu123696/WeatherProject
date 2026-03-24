import { weatherUiPalette, WeatherUiPalette } from '../utils/WeatherTheme';

@Component
export struct LifeAdviceTileView {
  @Prop emoji: string = '';
  @Prop titleStr: string = '';
  @Prop bodyStr: string = '';
  @Prop weatherCode: number = -1;

  private palette(): WeatherUiPalette {
    return weatherUiPalette(this.weatherCode);
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Text(this.emoji)
          .fontSize(24)
        Column({ space: 8 }) {
          Text(this.titleStr)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().hourlyChipText)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.palette().hourlyChipBg)
            .borderRadius(10)
            .borderWidth(1)
            .borderColor(this.palette().hourlyPillBorder)
          Text(this.bodyStr)
            .fontSize(13)
            .fontWeight(FontWeight.Regular)
            .fontColor(this.palette().adviceBody)
            .lineHeight(21)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .constraintSize({ minHeight: 108 })
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.palette().adviceInner)
    .borderRadius(16)
    .borderWidth(1)
    .borderColor(this.palette().hourlyPillBorder)
    .shadow({ radius: 12, color: this.palette().shadowSoft, offsetX: 0, offsetY: 4 })
    .alignItems(HorizontalAlign.Start)
  }
}
