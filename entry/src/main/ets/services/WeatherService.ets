import http from '@ohos.net.http';
import { geoLocationManager } from '@kit.LocationKit';

export interface WeatherInfo {
  city: string;
  temperature: number;
  windSpeed: number;
  weatherCode: number;
  updateTime: string;
  forecast: ForecastItem[];
  weeklyForecast: DailyForecastItem[];
  dressingAdvice: string;
}

export interface ForecastItem {
  time: string;
  temperature: number;
  weatherCode: number;
}

export interface DailyForecastItem {
  date: string;
  minTemperature: number;
  maxTemperature: number;
  weatherCode: number;
}

interface Coordinate {
  latitude: number;
  longitude: number;
}

interface CurrentWeatherWithForecast {
  temperature: number;
  windSpeed: number;
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

  async queryCurrentCityWeather(): Promise<WeatherInfo> {
    const coordinate = await this.getCurrentCoordinate();
    const weatherPromise = this.queryCurrentWeatherWithForecast(coordinate);
    const cityFallback = this.buildCoordinateCityFallback(coordinate);
    const cityPromise = this.withTimeout(this.reverseGeocodeCity(coordinate), 4500, cityFallback);

    const weather = await weatherPromise;
    const city = await cityPromise;
    const dressingAdvice = this.buildDressingAdvice(weather.temperature, weather.windSpeed, weather.weatherCode);

    return {
      city,
      temperature: weather.temperature,
      windSpeed: weather.windSpeed,
      weatherCode: weather.weatherCode,
      updateTime: weather.time,
      forecast: weather.forecast,
      weeklyForecast: weather.weeklyForecast,
      dressingAdvice
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
    const coordinate = await this.geocodeCity(cityName);
    const weather = await this.queryCurrentWeatherWithForecast(coordinate);
    const dressingAdvice = this.buildDressingAdvice(weather.temperature, weather.windSpeed, weather.weatherCode);
    return {
      city: cityName,
      temperature: weather.temperature,
      windSpeed: weather.windSpeed,
      weatherCode: weather.weatherCode,
      updateTime: weather.time,
      forecast: weather.forecast,
      weeklyForecast: weather.weeklyForecast,
      dressingAdvice
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
      const url = `https://nominatim.openstreetmap.org/reverse?lat=${coordinate.latitude}&lon=${coordinate.longitude}&format=json&accept-language=zh-CN`;
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
      if (!address) {
        return undefined;
      }

      return address['city']
        || address['town']
        || address['county']
        || address['municipality']
        || address['state_district']
        || address['city_district']
        || address['state']
        || address['village']
        || address['suburb']
        || undefined;
    } catch (_) {
      return undefined;
    } finally {
      client.destroy();
    }
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

  private async geocodeCity(cityName: string): Promise<Coordinate> {
    const client = http.createHttp();
    try {
      const encoded = encodeURIComponent(cityName);
      const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encoded}&count=1&language=zh&format=json`;
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING
      });

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`城市查询失败: ${response.responseCode}`);
      }

      const result = JSON.parse(response.result as string) as Record<string, Object>;
      const rows = result['results'] as Array<Record<string, number>> | undefined;
      if (!rows || rows.length === 0) {
        throw new Error('未找到该城市');
      }

      return {
        latitude: Number(rows[0]['latitude']),
        longitude: Number(rows[0]['longitude'])
      };
    } finally {
      client.destroy();
    }
  }

  private async queryCurrentWeatherWithForecast(coordinate: Coordinate): Promise<CurrentWeatherWithForecast> {
    const client = http.createHttp();
    try {
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${coordinate.latitude}&longitude=${coordinate.longitude}&current=temperature_2m,wind_speed_10m,weather_code&hourly=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,weather_code&forecast_days=7`;
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING
      });

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`天气请求失败: ${response.responseCode}`);
      }

      const result = JSON.parse(response.result as string) as Record<string, Object>;
      const current = result['current'] as Record<string, number | string> | undefined;
      if (!current) {
        throw new Error('天气数据为空');
      }
      const forecast = this.parseForecast(result);
      const weeklyForecast = this.parseWeeklyForecast(result);

      return {
        temperature: Number(current['temperature_2m'] ?? 0),
        windSpeed: Number(current['wind_speed_10m'] ?? 0),
        weatherCode: Number(current['weather_code'] ?? -1),
        time: String(current['time'] ?? ''),
        forecast,
        weeklyForecast
      };
    } finally {
      client.destroy();
    }
  }

  private parseForecast(result: Record<string, Object>): ForecastItem[] {
    const hourly = result['hourly'] as Record<string, Array<number | string>> | undefined;
    if (!hourly) {
      return [];
    }

    const times = hourly['time'] as string[] | undefined;
    const temperatures = hourly['temperature_2m'] as number[] | undefined;
    const codes = hourly['weather_code'] as number[] | undefined;
    if (!times || !temperatures || !codes) {
      return [];
    }

    const maxCount = Math.min(times.length, temperatures.length, codes.length, 8);
    const list: ForecastItem[] = [];
    for (let i = 0; i < maxCount; i++) {
      list.push({
        time: String(times[i]),
        temperature: Number(temperatures[i]),
        weatherCode: Number(codes[i])
      });
    }
    return list;
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
}
