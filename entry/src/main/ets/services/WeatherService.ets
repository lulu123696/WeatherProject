import http from '@ohos.net.http';
import { geoLocationManager } from '@kit.LocationKit';

/** 生活指数：穿衣、出行、运动、洗车、感冒、晾晒 */
export interface LifeIndexAdvice {
  dressing: string;
  travel: string;
  exercise: string;
  carWash: string;
  cold: string;
  laundry: string;
}

export interface WeatherInfo {
  city: string;
  temperature: number;
  apparentTemperature: number;
  windSpeed: number;
  humidity: number;
  precipitationProbability: number;
  pressure: number;
  visibility: number;
  uvIndex: number;
  sunrise: string;
  sunset: string;
  weatherCode: number;
  updateTime: string;
  forecast: ForecastItem[];
  weeklyForecast: DailyForecastItem[];
  lifeAdvice: LifeIndexAdvice;
}

export interface ForecastItem {
  time: string;
  temperature: number;
  precipitationProbability: number;
  weatherCode: number;
}

export interface DailyForecastItem {
  date: string;
  minTemperature: number;
  maxTemperature: number;
  precipitationProbability: number;
  uvIndex: number;
  sunrise: string;
  sunset: string;
  weatherCode: number;
}

interface Coordinate {
  latitude: number;
  longitude: number;
}

interface CurrentWeatherWithForecast {
  temperature: number;
  apparentTemperature: number;
  windSpeed: number;
  humidity: number;
  precipitationProbability: number;
  pressure: number;
  visibility: number;
  uvIndex: number;
  sunrise: string;
  sunset: string;
  weatherCode: number;
  time: string;
  forecast: ForecastItem[];
  weeklyForecast: DailyForecastItem[];
}

interface CityAnchor {
  name: string;
  latitude: number;
  longitude: number;
}

interface GeocodeHit extends Coordinate {
  label: string;
}

export class WeatherService {
  private static readonly CITY_ANCHORS: CityAnchor[] = [
    { name: '北京', latitude: 39.9042, longitude: 116.4074 },
    { name: '上海', latitude: 31.2304, longitude: 121.4737 },
    { name: '广州', latitude: 23.1291, longitude: 113.2644 },
    { name: '深圳', latitude: 22.5431, longitude: 114.0579 },
    { name: '天津', latitude: 39.3434, longitude: 117.3616 },
    { name: '重庆', latitude: 29.5630, longitude: 106.5516 },
    { name: '杭州', latitude: 30.2741, longitude: 120.1551 },
    { name: '南京', latitude: 32.0603, longitude: 118.7969 },
    { name: '武汉', latitude: 30.5928, longitude: 114.3055 },
    { name: '成都', latitude: 30.5728, longitude: 104.0668 },
    { name: '西安', latitude: 34.3416, longitude: 108.9398 },
    { name: '苏州', latitude: 31.2989, longitude: 120.5853 },
    { name: '郑州', latitude: 34.7466, longitude: 113.6254 },
    { name: '长沙', latitude: 28.2278, longitude: 112.9388 },
    { name: '青岛', latitude: 36.0671, longitude: 120.3826 },
    { name: '沈阳', latitude: 41.8057, longitude: 123.4315 },
    { name: '大连', latitude: 38.9140, longitude: 121.6147 },
    { name: '厦门', latitude: 24.4798, longitude: 118.0894 },
    { name: '福州', latitude: 26.0745, longitude: 119.2965 },
    { name: '昆明', latitude: 25.0389, longitude: 102.7183 }
  ];

  private static parseHttpJsonRecord(response: http.HttpResponse): Record<string, Object> {
    const r = response.result;
    if (typeof r === 'string') {
      return JSON.parse(r) as Record<string, Object>;
    }
    if (typeof r === 'object' && r !== null) {
      return r as Record<string, Object>;
    }
    return JSON.parse(String(r)) as Record<string, Object>;
  }

  private static jsonHasOwnKey(row: Record<string, Object>, key: string): boolean {
    const keys = Object.keys(row);
    for (let i = 0; i < keys.length; i++) {
      if (keys[i] === key) {
        return true;
      }
    }
    return false;
  }

  private static jsonNumber(row: Record<string, Object> | undefined, key: string): number {
    if (!row) {
      return 0;
    }
    const v = row[key];
    if (v === undefined || v === null) {
      return 0;
    }
    if (typeof v === 'number') {
      return Number.isFinite(v) ? v : 0;
    }
    const n = parseFloat(String(v));
    return Number.isFinite(n) ? n : 0;
  }

  async queryCurrentCityWeather(): Promise<WeatherInfo> {
    const coordinate = await this.getCurrentCoordinate();
    const weatherPromise = this.queryCurrentWeatherWithForecast(coordinate);
    const cityFallback = this.buildCoordinateCityFallback(coordinate);
    const cityPromise = this.withTimeout(this.reverseGeocodeCity(coordinate), 6000, cityFallback);

    const weather = await weatherPromise;
    const rawCity = await cityPromise;
    const city = WeatherService.pickRicherDistrictLabel(rawCity, cityFallback);
    const lifeAdvice = this.buildLifeIndexAdvice(
      weather.temperature,
      weather.apparentTemperature,
      weather.windSpeed,
      weather.humidity,
      weather.precipitationProbability,
      weather.visibility,
      weather.uvIndex,
      weather.weatherCode
    );

    return {
      city,
      temperature: weather.temperature,
      apparentTemperature: weather.apparentTemperature,
      windSpeed: weather.windSpeed,
      humidity: weather.humidity,
      precipitationProbability: weather.precipitationProbability,
      pressure: weather.pressure,
      visibility: weather.visibility,
      uvIndex: weather.uvIndex,
      sunrise: weather.sunrise,
      sunset: weather.sunset,
      weatherCode: weather.weatherCode,
      updateTime: weather.time,
      forecast: weather.forecast,
      weeklyForecast: weather.weeklyForecast,
      lifeAdvice
    };
  }

  private withTimeout<T>(promise: Promise<T>, timeoutMs: number, fallback: T): Promise<T> {
    return new Promise((resolve) => {
      let settled = false;
      const timer = setTimeout(() => {
        if (settled) {
          return;
        }
        settled = true;
        resolve(fallback);
      }, timeoutMs);

      promise.then((value) => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timer);
        resolve(value);
      }).catch(() => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timer);
        resolve(fallback);
      });
    });
  }

  async queryWeatherByCity(cityName: string): Promise<WeatherInfo> {
    const hit = await this.geocodeCity(cityName);
    const coordinate: Coordinate = { latitude: hit.latitude, longitude: hit.longitude };
    const needReverse = !WeatherService.labelHasCountyOrDistrict(hit.label);
    const reversePromise: Promise<string> = needReverse
      ? this.withTimeout(this.reverseGeocodeCity(coordinate), 4000, hit.label)
      : Promise.resolve(hit.label);
    const pair = await Promise.all([
      this.queryCurrentWeatherWithForecast(coordinate),
      reversePromise
    ]);
    const weather = pair[0] as CurrentWeatherWithForecast;
    const fromReverse = pair[1] as string;
    const lifeAdvice = this.buildLifeIndexAdvice(
      weather.temperature,
      weather.apparentTemperature,
      weather.windSpeed,
      weather.humidity,
      weather.precipitationProbability,
      weather.visibility,
      weather.uvIndex,
      weather.weatherCode
    );
    const displayCity = WeatherService.pickRicherDistrictLabel(fromReverse, hit.label);
    return {
      city: displayCity,
      temperature: weather.temperature,
      apparentTemperature: weather.apparentTemperature,
      windSpeed: weather.windSpeed,
      humidity: weather.humidity,
      precipitationProbability: weather.precipitationProbability,
      pressure: weather.pressure,
      visibility: weather.visibility,
      uvIndex: weather.uvIndex,
      sunrise: weather.sunrise,
      sunset: weather.sunset,
      weatherCode: weather.weatherCode,
      updateTime: weather.time,
      forecast: weather.forecast,
      weeklyForecast: weather.weeklyForecast,
      lifeAdvice
    };
  }

  private getCurrentCoordinate(): Promise<Coordinate> {
    return new Promise((resolve, reject) => {
      const requestInfo: geoLocationManager.CurrentLocationRequest = {
        'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
        'scenario': geoLocationManager.LocationRequestScenario.UNSET
      };

      geoLocationManager.getCurrentLocation(requestInfo, (error, location) => {
        if (error) {
          reject(new Error(`定位失败: ${JSON.stringify(error)}`));
          return;
        }
        resolve({
          latitude: location.latitude,
          longitude: location.longitude
        });
      });
    });
  }

  private async reverseGeocodeCity(coordinate: Coordinate): Promise<string> {
    const city = await this.requestCityFromNominatim(coordinate);
    return city || this.buildCoordinateCityFallback(coordinate);
  }

  private async requestCityFromNominatim(coordinate: Coordinate): Promise<string | undefined> {
    const client = http.createHttp();
    try {
      const lat = coordinate.latitude;
      const lon = coordinate.longitude;
      const url =
        `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&addressdetails=1&zoom=12&accept-language=zh-CN`;
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        header: {
          'User-Agent': 'HarmonyWeatherDemo/1.0'
        }
      });

      if (response.responseCode < 200 || response.responseCode >= 300) {
        return undefined;
      }

      const raw = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      const data = JSON.parse(raw) as Record<string, Object>;
      const address = data['address'] as Record<string, string> | undefined;
      let label: string | undefined = undefined;
      if (address) {
        label = WeatherService.formatLocationFromNominatimAddress(address);
      }
      if (!label || !WeatherService.labelHasCountyOrDistrict(label)) {
        const dn = data['display_name'];
        if (typeof dn === 'string' && dn.length > 0) {
          const fromDn = WeatherService.formatFromNominatimDisplayName(dn);
          if (fromDn) {
            label = WeatherService.pickRicherDistrictLabel(fromDn, label ?? '');
          }
        }
      }
      return label;
    } catch (_) {
      return undefined;
    } finally {
      client.destroy();
    }
  }

  /** 去掉省/市等后缀，便于「沈阳」与「沈阳市」与锚点比对 */
  private static stripAdministrativeSuffix(s: string): string {
    let t = s.trim();
    t = t.replace(/特别行政区$/u, '');
    t = t.replace(/自治区$/u, '');
    t = t.replace(/省$/u, '');
    t = t.replace(/市$/u, '');
    return t;
  }

  /** 是否包含县级、区级等（用于判断是否比「仅市名」更细） */
  private static labelHasCountyOrDistrict(label: string): boolean {
    return /(区|县|旗|新区|林区|特区|自治县|自治旗|市辖区)/.test(label);
  }

  /** 在两者中优先保留含区县、更长的地名 */
  private static pickRicherDistrictLabel(a: string, b: string): string {
    const ha = WeatherService.labelHasCountyOrDistrict(a);
    const hb = WeatherService.labelHasCountyOrDistrict(b);
    if (ha && !hb) {
      return a;
    }
    if (hb && !ha) {
      return b;
    }
    return a.length >= b.length ? a : b;
  }

  /**
   * Nominatim display_name 多为「细项, 区, 市, 省, 中国」，从中抽出市+区县级。
   */
  private static formatFromNominatimDisplayName(displayName: string): string | undefined {
    const parts = displayName.split(',')
      .map((t: string) => t.trim())
      .filter((t: string) => t.length > 0 && t !== '中国' && t !== 'China' && t !== 'Hong Kong' && t !== 'Macau');

    const isDistrictLike = (p: string): boolean =>
      /(区|县|旗|新区|林区|特区|自治县|自治旗)$/.test(p) && !/^市辖区$/.test(p);

    const isCityOrProvinceLike = (p: string): boolean =>
      /(市|省|自治区|特别行政区)$/.test(p);

    const dist = parts.find(isDistrictLike);
    const city = parts.find(isCityOrProvinceLike);

    if (city && dist && city !== dist) {
      if (dist.indexOf(city) >= 0 || city.indexOf(dist) >= 0) {
        return city.length >= dist.length ? city : `${city}${dist}`;
      }
      return `${city}${dist}`;
    }
    if (dist) {
      const parent = parts.find((p: string) => p !== dist && isCityOrProvinceLike(p));
      if (parent) {
        return `${parent}${dist}`;
      }
      return dist;
    }
    if (parts.length >= 2) {
      const tailTwo = `${parts[parts.length - 2]}${parts[parts.length - 1]}`;
      if (WeatherService.labelHasCountyOrDistrict(tailTwo) || parts[parts.length - 1].length >= 2) {
        return tailTwo;
      }
    }
    return parts.length > 0 ? parts[parts.length - 1] : undefined;
  }

  private buildCoordinateCityFallback(coordinate: Coordinate): string {
    const nearbyCity = this.findNearestChineseCity(coordinate);
    if (nearbyCity) {
      return nearbyCity;
    }

    const lat = coordinate.latitude.toFixed(2);
    const lon = coordinate.longitude.toFixed(2);
    return `附近(${lat}, ${lon})`;
  }

  private findNearestChineseCity(coordinate: Coordinate): string | undefined {
    let nearestName: string | undefined = undefined;
    let nearestDistanceKm = Number.POSITIVE_INFINITY;

    for (const anchor of WeatherService.CITY_ANCHORS) {
      const distanceKm = this.calcDistanceKm(coordinate.latitude, coordinate.longitude, anchor.latitude, anchor.longitude);
      if (distanceKm < nearestDistanceKm) {
        nearestDistanceKm = distanceKm;
        nearestName = anchor.name;
      }
    }

    // 仅在较近范围内兜底为城市名，避免跨省误判
    if (nearestDistanceKm <= 120) {
      return nearestName;
    }

    return undefined;
  }

  private calcDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const rad = Math.PI / 180;
    const dLat = (lat2 - lat1) * rad;
    const dLon = (lon2 - lon1) * rad;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
      + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.asin(Math.min(1, Math.sqrt(a)));
    return 6371 * c;
  }

  /**
   * Nominatim：优先组合「上级行政区 + 区县」，便于显示到「区」一级。
   */
  private static formatLocationFromNominatimAddress(address: Record<string, string>): string | undefined {
    const pick = (k: string): string => {
      const v = address[k];
      return (v && v.trim().length > 0) ? v.trim() : '';
    };

    const state = pick('state');
    const city = pick('city') || pick('municipality');
    const suburbPick = pick('suburb');
    const suburbDistrict = suburbPick && /(区|县|旗|新区)$/.test(suburbPick) ? suburbPick : '';

    const district = pick('city_district') || pick('district') || pick('county') || pick('borough')
      || suburbDistrict
      || pick('state_district');
    const town = pick('town');
    const village = pick('village');
    const suburb = suburbPick;

    if (district.length > 0) {
      const parent = city || state;
      if (parent.length === 0) {
        return district;
      }
      if (district === parent || parent === district) {
        return parent;
      }
      const cityCore = parent.replace(/市$|省$|自治区$|特别行政区$/, '');
      const distCore = district.replace(/区$|县$|市$/, '');
      const badMerge = parent.includes(district) || (district.includes(cityCore) && district.length > cityCore.length);
      if (badMerge) {
        return parent.length >= district.length ? parent : `${parent}${district}`;
      }
      if (distCore.length > 0 && parent.indexOf(distCore) >= 0) {
        return parent;
      }
      return `${parent}${district}`;
    }

    return city || town || pick('county') || pick('municipality') || pick('state_district') || state || village || suburb || undefined;
  }

  private strField(row: Record<string, Object>, key: string): string {
    const v = row[key];
    if (typeof v === 'string') {
      return v.trim();
    }
    return '';
  }

  /** Open-Meteo 结果中的 admin1–3 含省 / 市 / 区县，拼成完整地区名（精确到区县时含「区」「县」） */
  private buildLabelFromOpenMeteoRow(row: Record<string, Object>, query: string): string {
    const a1 = this.strField(row, 'admin1');
    const a2 = this.strField(row, 'admin2');
    const a3 = this.strField(row, 'admin3');
    const a4 = this.strField(row, 'admin4');
    const name = this.strField(row, 'name');
    const segs: string[] = [];
    [a1, a2, a3, a4].forEach((s: string) => {
      if (s && segs.indexOf(s) < 0) {
        segs.push(s);
      }
    });
    let out = segs.join('');
    if (out.length === 0) {
      return name || query.trim();
    }
    /**
     * 不再把 API 的 name 无脑拼在 admin 后面：国内常有村/镇/街道名与大城市重名（如「北京」），
     * 会与上级市名拼成「重庆市北京」等错误展示。
     */
    return out;
  }

  /**
   * Nominatim 单条结果常为「沈阳路」等道路，会落在别的城市；多结果按行政级别与名称打分择优。
   */
  private scoreNominatimCandidate(r: Record<string, Object>, query: string): number {
    const q = query.trim();
    if (q.length === 0) {
      return 0;
    }
    const qCore = WeatherService.stripAdministrativeSuffix(q);
    const cl = this.strField(r, 'class');
    const ty = this.strField(r, 'type');
    let score = 0;
    if (cl === 'highway' || ty === 'road' || ty === 'residential' || ty === 'footway' || ty === 'path') {
      score -= 250;
    }
    const shortName = this.strField(r, 'name');
    if (shortName === q || shortName === qCore || shortName === q + '市') {
      score += 450;
    }
    const addr = r['address'] as Record<string, string> | undefined;
    if (addr) {
      const cityLike = (addr['city'] || addr['municipality'] || addr['county'] || addr['town'] || '').trim();
      if (cityLike.length > 0) {
        const cityCore = WeatherService.stripAdministrativeSuffix(cityLike);
        if (cityLike.indexOf(q) >= 0 || cityLike.indexOf(qCore) >= 0 || cityCore === qCore || qCore === cityCore) {
          score += 520;
        }
      }
    }
    const dn = r['display_name'];
    if (typeof dn === 'string' && (dn.indexOf(q) >= 0 || dn.indexOf(qCore + '市') >= 0)) {
      score += 120;
    }
    const imp = r['importance'];
    if (typeof imp === 'number') {
      score += imp * 12;
    }
    return score;
  }

  private pickBestNominatimRow(arr: Array<Record<string, Object>>, query: string): Record<string, Object> {
    if (arr.length === 1) {
      return arr[0];
    }
    let best = arr[0];
    let bestScore = this.scoreNominatimCandidate(arr[0], query);
    for (let i = 1; i < arr.length; i++) {
      const s = this.scoreNominatimCandidate(arr[i], query);
      if (s > bestScore) {
        bestScore = s;
        best = arr[i];
      }
    }
    return best;
  }

  private scoreOpenMeteoRow(r: Record<string, Object>, query: string): number {
    const q = query.trim();
    if (q.length === 0) {
      return 0;
    }
    const qCore = WeatherService.stripAdministrativeSuffix(q);
    const name = this.strField(r, 'name');
    const a1 = this.strField(r, 'admin1');
    const a2 = this.strField(r, 'admin2');
    const a3 = this.strField(r, 'admin3');
    let score = 0;
    if (name === q || name === q + '市') {
      score += 320;
    }
    if (name === qCore || name === qCore + '市') {
      score += 300;
    }
    if (qCore.length >= 2 && name.indexOf(qCore) >= 0) {
      score += 160;
    }
    if (a1.indexOf(qCore) >= 0 || a2.indexOf(qCore) >= 0 || a3.indexOf(qCore) >= 0) {
      score += 220;
    }
    if (a1.indexOf(q) >= 0 || a2.indexOf(q) >= 0 || a3.indexOf(q) >= 0) {
      score += 200;
    }
    const pop = r['population'];
    if (typeof pop === 'number' && pop > 0) {
      score += Math.log10(pop + 1) * 4;
    }
    return score;
  }

  private pickBestOpenMeteoRow(rows: Array<Record<string, Object>>, query: string): Record<string, Object> {
    if (rows.length === 1) {
      return rows[0];
    }
    let best = rows[0];
    let bestScore = this.scoreOpenMeteoRow(rows[0], query);
    for (let i = 1; i < rows.length; i++) {
      const s = this.scoreOpenMeteoRow(rows[i], query);
      if (s > bestScore) {
        bestScore = s;
        best = rows[i];
      }
    }
    return best;
  }

  /** 国内名称用 Nominatim 正向搜索补全区县（Open-Meteo 在国内常缺 admin3） */
  private async nominatimForwardLabel(query: string): Promise<string | undefined> {
    const q = query.trim();
    if (q.length === 0) {
      return undefined;
    }
    const client = http.createHttp();
    try {
      const encoded = encodeURIComponent(q);
      const url =
        `https://nominatim.openstreetmap.org/search?q=${encoded}&format=json&addressdetails=1&limit=10&accept-language=zh-CN&countrycodes=cn`;
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        header: {
          'User-Agent': 'HarmonyWeatherDemo/1.0'
        }
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return undefined;
      }
      const raw = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      const arr = JSON.parse(raw) as Array<Record<string, Object>> | undefined;
      if (!arr || arr.length === 0) {
        return undefined;
      }
      const row0 = this.pickBestNominatimRow(arr, q);
      const address = row0['address'] as Record<string, string> | undefined;
      let label: string | undefined = undefined;
      if (address) {
        label = WeatherService.formatLocationFromNominatimAddress(address);
      }
      if (!label || !WeatherService.labelHasCountyOrDistrict(label)) {
        const dn = row0['display_name'];
        if (typeof dn === 'string') {
          const fromDn = WeatherService.formatFromNominatimDisplayName(dn);
          if (fromDn) {
            label = WeatherService.pickRicherDistrictLabel(fromDn, label ?? '');
          }
        }
      }
      return label;
    } catch (_) {
      return undefined;
    } finally {
      client.destroy();
    }
  }

  /** Open-Meteo 地理编码第一条结果（与 Nominatim 并行可压缩总耗时） */
  /** 与锚点列表完全匹配时直接返回坐标，省去两次外网地理编码 */
  private tryGeocodeFromAnchor(cityName: string): GeocodeHit | undefined {
    const q = cityName.trim();
    if (q.length === 0) {
      return undefined;
    }
    const qCore = WeatherService.stripAdministrativeSuffix(q);
    for (const a of WeatherService.CITY_ANCHORS) {
      const aCore = WeatherService.stripAdministrativeSuffix(a.name);
      if (a.name === q || a.name + '市' === q || aCore === qCore) {
        return {
          latitude: a.latitude,
          longitude: a.longitude,
          label: a.name
        };
      }
    }
    return undefined;
  }

  private async openMeteoGeocodeFirstRow(cityName: string): Promise<Record<string, Object>> {
    const client = http.createHttp();
    try {
      const encoded = encodeURIComponent(cityName);
      const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encoded}&count=10&language=zh&format=json`;
      let response: http.HttpResponse;
      try {
        response = await client.request(url, {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.STRING
        });
      } catch (_) {
        throw new Error('城市查询请求失败');
      }

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`城市查询失败: ${response.responseCode}`);
      }

      const result = JSON.parse(response.result as string) as Record<string, Object>;
      const rows = result['results'] as Array<Record<string, Object>> | undefined;
      if (!rows || rows.length === 0) {
        throw new Error('未找到该城市');
      }
      return this.pickBestOpenMeteoRow(rows, cityName);
    } finally {
      client.destroy();
    }
  }

  private async geocodeCity(cityName: string): Promise<GeocodeHit> {
    const anchor = this.tryGeocodeFromAnchor(cityName);
    if (anchor !== undefined) {
      return anchor;
    }

    const nomPromise = this.nominatimForwardLabel(cityName);
    const row0 = await this.openMeteoGeocodeFirstRow(cityName);
    let label = this.buildLabelFromOpenMeteoRow(row0, cityName);
    if (WeatherService.labelHasCountyOrDistrict(label)) {
      void nomPromise;
      return {
        latitude: Number(row0['latitude']),
        longitude: Number(row0['longitude']),
        label
      };
    }
    const nomLabel = await nomPromise;
    if (nomLabel) {
      label = WeatherService.pickRicherDistrictLabel(nomLabel, label);
    }
    return {
      latitude: Number(row0['latitude']),
      longitude: Number(row0['longitude']),
      label
    };
  }

  private async queryCurrentWeatherWithForecast(coordinate: Coordinate): Promise<CurrentWeatherWithForecast> {
    const client = http.createHttp();
    try {
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${coordinate.latitude}&longitude=${coordinate.longitude}&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,surface_pressure,visibility,weather_code,precipitation_probability,uv_index&hourly=temperature_2m,weather_code,precipitation_probability,uv_index&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,uv_index_max,sunrise,sunset&forecast_days=7&timezone=auto`;
      let response: http.HttpResponse;
      try {
        response = await client.request(url, {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.STRING
        });
      } catch (_) {
        throw new Error('天气请求失败，请检查网络');
      }

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`天气请求失败: ${response.responseCode}`);
      }

      const result = WeatherService.parseHttpJsonRecord(response);
      const current = result['current'] as Record<string, Object> | undefined;
      if (!current) {
        throw new Error('天气数据为空');
      }
      const currentTime = String(current['time'] ?? '');
      const forecast = this.parseForecast(result, currentTime);
      const weeklyForecast = this.parseWeeklyForecast(result);

      let precipitationProbability = 0;
      if (WeatherService.jsonHasOwnKey(current, 'precipitation_probability')) {
        precipitationProbability = WeatherService.jsonNumber(current, 'precipitation_probability');
      } else if (forecast.length > 0) {
        precipitationProbability = forecast[0].precipitationProbability;
      } else if (weeklyForecast.length > 0) {
        precipitationProbability = weeklyForecast[0].precipitationProbability;
      }

      let uvIndex = 0;
      if (WeatherService.jsonHasOwnKey(current, 'uv_index')) {
        uvIndex = WeatherService.jsonNumber(current, 'uv_index');
      } else if (weeklyForecast.length > 0) {
        uvIndex = weeklyForecast[0].uvIndex;
      }

      let sunrise = '';
      let sunset = '';
      if (weeklyForecast.length > 0) {
        sunrise = weeklyForecast[0].sunrise;
        sunset = weeklyForecast[0].sunset;
      }

      let weatherCode = -1;
      if (WeatherService.jsonHasOwnKey(current, 'weather_code')) {
        weatherCode = Math.trunc(WeatherService.jsonNumber(current, 'weather_code'));
      }

      return {
        temperature: WeatherService.jsonNumber(current, 'temperature_2m'),
        apparentTemperature: WeatherService.jsonNumber(current, 'apparent_temperature'),
        windSpeed: WeatherService.jsonNumber(current, 'wind_speed_10m'),
        humidity: WeatherService.jsonNumber(current, 'relative_humidity_2m'),
        precipitationProbability,
        pressure: WeatherService.jsonNumber(current, 'surface_pressure'),
        visibility: WeatherService.jsonNumber(current, 'visibility'),
        uvIndex,
        sunrise,
        sunset,
        weatherCode,
        time: currentTime,
        forecast,
        weeklyForecast
      };
    } finally {
      client.destroy();
    }
  }

  private parseForecast(result: Record<string, Object>, currentTime: string): ForecastItem[] {
    const hourly = result['hourly'] as Record<string, Array<number | string>> | undefined;
    if (!hourly) {
      return [];
    }

    const times = hourly['time'] as string[] | undefined;
    const temperatures = hourly['temperature_2m'] as number[] | undefined;
    const codes = hourly['weather_code'] as number[] | undefined;
    const precipitationProbabilities = hourly['precipitation_probability'] as number[] | undefined;
    if (!times || !temperatures || !codes) {
      return [];
    }

    const startIndex = this.findStartIndexByTime(times, currentTime);
    let upper = Math.min(times.length, temperatures.length, codes.length, startIndex + 8);
    if (precipitationProbabilities !== undefined) {
      upper = Math.min(upper, precipitationProbabilities.length);
    }
    const list: ForecastItem[] = [];
    for (let i = startIndex; i < upper; i++) {
      list.push({
        time: String(times[i]),
        temperature: Number(temperatures[i]),
        precipitationProbability: precipitationProbabilities !== undefined
          ? Number(precipitationProbabilities[i] ?? 0)
          : 0,
        weatherCode: Number(codes[i])
      });
    }
    return list;
  }

  private normalizeToHourKey(isoTime: string): string {
    if (!isoTime) {
      return '';
    }
    const tIndex = isoTime.indexOf('T');
    if (tIndex < 0 || isoTime.length < tIndex + 3) {
      return isoTime;
    }
    // "YYYY-MM-DD" + "T" + "HH"（忽略分秒与时区后缀的比较前缀）
    return isoTime.substring(0, tIndex + 3);
  }

  private findStartIndexByTime(times: string[], currentTime: string): number {
    if (!currentTime || times.length === 0) {
      return 0;
    }
    const targetKey = this.normalizeToHourKey(currentTime);
    if (!targetKey) {
      return 0;
    }
    const exactIdx = times.findIndex((time) => this.normalizeToHourKey(time) === targetKey);
    if (exactIdx >= 0) {
      return exactIdx;
    }
    // 当前时刻若落在两点之间，取第一个整点不早于当前小时的槽位
    const afterIdx = times.findIndex((time) => this.normalizeToHourKey(time) >= targetKey);
    if (afterIdx >= 0) {
      return afterIdx;
    }
    return 0;
  }

  private parseWeeklyForecast(result: Record<string, Object>): DailyForecastItem[] {
    const daily = result['daily'] as Record<string, Array<number | string>> | undefined;
    if (!daily) {
      return [];
    }

    const dates = daily['time'] as string[] | undefined;
    const maxTemps = daily['temperature_2m_max'] as number[] | undefined;
    const minTemps = daily['temperature_2m_min'] as number[] | undefined;
    const codes = daily['weather_code'] as number[] | undefined;
    const precipitation = daily['precipitation_probability_max'] as number[] | undefined;
    const uvIndex = daily['uv_index_max'] as number[] | undefined;
    const sunrise = daily['sunrise'] as string[] | undefined;
    const sunset = daily['sunset'] as string[] | undefined;
    if (!dates || !maxTemps || !minTemps || !codes) {
      return [];
    }

    const maxCount = Math.min(dates.length, maxTemps.length, minTemps.length, codes.length, 7);
    const list: DailyForecastItem[] = [];
    for (let i = 0; i < maxCount; i++) {
      list.push({
        date: String(dates[i]),
        minTemperature: Number(minTemps[i]),
        maxTemperature: Number(maxTemps[i]),
        precipitationProbability: Number(precipitation?.[i] ?? 0),
        uvIndex: Number(uvIndex?.[i] ?? 0),
        sunrise: String(sunrise?.[i] ?? ''),
        sunset: String(sunset?.[i] ?? ''),
        weatherCode: Number(codes[i])
      });
    }
    return list;
  }

  private buildDressingAdvice(temperature: number, windSpeed: number, weatherCode: number): string {
    const temp = Number.isFinite(temperature) ? temperature : 0;
    const wind = Number.isFinite(windSpeed) ? windSpeed : 0;

    let base: string;
    if (temp >= 28) base = '天气偏热，建议短袖/薄裙，注意补水与防晒。';
    else if (temp >= 20) base = '体感舒适，建议短袖或薄长袖，早晚可备一件薄外套。';
    else if (temp >= 12) base = '天气偏凉，建议长袖+外套，注意保暖。';
    else if (temp >= 5) base = '天气较冷，建议厚外套/毛衣，注意防寒。';
    else base = '天气寒冷，建议羽绒服/厚外套，注意保暖防冻。';

    const windy = wind >= 20;
    const rainy = (weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 99);
    const snowy = weatherCode >= 71 && weatherCode <= 77;

    const extras: string[] = [];
    if (windy) extras.push('风较大，建议加防风外层。');
    if (rainy) extras.push('可能有雨，建议带伞或雨衣。');
    if (snowy) extras.push('可能有雪，注意防滑保暖。');

    return extras.length > 0 ? `${base}${extras.join('')}` : base;
  }

  private static isRainOrStorm(code: number): boolean {
    return (code >= 51 && code <= 67) || (code >= 80 && code <= 99);
  }

  private static isSnow(code: number): boolean {
    return code >= 71 && code <= 77;
  }

  private static isFog(code: number): boolean {
    return code >= 45 && code <= 48;
  }

  private buildLifeIndexAdvice(
    temperature: number,
    apparentTemperature: number,
    windSpeed: number,
    humidity: number,
    precipitationProbability: number,
    visibility: number,
    uvIndex: number,
    weatherCode: number
  ): LifeIndexAdvice {
    const temp = Number.isFinite(temperature) ? temperature : 0;
    const apparent = Number.isFinite(apparentTemperature) ? apparentTemperature : temp;
    const wind = Number.isFinite(windSpeed) ? windSpeed : 0;
    const hum = Number.isFinite(humidity) ? humidity : 50;
    const precip = Number.isFinite(precipitationProbability) ? precipitationProbability : 0;
    const vis = Number.isFinite(visibility) ? visibility : 10000;
    const uv = Number.isFinite(uvIndex) ? uvIndex : 0;
    const code = Number.isFinite(weatherCode) ? weatherCode : -1;

    return {
      dressing: this.buildDressingAdvice(temp, wind, code),
      travel: this.buildTravelAdvice(temp, wind, precip, vis, code),
      exercise: this.buildExerciseAdvice(temp, apparent, wind, precip, code),
      carWash: this.buildCarWashAdvice(precip, wind, code),
      cold: this.buildColdAdvice(temp, apparent, hum, wind, code),
      laundry: this.buildLaundryAdvice(temp, wind, precip, hum, vis, code)
    };
  }

  private buildTravelAdvice(
    temp: number,
    wind: number,
    precipProb: number,
    visibilityM: number,
    code: number
  ): string {
    if (WeatherService.isFog(code) || visibilityM < 2000) {
      return '能见度偏低，驾车请减速、开雾灯，尽量推迟长途出行。';
    }
    if (code >= 95 || code === 96 || code === 99) {
      return '有强对流/雷暴风险，尽量减少外出与户外停留，注意交通安全。';
    }
    if (WeatherService.isRainOrStorm(code) || precipProb >= 60) {
      return '降水概率较高，出行请带雨具，路面湿滑注意防滑。';
    }
    if (wind >= 28) {
      return '风力较大，骑行与高空作业需谨慎，注意坠物。';
    }
    if (temp <= -5 || temp >= 35) {
      return '气温极端，长途出行请做好保暖或防暑，备好饮用水。';
    }
    return '天气条件总体适宜出行，仍请关注路况与实时预报。';
  }

  private buildExerciseAdvice(
    temp: number,
    apparent: number,
    wind: number,
    precipProb: number,
    code: number
  ): string {
    if (WeatherService.isRainOrStorm(code) || precipProb >= 50) {
      return '有雨或降水概率高，建议改为室内运动。';
    }
    if (code >= 95) {
      return '雷雨天气，请避免户外运动与树下停留。';
    }
    if (temp >= 32 || apparent >= 34) {
      return '高温闷热，建议清晨或傍晚短时锻炼，及时补水，避免中暑。';
    }
    if (temp <= 0 || apparent <= -2) {
      return '气温偏低，户外运动前充分热身，注意保暖与关节防护。';
    }
    if (wind >= 25) {
      return '风大，户外跑步/骑行强度宜降低，注意防风。';
    }
    if (temp >= 15 && temp <= 26 && precipProb < 30) {
      return '气温舒适、天气较稳，适合散步、慢跑等户外运动。';
    }
    return '可根据体感选择中等强度运动，注意循序渐进与补水。';
  }

  private buildCarWashAdvice(precipProb: number, wind: number, code: number): string {
    if (WeatherService.isRainOrStorm(code) || precipProb >= 40) {
      return '近期易有降水，不宜洗车，以免很快弄脏。';
    }
    if (WeatherService.isSnow(code)) {
      return '有降雪或路面融雪剂，建议暂缓洗车。';
    }
    if (wind >= 30) {
      return '风力大易扬尘，洗车效果可能维持较短，可择日再洗。';
    }
    if (precipProb < 20 && (code === 0 || (code >= 1 && code <= 3))) {
      return '未来一段时间降水概率低，较适宜洗车。';
    }
    return '天气尚可，如需洗车可安排，仍建议关注短时预报。';
  }

  private buildColdAdvice(temp: number, apparent: number, hum: number, wind: number, code: number): string {
    const gap = Math.abs(temp - apparent);
    if (temp < 8 && hum >= 70 && wind >= 15) {
      return '湿冷明显，易诱发呼吸道不适，注意保暖与室内通风。';
    }
    if (gap >= 6) {
      return '体感与气温差异较大，注意增减衣物，预防感冒。';
    }
    if (temp < 5) {
      return '气温较低，儿童与老人更需注意保暖，减少长时间户外停留。';
    }
    if (WeatherService.isRainOrStorm(code) && temp < 15) {
      return '阴雨湿冷，抵抗力易下降，注意防雨与足部保暖。';
    }
    if (temp >= 18 && temp <= 26 && hum >= 40 && hum <= 65) {
      return '温湿度较舒适，感冒风险相对不高，仍建议规律作息。';
    }
    return '关注天气变化，适时穿衣，勤洗手、多饮水，有助降低感冒风险。';
  }

  private buildLaundryAdvice(
    temp: number,
    wind: number,
    precipProb: number,
    hum: number,
    vis: number,
    code: number
  ): string {
    if (WeatherService.isRainOrStorm(code) || precipProb >= 35) {
      return '易有降水，不宜室外晾晒，建议使用烘干机或室内阴干。';
    }
    if (WeatherService.isFog(code) || vis < 3000) {
      return '湿度大、能见度一般，衣物不易干透，不宜户外晾晒。';
    }
    if (hum >= 85) {
      return '空气湿度高，晾晒偏慢，可选通风好的时段或辅助除湿。';
    }
    if ((code === 0 || (code >= 1 && code <= 3)) && wind >= 8 && precipProb < 25 && hum < 75) {
      return '晴到多云、有风、湿度适中，较适宜户外晾晒。';
    }
    if (temp >= 20 && wind >= 5 && precipProb < 30) {
      return '天气尚可，可晾晒，留意傍晚是否转潮或起风。';
    }
    return '可根据阳台通风情况短时晾晒，关注未来几小时是否转阴或下雨。';
  }
}
