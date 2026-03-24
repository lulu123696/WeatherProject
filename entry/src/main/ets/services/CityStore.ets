import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'weather_city_store_v1';
const KEY_CITIES = 'cities';
const KEY_CURRENT = 'currentCity';
const KEY_FAVORITES = 'favorites';
const KEY_RECENT = 'recent';

export class CityStore {
  private static cities: string[] = ['北京', '上海'];
  private static currentCity: string = '';
  private static favorites: string[] = [];
  private static recent: string[] = [];
  private static pref: preferences.Preferences | null = null;
  private static loadTask: Promise<void> | null = null;

  static async ensureLoaded(context: common.Context): Promise<void> {
    if (CityStore.pref !== null) {
      return;
    }
    if (CityStore.loadTask === null) {
      CityStore.loadTask = CityStore.loadFromDisk(context);
    }
    await CityStore.loadTask;
  }

  private static async loadFromDisk(context: common.Context): Promise<void> {
    try {
      CityStore.pref = await preferences.getPreferences(context, PREF_NAME);
      const citiesRaw = (await CityStore.pref.get(KEY_CITIES, '[]')) as string;
      const curRaw = (await CityStore.pref.get(KEY_CURRENT, '')) as string;
      const favRaw = (await CityStore.pref.get(KEY_FAVORITES, '[]')) as string;
      const recRaw = (await CityStore.pref.get(KEY_RECENT, '[]')) as string;

      CityStore.cities = CityStore.parseStringArray(citiesRaw);
      if (CityStore.cities.length === 0) {
        CityStore.cities = ['北京', '上海'];
      }
      CityStore.currentCity = typeof curRaw === 'string' ? curRaw.trim() : '';
      CityStore.favorites = CityStore.parseStringArray(favRaw);
      CityStore.recent = CityStore.parseStringArray(recRaw).slice(0, 20);
    } catch (_) {
      CityStore.pref = null;
    }
  }

  private static parseStringArray(raw: string): string[] {
    if (!raw || raw.length === 0) {
      return [];
    }
    try {
      const v = JSON.parse(raw) as Object[];
      if (!Array.isArray(v)) {
        return [];
      }
      const out: string[] = [];
      for (let i = 0; i < v.length; i++) {
        const s = v[i];
        if (typeof s === 'string') {
          const t = s.trim();
          if (t.length > 0 && out.indexOf(t) < 0) {
            out.push(t);
          }
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  private static async persist(): Promise<void> {
    const p = CityStore.pref;
    if (p === null) {
      return;
    }
    try {
      await p.put(KEY_CITIES, JSON.stringify(CityStore.cities));
      await p.put(KEY_CURRENT, CityStore.currentCity);
      await p.put(KEY_FAVORITES, JSON.stringify(CityStore.favorites));
      await p.put(KEY_RECENT, JSON.stringify(CityStore.recent));
      await p.flush();
    } catch (_) {
    }
  }

  static listCities(): string[] {
    return [...CityStore.cities];
  }

  static listFavorites(): string[] {
    return [...CityStore.favorites];
  }

  /** 最近访问（不含当前项也可切换；首页展示时仍可看到当前） */
  static listRecent(max: number = 12): string[] {
    return CityStore.recent.slice(0, max);
  }

  static isFavorite(city: string): boolean {
    const n = city.trim();
    return n.length > 0 && CityStore.favorites.indexOf(n) >= 0;
  }

  static addCity(city: string): void {
    const normalized = city.trim();
    if (!normalized) {
      return;
    }
    if (CityStore.cities.indexOf(normalized) < 0) {
      CityStore.cities = [normalized, ...CityStore.cities];
      void CityStore.persist();
    }
  }

  static removeCity(city: string): void {
    CityStore.cities = CityStore.cities.filter((item) => item !== city);
    CityStore.favorites = CityStore.favorites.filter((item) => item !== city);
    CityStore.recent = CityStore.recent.filter((item) => item !== city);
    if (CityStore.currentCity === city) {
      CityStore.currentCity = '';
    }
    void CityStore.persist();
  }

  static toggleFavorite(city: string): void {
    const n = city.trim();
    if (!n) {
      return;
    }
    if (CityStore.cities.indexOf(n) < 0) {
      CityStore.cities = [n, ...CityStore.cities];
    }
    const idx = CityStore.favorites.indexOf(n);
    if (idx >= 0) {
      CityStore.favorites = CityStore.favorites.filter((x) => x !== n);
    } else {
      CityStore.favorites = [n, ...CityStore.favorites.filter((x) => x !== n)];
    }
    void CityStore.persist();
  }

  static setCurrentCity(city: string): void {
    const normalized = city.trim();
    if (!normalized) {
      return;
    }
    CityStore.currentCity = normalized;
    if (CityStore.cities.indexOf(normalized) < 0) {
      CityStore.cities = [normalized, ...CityStore.cities];
    }
    CityStore.touchRecent(normalized);
    void CityStore.persist();
  }

  private static touchRecent(normalized: string): void {
    CityStore.recent = [normalized, ...CityStore.recent.filter((c) => c !== normalized)].slice(0, 20);
  }

  static getCurrentCity(): string {
    return CityStore.currentCity;
  }

  /** 仅从最近列表移除（不删除收藏与城市池） */
  static removeFromRecent(city: string): void {
    const n = city.trim();
    if (!n) {
      return;
    }
    CityStore.recent = CityStore.recent.filter((c) => c !== n);
    void CityStore.persist();
  }
}
