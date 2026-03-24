import { DailyForecastItem } from '../services/WeatherService';

/**
 * 7 日最高温 / 最低温折线图（Shape + Polyline）
 */
@Component
export struct WeeklyTrendChart {
  @Prop @Watch('onDailyChange') daily: DailyForecastItem[] = [];
  @Prop @Watch('onRefreshId') refreshId: number = 0;
  @Prop maxLineColor: string = '#C62828';
  @Prop minLineColor: string = '#1565C0';
  @Prop dateTextColor: string = '#2E5070';
  @Prop scaleTextColor: string = '#4A6B86';

  @State private plotW: number = 300;
  @State private maxPts: number[][] = [];
  @State private minPts: number[][] = [];
  @State private scaleLabels: string[] = ['—', '—', '—', '—', '—'];
  @State private dateLabels: string[] = [];

  onRefreshId(): void {
    this.rebuildGeometry(this.plotW);
  }

  onDailyChange(): void {
    this.rebuildGeometry(this.plotW);
  }

  aboutToAppear(): void {
    this.rebuildGeometry(this.plotW);
  }

  private rebuildGeometry(widthVp: number): void {
    const list = this.daily;
    const w = widthVp > 20 ? widthVp : 300;
    const h = 168;
    const padL = 6;
    const padR = 6;
    const padT = 8;
    const padB = 6;
    const innerW = w - padL - padR;
    const innerH = h - padT - padB;

    if (!list || list.length === 0) {
      this.maxPts = [];
      this.minPts = [];
      this.dateLabels = [];
      return;
    }

    let tLo = list[0].minTemperature;
    let tHi = list[0].maxTemperature;
    for (let i = 0; i < list.length; i++) {
      tLo = Math.min(tLo, list[i].minTemperature);
      tHi = Math.max(tHi, list[i].maxTemperature);
    }
    tLo -= 1.5;
    tHi += 1.5;
    const range = tHi - tLo > 0.1 ? tHi - tLo : 1;
    const n = list.length;
    const stepX = n <= 1 ? 0 : innerW / (n - 1);

    const yOf = (t: number): number => {
      return padT + ((tHi - t) / range) * innerH;
    };

    const hi: number[][] = [];
    const lo: number[][] = [];
    for (let i = 0; i < n; i++) {
      const x = padL + stepX * i;
      hi.push([x, yOf(list[i].maxTemperature)]);
      lo.push([x, yOf(list[i].minTemperature)]);
    }
    this.maxPts = hi;
    this.minPts = lo;

    const scales: string[] = [];
    for (let g = 0; g <= 4; g++) {
      const val = tHi - (range * g) / 4;
      scales.push(`${val.toFixed(0)}°`);
    }
    this.scaleLabels = scales;

    const dates: string[] = [];
    for (let i = 0; i < n; i++) {
      const raw = list[i].date;
      dates.push(raw && raw.length >= 10 ? raw.substring(5, 10) : `${i + 1}`);
    }
    this.dateLabels = dates;
  }

  build() {
    Column({ space: 8 }) {
      if (this.daily.length === 0) {
        Text('暂无 7 日数据')
          .fontSize(14)
          .fontColor(this.scaleTextColor)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(24)
      } else {
        Row() {
          Column() {
            Text(this.scaleLabels[0])
              .fontSize(10)
              .fontColor(this.scaleTextColor)
              .width('100%')
              .textAlign(TextAlign.End)
            Blank()
              .layoutWeight(1)
            Text(this.scaleLabels[1])
              .fontSize(10)
              .fontColor(this.scaleTextColor)
              .width('100%')
              .textAlign(TextAlign.End)
            Blank()
              .layoutWeight(1)
            Text(this.scaleLabels[2])
              .fontSize(10)
              .fontColor(this.scaleTextColor)
              .width('100%')
              .textAlign(TextAlign.End)
            Blank()
              .layoutWeight(1)
            Text(this.scaleLabels[3])
              .fontSize(10)
              .fontColor(this.scaleTextColor)
              .width('100%')
              .textAlign(TextAlign.End)
            Blank()
              .layoutWeight(1)
            Text(this.scaleLabels[4])
              .fontSize(10)
              .fontColor(this.scaleTextColor)
              .width('100%')
              .textAlign(TextAlign.End)
          }
          .width(36)
          .height(168)
          .justifyContent(FlexAlign.SpaceBetween)

          Column({ space: 6 }) {
            if (this.maxPts.length > 0 && this.minPts.length > 0) {
              Shape() {
                Polyline()
                  .width('100%')
                  .height('100%')
                  .points(this.maxPts)
                  .stroke(this.maxLineColor)
                  .strokeWidth(2.5)
                  .fillOpacity(0)
                Polyline()
                  .width('100%')
                  .height('100%')
                  .points(this.minPts)
                  .stroke(this.minLineColor)
                  .strokeWidth(2.5)
                  .fillOpacity(0)
              }
              .width('100%')
              .height(168)
              .onAreaChange((_: Area, area: Area) => {
                const nw = area.width as number;
                if (nw > 10 && Math.abs(nw - this.plotW) > 1) {
                  this.plotW = nw;
                  this.rebuildGeometry(nw);
                }
              })
            } else {
              Blank()
                .width('100%')
                .height(168)
            }

            Row() {
              ForEach(this.dateLabels, (lab: string, i: number) => {
                Text(lab)
                  .fontSize(11)
                  .fontColor(this.dateTextColor)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
              }, (lab: string, i: number) => `wd_${i}_${lab}`)
            }
            .width('100%')
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%')
  }
}
