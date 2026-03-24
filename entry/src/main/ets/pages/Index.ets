import { DailyForecastItem, ForecastItem, WeatherInfo, WeatherService } from '../services/WeatherService';
import { checkPermissionGrant, reqPermissionsFromUser } from '../services/PermissionManager';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';


@Entry
@Component
struct Index {
  @State loading: boolean = false;
  @State errorMsg: string = '';
  @State manualCity: string = '';
  @State weather: WeatherInfo = {
    city: '--',
    temperature: 0,
    windSpeed: 0,
    weatherCode: -1,
    updateTime: '--',
    forecast: [],
    weeklyForecast: [],
    dressingAdvice: ''
  };

  private weatherService: WeatherService = new WeatherService();

  async aboutToAppear(): Promise<void> {
    let grantStatus2: boolean = await checkPermissionGrant('ohos.permission.APPROXIMATELY_LOCATION') === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    if (!grantStatus2) {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      reqPermissionsFromUser(['ohos.permission.APPROXIMATELY_LOCATION'], ctx);
    }
    this.refreshByLocation();
  }

  private async refreshByLocation(): Promise<void> {
    this.loading = true;
    this.errorMsg = '';
    try {
      this.weather = await this.weatherService.queryCurrentCityWeather();
    } catch (error) {
      this.errorMsg = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async refreshByManualCity(): Promise<void> {
    if (!this.manualCity.trim()) {
      this.errorMsg = '请输入城市名称';
      return;
    }
    this.loading = true;
    this.errorMsg = '';
    try {
      this.weather = await this.weatherService.queryWeatherByCity(this.manualCity.trim());
    } catch (error) {
      this.errorMsg = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private weatherDescByCode(code: number): string {
    if (code === 0) return '晴';
    if (code >= 1 && code <= 3) return '多云';
    if (code >= 45 && code <= 48) return '雾';
    if (code >= 51 && code <= 67) return '雨';
    if (code >= 71 && code <= 77) return '雪';
    if (code >= 80 && code <= 99) return '阵雨/雷暴';
    return '未知';
  }

  private weatherIconByCode(code: number): string {
    if (code === 0) return '☀️';
    if (code >= 1 && code <= 3) return '⛅';
    if (code >= 45 && code <= 48) return '🌫️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '🌨️';
    if (code >= 80 && code <= 99) return '⛈️';
    return '❓';
  }

  private formatForecastTime(raw: string): string {
    const idx = raw.indexOf('T');
    if (idx >= 0 && raw.length >= idx + 6) {
      return raw.substring(idx + 1, idx + 6);
    }
    return raw;
  }

  private formatDailyDate(raw: string): string {
    // Open-Meteo daily time is usually "YYYY-MM-DD"
    if (raw && raw.length >= 10) {
      return raw.substring(5, 10);
    }
    return raw;
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('当前城市天气')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        TextInput({ placeholder: '输入城市，如 北京/上海', text: this.manualCity })
          .onChange((value: string) => {
            this.manualCity = value;
          })
          .width('90%')

        Row({ space: 10 }) {
          Button(this.loading ? '查询中...' : '按城市查询')
            .enabled(!this.loading)
            .onClick(() => {
              this.refreshByManualCity();
            })

          Button(this.loading ? '定位中...' : '定位查询')
            .enabled(!this.loading)
            .onClick(() => {
              this.refreshByLocation();
            })
        }

        Text(this.weather.city)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)

        Text(`${this.weatherIconByCode(this.weather.weatherCode)} ${this.weather.temperature.toFixed(1)}°C`)
          .fontSize(44)
          .fontWeight(FontWeight.Bold)

        Text(`天气: ${this.weatherDescByCode(this.weather.weatherCode)}`)
          .fontSize(18)

        Text(`风速: ${this.weather.windSpeed.toFixed(1)} km/h`)
          .fontSize(18)

        Text(`更新时间: ${this.weather.updateTime}`)
          .fontSize(14)
          .fontColor('#888888')

        if (this.weather.dressingAdvice) {
          Column({ space: 6 }) {
            Text('穿衣建议')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .margin({ top: 8 })

            Text(this.weather.dressingAdvice)
              .fontSize(14)
              .fontColor('#333333')
              .padding(12)
              .backgroundColor('#FFF7E6')
              .borderRadius(10)
              .width('90%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }

        if (this.errorMsg) {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor(Color.Red)
            .margin({ top: 8 })
        }

        Text('未来小时预报')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })

        ForEach(this.weather.forecast, (item: ForecastItem) => {
          Row() {
            Text(this.formatForecastTime(item.time))
              .width('25%')
            Text(this.weatherIconByCode(item.weatherCode))
              .width('20%')
            Text(`${item.temperature.toFixed(1)}°C`)
              .width('25%')
            Text(this.weatherDescByCode(item.weatherCode))
              .width('30%')
          }
          .width('90%')
          .padding({ top: 6, bottom: 6, left: 8, right: 8 })
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        })

        Text('未来一周预报')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })

        ForEach(this.weather.weeklyForecast, (item: DailyForecastItem) => {
          Row() {
            Text(this.formatDailyDate(item.date))
              .width('20%')
            Text(this.weatherIconByCode(item.weatherCode))
              .width('15%')
            Text(`${item.minTemperature.toFixed(0)}~${item.maxTemperature.toFixed(0)}°C`)
              .width('35%')
            Text(this.weatherDescByCode(item.weatherCode))
              .width('30%')
          }
          .width('90%')
          .padding({ top: 8, bottom: 8, left: 8, right: 8 })
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        })
      }
      .width('100%')
      .padding(20)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
