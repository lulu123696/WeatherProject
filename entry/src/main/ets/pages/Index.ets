import { ForecastItem, WeatherInfo, WeatherService } from '../services/WeatherService';
import {
  checkPermissionGrant,
  openApplicationPermissionSettings,
  requestPermissionsFromUserAsync
} from '../services/PermissionManager';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { CityStore } from '../services/CityStore';
import { CityHubPanel } from '../components/CityHubPanel';
import { KeyMetricTileView } from '../components/KeyMetricTileView';
import { LifeAdviceTileView } from '../components/LifeAdviceTileView';
import { weatherBackgroundGradient, weatherUiPalette, WeatherUiPalette } from '../utils/WeatherTheme';

const APPROX_LOCATION_PERMISSION: Permissions = 'ohos.permission.APPROXIMATELY_LOCATION';

interface DetailParams {
  weather: WeatherInfo;
}


@Entry
@Component
struct Index {
  @State loading: boolean = false;
  @State errorMsg: string = '';
  @State manualCity: string = '';
  @State cityHubOpen: boolean = false;
  /** 仅打开半模态时递增，供面板重置搜索框草稿 */
  @State cityHubSession: number = 0;
  /** 触发半模态内列表与 CityStore 同步刷新 */
  @State cityHubTick: number = 0;
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

  private weatherService: WeatherService = new WeatherService();
  /** 用户曾拒绝定位：从设置开启后回到界面时自动再拉一次定位天气 */
  private pendingRelocateAfterGrant: boolean = false;

  private palette(): WeatherUiPalette {
    return weatherUiPalette(this.weather.weatherCode);
  }

  onPageShow(): void {
    void this.handlePageShowAsync();
  }

  private async handlePageShowAsync(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await CityStore.ensureLoaded(ctx);
    await this.tryRelocateAfterPermissionGrantedAsync();
    await this.syncSelectedCityFromStoreAsync();
  }

  private async tryRelocateAfterPermissionGrantedAsync(): Promise<void> {
    if (!this.pendingRelocateAfterGrant) {
      return;
    }
    const granted =
      await checkPermissionGrant(APPROX_LOCATION_PERMISSION) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    if (!granted) {
      return;
    }
    await this.refreshByLocation();
  }

  /** 从城市管理返回不会触发 aboutToAppear，需在 onPageShow 同步 CityStore 并刷新 */
  private async syncSelectedCityFromStoreAsync(): Promise<void> {
    const storeCity = CityStore.getCurrentCity();
    if (!storeCity) {
      return;
    }
    if (storeCity === this.manualCity.trim()) {
      return;
    }
    this.manualCity = storeCity;
    await this.refreshByManualCity();
  }

  private showLocationPermissionSettingsGuide(context: common.UIAbilityContext): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '需要位置权限',
      message: '定位授权被拒绝或未开启，无法按定位获取天气。请前往系统设置，在本应用的权限中打开「大致位置」。',
      buttons: [
        { text: '知道了', color: this.palette().dialogNeutral },
        { text: '去设置', color: this.palette().dialogAccent }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        openApplicationPermissionSettings(context).catch((): void => {
        });
      }
    }).catch((): void => {
    });
  }

  private async ensureLocationPermission(): Promise<boolean> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const granted =
      await checkPermissionGrant(APPROX_LOCATION_PERMISSION) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    if (granted) {
      return true;
    }
    const ok = await requestPermissionsFromUserAsync([APPROX_LOCATION_PERMISSION], ctx);
    if (ok) {
      return true;
    }
    this.pendingRelocateAfterGrant = true;
    this.showLocationPermissionSettingsGuide(ctx);
    this.errorMsg = '定位权限未开启，请到设置中为本应用打开「大致位置」权限';
    return false;
  }

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await CityStore.ensureLoaded(ctx);
    const selectedCity = CityStore.getCurrentCity();
    if (selectedCity) {
      this.manualCity = selectedCity;
      this.refreshByManualCity();
      return;
    }
    const ok = await this.ensureLocationPermission();
    if (ok) {
      this.refreshByLocation();
    }
  }

  private async refreshByLocation(): Promise<void> {
    const ok = await this.ensureLocationPermission();
    if (!ok) {
      return;
    }
    this.pendingRelocateAfterGrant = false;
    this.loading = true;
    this.errorMsg = '';
    try {
      this.weather = await this.weatherService.queryCurrentCityWeather();
      CityStore.setCurrentCity(this.weather.city);
      this.manualCity = this.weather.city;
    } catch (error) {
      this.errorMsg = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  /** @param nameOverride 若传入则优先使用该名称查询（解决半模态内输入与 @State 不同步） */
  private async refreshByManualCity(nameOverride?: string): Promise<void> {
    const raw = nameOverride !== undefined ? nameOverride : this.manualCity;
    const city = raw.trim();
    if (!city) {
      this.errorMsg = '请输入城市名称';
      return;
    }
    this.loading = true;
    this.errorMsg = '';
    try {
      this.weather = await this.weatherService.queryWeatherByCity(city);
      CityStore.setCurrentCity(this.weather.city);
      this.manualCity = this.weather.city;
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

  private formatClock(raw: string): string {
    const idx = raw.indexOf('T');
    if (idx >= 0 && raw.length >= idx + 6) {
      return raw.substring(idx + 1, idx + 6);
    }
    return raw;
  }

  private openCityHub(): void {
    this.cityHubSession++;
    this.cityHubTick++;
    this.cityHubOpen = true;
  }

  private pickCityFromHub(city: string): void {
    this.manualCity = city;
    this.cityHubOpen = false;
    void this.refreshByManualCity();
  }

  private toggleFavFromHub(city: string): void {
    CityStore.toggleFavorite(city);
    this.cityHubTick++;
  }

  private removeRecentFromHub(city: string): void {
    CityStore.removeFromRecent(city);
    this.cityHubTick++;
  }

  private async queryFromHubAsync(query: string): Promise<void> {
    await this.refreshByManualCity(query);
    if (this.errorMsg.length === 0) {
      this.cityHubOpen = false;
    }
    this.cityHubTick++;
  }

  private async locateFromHubAsync(): Promise<void> {
    await this.refreshByLocation();
    this.cityHubTick++;
  }

  @Builder
  buildCityHub(): void {
    CityHubPanel({
      manualCity: this.manualCity,
      hubSession: this.cityHubSession,
      onManualCityChange: (v: string): void => {
        this.manualCity = v;
      },
      favorites: CityStore.listFavorites(),
      recent: CityStore.listRecent(12),
      displayCity: this.weather.city,
      loading: this.loading,
      onPickCity: (c: string): void => {
        this.pickCityFromHub(c);
      },
      onLocate: (): void => {
        void this.locateFromHubAsync();
      },
      onQueryAndSwitch: (q: string): void => {
        void this.queryFromHubAsync(q);
      },
      onToggleFavorite: (c: string): void => {
        this.toggleFavFromHub(c);
      },
      onRemoveCity: (c: string): void => {
        this.removeRecentFromHub(c);
      },
      onClose: (): void => {
        this.cityHubOpen = false;
      }
    });
  }

  private buildDetailParams(): DetailParams {
    return {
      weather: this.weather
    };
  }

  private navigateToDetail(params: DetailParams): void {
    router.pushUrl({
      url: 'pages/WeatherDetail',
      params
    }, (err: BusinessError) => {
      if (err && err.code) {
        this.errorMsg = '打开详情页失败';
      }
    });
  }

  private openDetailPage(): void {
    try {
      const params = this.buildDetailParams();
      this.navigateToDetail(params);
    } catch (_) {
      this.errorMsg = '打开详情页失败';
    }
  }

  build() {
    Column() {
      Row() {
        Text('天气')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().pageTitle)
        Blank()
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Text('⋮')
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textMuted)
            .letterSpacing(1)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .opacity(0.88)
        .bindMenu([
          {
            value: '城市收藏与切换',
            action: (): void => {
              this.openCityHub();
            }
          }
        ])
      }
      .width('92%')
      .margin({ top: 24, bottom: 4 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 14 }) {
        Column({ space: 10 }) {
          Text('城市与查询')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().searchLabel)
            .width('100%')

          TextInput({ placeholder: '输入城市，如 北京/上海', text: this.manualCity })
            .onChange((value: string) => {
              this.manualCity = value;
            })
            .width('100%')
            .fontColor(this.palette().textPrimary)
            .backgroundColor(this.palette().inputFill)
            .borderRadius(12)
            .padding({ left: 10, right: 10 })
        }
        .width('92%')
        .padding({ left: 14, right: 14, top: 16, bottom: 16 })
        .backgroundColor(this.palette().searchTint)
        .borderRadius(18)
        .shadow({ radius: 18, color: this.palette().shadowSearch, offsetX: 0, offsetY: 10 })

        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Button(this.loading ? '查询中…' : '按城市查询')
              .enabled(!this.loading)
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().onAccent)
              .backgroundColor(this.palette().accent)
              .borderRadius(14)
              .onClick(() => this.refreshByManualCity())

            Button(this.loading ? '定位中…' : '定位查询')
              .enabled(!this.loading)
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().ghostBtnText)
              .backgroundColor(this.palette().ghostBtnBg)
              .borderWidth(1.5)
              .borderColor(this.palette().ghostBtnBorder)
              .borderRadius(14)
              .onClick(() => this.refreshByLocation())
          }
          .width('100%')

          Button('📋 完整预报 · 7 日趋势与详情')
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().accentDeep)
            .backgroundColor(this.palette().ghostBtnBg)
            .borderWidth(1)
            .borderColor(this.palette().ghostBtnBorder)
            .borderRadius(14)
            .onClick(() => this.openDetailPage())
        }
        .width('92%')

        Column({ space: 8 }) {
          Text(`${this.weather.city} · ${this.weatherDescByCode(this.weather.weatherCode)}`)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
          Text(`${this.weatherIconByCode(this.weather.weatherCode)} ${this.weather.temperature.toFixed(1)}°C`)
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().heroTemp)
          if (this.weather.weeklyForecast.length > 0) {
            Text(`今日 最高 ${this.weather.weeklyForecast[0].maxTemperature.toFixed(1)}°　最低 ${this.weather.weeklyForecast[0].minTemperature.toFixed(1)}°`)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textSecondary)
          }
          Text(`体感 ${this.weather.apparentTemperature.toFixed(1)}°C  风速 ${this.weather.windSpeed.toFixed(1)} km/h`)
            .fontSize(14)
            .fontColor(this.palette().textSecondary)
          Text(`更新时间 ${this.weather.updateTime}`)
            .fontSize(12)
            .fontColor(this.palette().metaDim)
        }
        .width('92%')
        .alignItems(HorizontalAlign.Start)
        .padding(14)
        .backgroundColor(this.palette().heroCardBg)
        .borderRadius(14)
        .borderWidth(1)
        .borderColor(this.palette().heroCardBorder)

          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text('逐小时预报')
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.palette().hourlyTitle)
                  Text('HOURLY')
                    .fontSize(10)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().hourlyChipText)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .backgroundColor(this.palette().hourlyChipBg)
                    .borderRadius(8)
                }
                .alignItems(VerticalAlign.Center)

                Text('向左滑动查看各时段气温与降水概率')
                  .fontSize(12)
                  .fontColor(this.palette().hourlyHint)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            Scroll() {
              Row({ space: 12 }) {
                ForEach(this.weather.forecast, (item: ForecastItem) => {
                  Column({ space: 8 }) {
                    Text(this.formatForecastTime(item.time))
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.palette().hourlyTime)
                    Text(this.weatherIconByCode(item.weatherCode))
                      .fontSize(30)
                    Text(`${item.temperature.toFixed(0)}°`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.palette().hourlyTemp)
                    Text(`降水 ${item.precipitationProbability.toFixed(0)}%`)
                      .fontSize(11)
                      .fontColor(this.palette().hourlyMeta)
                  }
                  .width(82)
                  .padding({ top: 14, bottom: 14, left: 12, right: 12 })
                  .backgroundColor(this.palette().hourlyPillBg)
                  .borderRadius(16)
                  .borderWidth(1)
                  .borderColor(this.palette().hourlyPillBorder)
                  .shadow({ radius: 8, color: this.palette().shadowSoft, offsetX: 0, offsetY: 2 })
                  .alignItems(HorizontalAlign.Center)
                })
              }
              .padding({ left: 4, right: 4 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
          .width('92%')
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(this.palette().hourlyModuleBg)
          .borderRadius(18)
          .borderWidth(1)
          .borderColor(this.palette().hourlyModuleBorder)
          .shadow({ radius: 20, color: this.palette().shadowCard, offsetX: 0, offsetY: 6 })
          .margin({ top: 8 })

        Column({ space: 12 }) {
          Row() {
            Text('关键天气指标')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.palette().metricsTitle)
              .layoutWeight(1)
            Text('实时')
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

          Column({ space: 10 }) {
            Row({ space: 10 }) {
              Column() {
                KeyMetricTileView({
                  emoji: '💧',
                  caption: '空气湿度',
                  detail: `${this.weather.humidity.toFixed(0)}%`,
                  weatherCode: this.weather.weatherCode
                })
              }
              .layoutWeight(1)
              Column() {
                KeyMetricTileView({
                  emoji: '☔',
                  caption: '降水概率',
                  detail: `${this.weather.precipitationProbability.toFixed(0)}%`,
                  weatherCode: this.weather.weatherCode
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
            Row({ space: 10 }) {
              Column() {
                KeyMetricTileView({
                  emoji: '🌀',
                  caption: '大气压',
                  detail: `${this.weather.pressure.toFixed(0)} hPa`,
                  weatherCode: this.weather.weatherCode
                })
              }
              .layoutWeight(1)
              Column() {
                KeyMetricTileView({
                  emoji: '👁',
                  caption: '能见度',
                  detail: `${(this.weather.visibility / 1000).toFixed(1)} km`,
                  weatherCode: this.weather.weatherCode
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
            Row({ space: 10 }) {
              Column() {
                KeyMetricTileView({
                  emoji: '☀️',
                  caption: '紫外线',
                  detail: `指数 ${this.weather.uvIndex.toFixed(1)}`,
                  weatherCode: this.weather.weatherCode
                })
              }
              .layoutWeight(1)
              Column() {
                KeyMetricTileView({
                  emoji: '🌅',
                  caption: '日出 · 日落',
                  detail: `${this.formatClock(this.weather.sunrise)} / ${this.formatClock(this.weather.sunset)}`,
                  weatherCode: this.weather.weatherCode
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
        }
        .width('92%')
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor(this.palette().metricsCardBg)
        .borderRadius(18)
        .borderWidth(1)
        .borderColor(this.palette().metricsCardBorder)
        .shadow({ radius: 20, color: this.palette().shadowCard, offsetX: 0, offsetY: 8 })

        if (this.weather.lifeAdvice.dressing.length > 0) {
          Column({ space: 14 }) {
            Row() {
              Text('生活指数')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().metricsTitle)
                .layoutWeight(1)
              Text('今日建议')
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

            Column({ space: 10 }) {
              Row({ space: 10 }) {
                Column() {
                  LifeAdviceTileView({
                    emoji: '👔',
                    titleStr: '穿衣',
                    bodyStr: this.weather.lifeAdvice.dressing,
                    weatherCode: this.weather.weatherCode
                  })
                }
                .layoutWeight(1)
                Column() {
                  LifeAdviceTileView({
                    emoji: '🚶',
                    titleStr: '出行',
                    bodyStr: this.weather.lifeAdvice.travel,
                    weatherCode: this.weather.weatherCode
                  })
                }
                .layoutWeight(1)
              }
              .width('100%')
              Row({ space: 10 }) {
                Column() {
                  LifeAdviceTileView({
                    emoji: '🏃',
                    titleStr: '运动',
                    bodyStr: this.weather.lifeAdvice.exercise,
                    weatherCode: this.weather.weatherCode
                  })
                }
                .layoutWeight(1)
                Column() {
                  LifeAdviceTileView({
                    emoji: '🚗',
                    titleStr: '洗车',
                    bodyStr: this.weather.lifeAdvice.carWash,
                    weatherCode: this.weather.weatherCode
                  })
                }
                .layoutWeight(1)
              }
              .width('100%')
              Row({ space: 10 }) {
                Column() {
                  LifeAdviceTileView({
                    emoji: '🤧',
                    titleStr: '感冒',
                    bodyStr: this.weather.lifeAdvice.cold,
                    weatherCode: this.weather.weatherCode
                  })
                }
                .layoutWeight(1)
                Column() {
                  LifeAdviceTileView({
                    emoji: '👕',
                    titleStr: '晾晒',
                    bodyStr: this.weather.lifeAdvice.laundry,
                    weatherCode: this.weather.weatherCode
                  })
                }
                .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%')
          }
          .width('92%')
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(this.palette().adviceShell)
          .borderRadius(18)
          .borderWidth(1)
          .borderColor(this.palette().metricsCardBorder)
          .shadow({ radius: 20, color: this.palette().shadowCard, offsetX: 0, offsetY: 8 })
          .margin({ top: 4 })
        }

        if (this.errorMsg) {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor(this.palette().error)
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 20 })
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
  }
  .width('100%')
  .height('100%')
  .linearGradient({
    angle: 165,
    colors: weatherBackgroundGradient(this.weather.weatherCode)
  })
  .bindSheet($$this.cityHubOpen, this.buildCityHub(), {
    dragBar: true,
    showClose: true,
    blurStyle: BlurStyle.Thick,
    onDisappear: (): void => {
      this.cityHubOpen = false;
    }
  })
  }
}
