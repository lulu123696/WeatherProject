import { router } from '@kit.ArkUI';
import { DailyForecastItem, WeatherInfo } from '../services/WeatherService';
import { WeeklyTrendChart } from '../components/WeeklyTrendChart';
import { weatherBackgroundGradient, weatherUiPalette, WeatherUiPalette } from '../utils/WeatherTheme';

interface DetailParams {
  weather?: WeatherInfo;
}

@Entry
@Component
struct WeatherDetail {
  @State weather: WeatherInfo = {
    city: '--',
    temperature: 0,
    apparentTemperature: 0,
    windSpeed: 0,
    humidity: 0,
    precipitationProbability: 0,
    pressure: 0,
    visibility: 0,
    uvIndex: 0,
    sunrise: '--',
    sunset: '--',
    weatherCode: -1,
    updateTime: '--',
    forecast: [],
    weeklyForecast: [],
    lifeAdvice: {
      dressing: '',
      travel: '',
      exercise: '',
      carWash: '',
      cold: '',
      laundry: ''
    }
  };

  @State private chartRefresh: number = 0;
  @State private daySheetOpen: boolean = false;
  @State private selectedDayForSheet: DailyForecastItem = {
    date: '',
    minTemperature: 0,
    maxTemperature: 0,
    precipitationProbability: 0,
    uvIndex: 0,
    sunrise: '--',
    sunset: '--',
    weatherCode: -1
  };

  aboutToAppear(): void {
    const params = router.getParams() as DetailParams;
    if (params && params.weather) {
      this.weather = params.weather;
    }
    this.chartRefresh++;
  }

  private palette(): WeatherUiPalette {
    return weatherUiPalette(this.weather.weatherCode);
  }

  private sheetPalette(): WeatherUiPalette {
    return weatherUiPalette(this.selectedDayForSheet.weatherCode);
  }

  private formatDailyDate(raw: string): string {
    return raw && raw.length >= 10 ? raw.substring(5, 10) : raw;
  }

  private formatFullDate(raw: string): string {
    if (!raw || raw.length < 10) {
      return raw;
    }
    const y = raw.substring(0, 4);
    const m = raw.substring(5, 7);
    const d = raw.substring(8, 10);
    return `${y}年${Number(m)}月${Number(d)}日`;
  }

  private formatClock(raw: string): string {
    const idx = raw.indexOf('T');
    return idx >= 0 && raw.length >= idx + 6 ? raw.substring(idx + 1, idx + 6) : raw;
  }

  private weatherIconByCode(code: number): string {
    if (code === 0) {
      return '☀️';
    }
    if (code >= 1 && code <= 3) {
      return '⛅';
    }
    if (code >= 45 && code <= 48) {
      return '🌫️';
    }
    if (code >= 51 && code <= 67) {
      return '🌧️';
    }
    if (code >= 71 && code <= 77) {
      return '🌨️';
    }
    if (code >= 80 && code <= 99) {
      return '⛈️';
    }
    return '❓';
  }

  private weatherDescByCode(code: number): string {
    if (code === 0) {
      return '晴';
    }
    if (code >= 1 && code <= 3) {
      return '多云';
    }
    if (code >= 45 && code <= 48) {
      return '雾';
    }
    if (code >= 51 && code <= 67) {
      return '雨';
    }
    if (code >= 71 && code <= 77) {
      return '雪';
    }
    if (code >= 80 && code <= 99) {
      return '阵雨/雷暴';
    }
    return '未知';
  }

  private openDayDetail(day: DailyForecastItem): void {
    this.selectedDayForSheet = {
      date: day.date,
      minTemperature: day.minTemperature,
      maxTemperature: day.maxTemperature,
      precipitationProbability: day.precipitationProbability,
      uvIndex: day.uvIndex,
      sunrise: day.sunrise,
      sunset: day.sunset,
      weatherCode: day.weatherCode
    };
    this.daySheetOpen = true;
  }

  @Builder
  buildDayDetailSheet(): void {
    Column({ space: 16 }) {
      Text(this.formatFullDate(this.selectedDayForSheet.date))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.sheetPalette().metricsTitle)
        .width('100%')
      Text(this.weather.city)
        .fontSize(14)
        .fontColor(this.sheetPalette().textSecondary)
        .width('100%')

      Row({ space: 16 }) {
        Text(this.weatherIconByCode(this.selectedDayForSheet.weatherCode))
          .fontSize(48)
        Column({ space: 8 }) {
          Text(this.weatherDescByCode(this.selectedDayForSheet.weatherCode))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.sheetPalette().textPrimary)
            .width('100%')
          Row({ space: 12 }) {
            Text(`最高 ${this.selectedDayForSheet.maxTemperature.toFixed(0)}°`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#B71C1C')
            Text(`最低 ${this.selectedDayForSheet.minTemperature.toFixed(0)}°`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#0D47A1')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 10 }) {
        this.dayDetailRow('💧', '降水概率（日最大）', `${this.selectedDayForSheet.precipitationProbability.toFixed(0)}%`)
        this.dayDetailRow('☀️', '紫外线（日最大）', `指数 ${this.selectedDayForSheet.uvIndex.toFixed(1)}`)
        this.dayDetailRow('🌅', '日出', this.formatClock(this.selectedDayForSheet.sunrise))
        this.dayDetailRow('🌇', '日落', this.formatClock(this.selectedDayForSheet.sunset))
      }
      .width('100%')
      .padding(14)
      .backgroundColor(this.sheetPalette().hourlyPillBg)
      .borderRadius(14)
      .borderWidth(1)
      .borderColor(this.sheetPalette().hourlyPillBorder)

      Text('以上为该日在 7 日预报中的汇总数据；逐小时与实况请在首页查看。')
        .fontSize(12)
        .fontColor(this.sheetPalette().textMuted)
        .lineHeight(18)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  dayDetailRow(emoji: string, caption: string, detailStr: string): void {
    Row({ space: 12 }) {
      Text(emoji)
        .fontSize(20)
      Column({ space: 4 }) {
        Text(caption)
          .fontSize(12)
          .fontColor(this.sheetPalette().textMuted)
          .width('100%')
        Text(detailStr)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.sheetPalette().textPrimary)
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 14 }) {
          Row({ space: 12 }) {
            Button('← 返回')
              .height(40)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().ghostBtnText)
              .backgroundColor(this.palette().ghostBtnBg)
              .borderWidth(1)
              .borderColor(this.palette().ghostBtnBorder)
              .borderRadius(14)
              .onClick(() => {
                router.back();
              })
            Column({ space: 4 }) {
              Text('7 日预报')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().pageTitle)
                .width('100%')
              Text(this.weather.city)
                .fontSize(14)
                .fontColor(this.palette().textSecondary)
                .width('100%')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('92%')
          .margin({ top: 20 })
          .alignItems(VerticalAlign.Center)

          Column({ space: 12 }) {
            Row() {
              Text('7 日气温趋势')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().metricsTitle)
                .layoutWeight(1)
              Text('折线')
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().hourlyChipText)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.palette().hourlyChipBg)
                .borderRadius(10)
                .borderWidth(1)
                .borderColor(this.palette().hourlyPillBorder)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row({ space: 24 }) {
              Row({ space: 6 }) {
                Text('━')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#C62828')
                Text('最高温')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.palette().textSecondary)
              }
              Row({ space: 6 }) {
                Text('━')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1565C0')
                Text('最低温')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.palette().textSecondary)
              }
            }
            .width('100%')

            WeeklyTrendChart({
              daily: this.weather.weeklyForecast,
              refreshId: this.chartRefresh,
              maxLineColor: '#C62828',
              minLineColor: '#1565C0'
            })
          }
          .width('92%')
          .padding(16)
          .backgroundColor(this.palette().hourlyModuleBg)
          .borderRadius(18)
          .borderWidth(1)
          .borderColor(this.palette().hourlyModuleBorder)
          .shadow({ radius: 20, color: this.palette().shadowCard, offsetX: 0, offsetY: 6 })

          Column({ space: 12 }) {
            Row() {
              Text('每日预报')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().metricsTitle)
                .layoutWeight(1)
              Text('7 天')
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().hourlyChipText)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.palette().hourlyChipBg)
                .borderRadius(10)
                .borderWidth(1)
                .borderColor(this.palette().hourlyPillBorder)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Text('点击任意一天查看当日汇总详情')
              .fontSize(12)
              .fontColor(this.palette().hourlyHint)
              .width('100%')

            ForEach(this.weather.weeklyForecast, (item: DailyForecastItem) => {
              Column({ space: 12 }) {
                Row() {
                  Column({ space: 6 }) {
                    Text(this.formatDailyDate(item.date))
                      .fontSize(17)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.palette().metricsTitle)
                    Text(this.weatherDescByCode(item.weatherCode))
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.palette().textMuted)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Text(this.weatherIconByCode(item.weatherCode))
                    .fontSize(34)
                  Column({ space: 4 }) {
                    Text(`${item.maxTemperature.toFixed(0)}°`)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#B71C1C')
                    Text(`${item.minTemperature.toFixed(0)}°`)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#0D47A1')
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                Row({ space: 10 }) {
                  Text(`降水 ${item.precipitationProbability.toFixed(0)}%`)
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().hourlyChipText)
                    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                    .backgroundColor(this.palette().hourlyChipBg)
                    .borderRadius(10)
                    .borderWidth(1)
                    .borderColor(this.palette().hourlyPillBorder)
                  Text(`UV ${item.uvIndex.toFixed(1)}`)
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().hourlyChipText)
                    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                    .backgroundColor(this.palette().hourlyChipBg)
                    .borderRadius(10)
                    .borderWidth(1)
                    .borderColor(this.palette().hourlyPillBorder)
                  Blank()
                    .layoutWeight(1)
                  Text('查看详情 ›')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().accentDeep)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.palette().hourlyPillBg)
              .borderRadius(16)
              .borderWidth(1)
              .borderColor(this.palette().hourlyPillBorder)
              .shadow({ radius: 10, color: this.palette().shadowSoft, offsetX: 0, offsetY: 3 })
              .alignItems(HorizontalAlign.Start)
              .onClick(() => {
                this.openDayDetail(item);
              })
            }, (item: DailyForecastItem) => item.date)
          }
          .width('92%')
          .padding({ bottom: 4 })
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 165,
      colors: weatherBackgroundGradient(this.weather.weatherCode)
    })
    .bindSheet($$this.daySheetOpen, this.buildDayDetailSheet(), {
      dragBar: true,
      showClose: true,
      blurStyle: BlurStyle.Thick,
      title: { title: '当日天气' },
      onDisappear: (): void => {
        this.daySheetOpen = false;
      }
    })
  }
}
