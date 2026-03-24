import { weatherUiPalette, WeatherUiPalette } from '../utils/WeatherTheme';

@Component
export struct CityHubPanel {
  /** 与首页同步；打开面板时复制到 searchDraft */
  @Prop manualCity: string = '';
  /** 每次打开半模态递增，用于把输入草稿重置为当前 manualCity */
  @Prop @Watch('onHubSession') hubSession: number = 0;
  onManualCityChange: (v: string) => void = (_: string) => {
  };
  @State private searchDraft: string = '';
  @Prop favorites: string[] = [];
  @Prop recent: string[] = [];
  @Prop displayCity: string = '';
  @Prop loading: boolean = false;
  onPickCity: (city: string) => void = (_: string) => {
  };
  onLocate: () => void = () => {
  };
  onQueryAndSwitch: (query: string) => void = (_: string) => {
  };
  onToggleFavorite: (city: string) => void = (_: string) => {
  };
  onRemoveCity: (city: string) => void = (_: string) => {
  };
  onClose: () => void = () => {
  };

  private palette(): WeatherUiPalette {
    return weatherUiPalette(-1);
  }

  private favStar(filled: boolean): string {
    return filled ? '★' : '☆';
  }

  private syncDraftFromProp(): void {
    this.searchDraft = this.manualCity;
  }

  /** 半模态每次展示时与城市池同步，避免沿用过期的 searchDraft */
  onHubSession(): void {
    this.syncDraftFromProp();
  }

  aboutToAppear(): void {
    this.syncDraftFromProp();
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Blank()
          .layoutWeight(1)
        Button('完成')
          .fontSize(15)
          .fontColor(this.palette().onAccent)
          .backgroundColor(this.palette().accent)
          .borderRadius(10)
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .onClick(() => this.onClose())
      }
      .width('100%')
      .padding({ left: 4, right: 4, bottom: 8 })

      Text('当前：' + (this.displayCity.length > 0 ? this.displayCity : '—'))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%')

      Row({ space: 10 }) {
        Button(this.loading ? '定位中…' : '定位到当前位置')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .fontColor(this.palette().onAccent)
          .backgroundColor(this.palette().accent)
          .borderRadius(12)
          .enabled(!this.loading)
          .onClick(() => this.onLocate())

        Button('收藏当前城市')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .fontColor(this.palette().accentDeep)
          .backgroundColor(this.palette().ghostBtnBg)
          .borderWidth(1)
          .borderColor(this.palette().ghostBtnBorder)
          .borderRadius(12)
          .enabled(this.displayCity.length > 0 && this.displayCity !== '--')
          .onClick(() => {
            if (this.displayCity.length > 0 && this.displayCity !== '--') {
              this.onToggleFavorite(this.displayCity);
            }
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('搜索并切换')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().searchLabel)
        TextInput({ placeholder: '输入城市名，回车或点按钮查询', text: this.searchDraft })
          .onChange((v: string) => {
            this.searchDraft = v;
            this.onManualCityChange(v);
          })
          .onSubmit(() => this.onQueryAndSwitch(this.searchDraft.trim()))
          .width('100%')
          .fontColor(this.palette().textPrimary)
          .backgroundColor(this.palette().inputFill)
          .borderRadius(12)
          .padding({ left: 10, right: 10 })
        Button(this.loading ? '查询中…' : '查询并设为当前城市')
          .width('100%')
          .height(40)
          .fontSize(14)
          .fontColor(this.palette().onAccent)
          .backgroundColor(this.palette().accent)
          .borderRadius(12)
          .enabled(!this.loading)
          .onClick(() => this.onQueryAndSwitch(this.searchDraft.trim()))
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.palette().searchTint)
      .borderRadius(14)

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('⭐ 收藏城市')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.palette().metricsTitle)
            if (this.favorites.length === 0) {
              Text('暂无收藏，可在上方将当前城市加入收藏')
                .fontSize(13)
                .fontColor(this.palette().textMuted)
            } else {
              ForEach(this.favorites, (city: string) => {
                Row({ space: 10 }) {
                  Button(this.favStar(true))
                    .fontSize(18)
                    .fontColor('#C9A227')
                    .backgroundColor(Color.Transparent)
                    .padding(0)
                    .onClick(() => this.onToggleFavorite(city))
                  Text(city)
                    .fontSize(16)
                    .layoutWeight(1)
                    .fontColor(this.palette().textPrimary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Button('切换')
                    .fontSize(13)
                    .fontColor(this.palette().onAccent)
                    .backgroundColor(this.palette().accent)
                    .borderRadius(8)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => this.onPickCity(city))
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.palette().listRow)
                .borderRadius(10)
                .borderWidth(1)
                .borderColor(this.palette().metricsCardBorder)
              }, (city: string) => 'fav_' + city)
            }
          }
          .width('100%')

          Column({ space: 8 }) {
            Text('🕐 最近访问')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.palette().metricsTitle)
            if (this.recent.length === 0) {
              Text('查询或切换城市后会自动记录')
                .fontSize(13)
                .fontColor(this.palette().textMuted)
            } else {
              ForEach(this.recent, (city: string) => {
                Row({ space: 10 }) {
                  Text(city)
                    .fontSize(16)
                    .layoutWeight(1)
                    .fontColor(this.palette().textPrimary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Button('切换')
                    .fontSize(13)
                    .fontColor(this.palette().accentDeep)
                    .backgroundColor(this.palette().ghostBtnBg)
                    .borderWidth(1)
                    .borderColor(this.palette().ghostBtnBorder)
                    .borderRadius(8)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => this.onPickCity(city))
                  Button('移除')
                    .fontSize(13)
                    .fontColor(this.palette().onAccent)
                    .backgroundColor(this.palette().deleteBtn)
                    .borderRadius(8)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .onClick(() => this.onRemoveCity(city))
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.palette().listRow)
                .borderRadius(10)
                .borderWidth(1)
                .borderColor(this.palette().metricsCardBorder)
              }, (city: string) => 'rc_' + city)
            }
          }
          .width('100%')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 24 })
  }
}
