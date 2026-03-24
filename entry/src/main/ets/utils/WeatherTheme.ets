/**
 * 与天气场景协调的渐变 + 文字 / 卡片配色（随 weather_code 变化）
 *
 * 卡片类颜色多为 #AARRGGBB 磨砂半透明，层级约：
 * 主信息区（hero）最不透明 → 指标/搜索 → 模块容器 → 列表行/药片更透；描边与阴影偏弱以衬在渐变背景上。
 */

export interface WeatherUiPalette {
  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  textSubtle: string;
  pageTitle: string;
  heroTemp: string;
  metaDim: string;
  searchTint: string;
  searchShadow: string;
  searchLabel: string;
  inputFill: string;
  accent: string;
  accentDeep: string;
  onAccent: string;
  ghostBtnBg: string;
  ghostBtnText: string;
  ghostBtnBorder: string;
  heroCardBg: string;
  heroCardBorder: string;
  metricsCardBg: string;
  metricsCardBorder: string;
  metricsTitle: string;
  metricsBody: string;
  adviceShell: string;
  adviceInner: string;
  adviceTitle: string;
  adviceBody: string;
  hourlyModuleBg: string;
  hourlyModuleBorder: string;
  hourlyTitle: string;
  hourlyChipBg: string;
  hourlyChipText: string;
  hourlyHint: string;
  hourlyPillBg: string;
  hourlyPillBorder: string;
  hourlyTime: string;
  hourlyTemp: string;
  hourlyMeta: string;
  moreRowBg: string;
  moreRowBorder: string;
  moreTitle: string;
  moreSub: string;
  moreArrow: string;
  shadowSoft: string;
  shadowCard: string;
  shadowSearch: string;
  shadowFab: string;
  error: string;
  dialogNeutral: string;
  dialogAccent: string;
  listRow: string;
  deleteBtn: string;
}

const PALETTE_CLEAR: WeatherUiPalette = {
  textPrimary: '#0C2438',
  textSecondary: '#2A4A68',
  textMuted: '#5A738A',
  textSubtle: '#6E879E',
  pageTitle: '#082038',
  heroTemp: '#062D50',
  metaDim: '#4A6780',
  searchTint: '#D0C2E4FA',
  searchShadow: '#335A9E29',
  searchLabel: '#0E2A46',
  inputFill: '#E8FFFFFF',
  accent: '#1B6FD6',
  accentDeep: '#144C99',
  onAccent: '#FFFFFF',
  ghostBtnBg: '#D8FFFFFF',
  ghostBtnText: '#144C99',
  ghostBtnBorder: '#6FA8E8',
  heroCardBg: '#DDFFFCF8',
  heroCardBorder: '#55B8CCE8',
  metricsCardBg: '#C8F5FAFF',
  metricsCardBorder: '#5098C0D8',
  metricsTitle: '#0A2845',
  metricsBody: '#4A6680',
  adviceShell: '#CCFFFDF8',
  adviceInner: '#B8FFEEDD',
  adviceTitle: '#4A3418',
  adviceBody: '#524535',
  hourlyModuleBg: '#CAFFFBF8',
  hourlyModuleBorder: '#4890B8D0',
  hourlyTitle: '#0E2A46',
  hourlyChipBg: '#A8E8F2FA',
  hourlyChipText: '#3D5C76',
  hourlyHint: '#6B879E',
  hourlyPillBg: '#B8F2F8FF',
  hourlyPillBorder: '#4498B8C8',
  hourlyTime: '#3D5C76',
  hourlyTemp: '#0E2A46',
  hourlyMeta: '#5E7A90',
  moreRowBg: '#A8D4E8FA',
  moreRowBorder: '#5098B8B0',
  moreTitle: '#0A2845',
  moreSub: '#4A6580',
  moreArrow: '#1B6FD6',
  shadowSoft: '#1A305509',
  shadowCard: '#1A305514',
  shadowSearch: '#2D528026',
  shadowFab: '#1B6FD638',
  error: '#C43232',
  dialogNeutral: '#5C6570',
  dialogAccent: '#1B6FD6',
  listRow: '#A5EBF4FC',
  deleteBtn: '#C95454'
};

const PALETTE_CLOUD: WeatherUiPalette = {
  textPrimary: '#162C38',
  textSecondary: '#3A5060',
  textMuted: '#5C7080',
  textSubtle: '#738898',
  pageTitle: '#122630',
  heroTemp: '#1A303E',
  metaDim: '#4A6270',
  searchTint: '#C8D6E2',
  searchShadow: '#3D4F5E2A',
  searchLabel: '#1A2F3D',
  inputFill: '#E5F7FAFC',
  accent: '#3A6D9E',
  accentDeep: '#2A5078',
  onAccent: '#FFFFFF',
  ghostBtnBg: '#D5F2F4F8',
  ghostBtnText: '#2A5078',
  ghostBtnBorder: '#8BA8BC',
  heroCardBg: '#D8F4F7F9',
  heroCardBorder: '#5090A0A8',
  metricsCardBg: '#C4EEF2F5',
  metricsCardBorder: '#4880989C',
  metricsTitle: '#142E3C',
  metricsBody: '#4D6472',
  adviceShell: '#CAF6F7F8',
  adviceInner: '#B0E8EAEE',
  adviceTitle: '#424038',
  adviceBody: '#48433C',
  hourlyModuleBg: '#CCF6F8FA',
  hourlyModuleBorder: '#488898A4',
  hourlyTitle: '#1A2F3D',
  hourlyChipBg: '#A8DEE4EC',
  hourlyChipText: '#465A6A',
  hourlyHint: '#758899',
  hourlyPillBg: '#B8E6ECF0',
  hourlyPillBorder: '#4090A0AC',
  hourlyTime: '#465A6A',
  hourlyTemp: '#1A2F3D',
  hourlyMeta: '#627889',
  moreRowBg: '#A8D4DCE4',
  moreRowBorder: '#50808898',
  moreTitle: '#142E3C',
  moreSub: '#5A6E7D',
  moreArrow: '#3A6D9E',
  shadowSoft: '#1E2D3A0A',
  shadowCard: '#1E2D3A12',
  shadowSearch: '#33445528',
  shadowFab: '#3A6D9E38',
  error: '#B84040',
  dialogNeutral: '#5C6570',
  dialogAccent: '#3A6D9E',
  listRow: '#A0E0E8EE',
  deleteBtn: '#C24A4A'
};

const PALETTE_FOG: WeatherUiPalette = {
  textPrimary: '#28303C',
  textSecondary: '#485462',
  textMuted: '#5E6C78',
  textSubtle: '#778490',
  pageTitle: '#202830',
  heroTemp: '#262E38',
  metaDim: '#566270',
  searchTint: '#C8CCD4',
  searchShadow: '#3A45522C',
  searchLabel: '#2D3540',
  inputFill: '#E6F6F7F8',
  accent: '#4F6880',
  accentDeep: '#3A5066',
  onAccent: '#FFFFFF',
  ghostBtnBg: '#D8F4F5F6',
  ghostBtnText: '#3A5066',
  ghostBtnBorder: '#8A98A5',
  heroCardBg: '#D5F2F3F5',
  heroCardBorder: '#509098A0',
  metricsCardBg: '#C4ECEEF0',
  metricsCardBorder: '#48808894',
  metricsTitle: '#242E38',
  metricsBody: '#505862',
  adviceShell: '#CAF4F5F6',
  adviceInner: '#B0E6E8EA',
  adviceTitle: '#403C38',
  adviceBody: '#45423C',
  hourlyModuleBg: '#CCF3F5F6',
  hourlyModuleBorder: '#48808894',
  hourlyTitle: '#2D3540',
  hourlyChipBg: '#A8D8DCE0',
  hourlyChipText: '#4B5563',
  hourlyHint: '#7F8C99',
  hourlyPillBg: '#B8E2E5E8',
  hourlyPillBorder: '#40808898',
  hourlyTime: '#4B5563',
  hourlyTemp: '#2D3540',
  hourlyMeta: '#6B7683',
  moreRowBg: '#A8CCD0D6',
  moreRowBorder: '#50808890',
  moreTitle: '#242E38',
  moreSub: '#667280',
  moreArrow: '#4F6880',
  shadowSoft: '#2A33400C',
  shadowCard: '#2A334014',
  shadowSearch: '#3A455228',
  shadowFab: '#4F688038',
  error: '#B03D3D',
  dialogNeutral: '#5C636B',
  dialogAccent: '#4F6880',
  listRow: '#9CD8DEE4',
  deleteBtn: '#B74A4A'
};

const PALETTE_RAIN: WeatherUiPalette = {
  textPrimary: '#0E2030',
  textSecondary: '#2A4460',
  textMuted: '#4A6080',
  textSubtle: '#607890',
  pageTitle: '#0A1C2C',
  heroTemp: '#0C2640',
  metaDim: '#345468',
  searchTint: '#B8D0E8',
  searchShadow: '#1E3A5530',
  searchLabel: '#122536',
  inputFill: '#DEE8F4FC',
  accent: '#2463A6',
  accentDeep: '#1A4878',
  onAccent: '#FFFFFF',
  ghostBtnBg: '#D0E6F2FA',
  ghostBtnText: '#1A4878',
  ghostBtnBorder: '#6898C8',
  heroCardBg: '#D2E8F4FA',
  heroCardBorder: '#5098B8CC',
  metricsCardBg: '#BEE0EEFA',
  metricsCardBorder: '#4888A8C0',
  metricsTitle: '#10384C',
  metricsBody: '#3A5870',
  adviceShell: '#CCEAF2F8',
  adviceInner: '#B0D8E4EF',
  adviceTitle: '#344050',
  adviceBody: '#38455C',
  hourlyModuleBg: '#CAE8F2FA',
  hourlyModuleBorder: '#4880A0B8',
  hourlyTitle: '#122536',
  hourlyChipBg: '#A8D0E4F0',
  hourlyChipText: '#2F4660',
  hourlyHint: '#647D99',
  hourlyPillBg: '#B8D8E8F4',
  hourlyPillBorder: '#4080A0B0',
  hourlyTime: '#2F4660',
  hourlyTemp: '#122536',
  hourlyMeta: '#5A7390',
  moreRowBg: '#98C8DCE8',
  moreRowBorder: '#488098B4',
  moreTitle: '#10384C',
  moreSub: '#4A6280',
  moreArrow: '#2463A6',
  shadowSoft: '#14283A0C',
  shadowCard: '#14283A14',
  shadowSearch: '#1E3A5530',
  shadowFab: '#2463A638',
  error: '#C13838',
  dialogNeutral: '#5A6474',
  dialogAccent: '#2463A6',
  listRow: '#98C8D8EC',
  deleteBtn: '#C24E4E'
};

const PALETTE_SNOW: WeatherUiPalette = {
  textPrimary: '#122E3E',
  textSecondary: '#305468',
  textMuted: '#4A6885',
  textSubtle: '#64889C',
  pageTitle: '#0E2836',
  heroTemp: '#123848',
  metaDim: '#3E6070',
  searchTint: '#C8E2F0',
  searchShadow: '#2A55702C',
  searchLabel: '#173242',
  inputFill: '#E4F6FAFD',
  accent: '#2E7CB8',
  accentDeep: '#1E5C8A',
  onAccent: '#FFFFFF',
  ghostBtnBg: '#D4EEF6FA',
  ghostBtnText: '#1E5C8A',
  ghostBtnBorder: '#78A8C8',
  heroCardBg: '#D6EEF6FA',
  heroCardBorder: '#5098B8C8',
  metricsCardBg: '#C2E6F0F8',
  metricsCardBorder: '#4888A4B8',
  metricsTitle: '#10344C',
  metricsBody: '#385C70',
  adviceShell: '#CCEAF4F8',
  adviceInner: '#B8DCE8F0',
  adviceTitle: '#304050',
  adviceBody: '#384858',
  hourlyModuleBg: '#CAECF4FA',
  hourlyModuleBorder: '#4888A8BC',
  hourlyTitle: '#173242',
  hourlyChipBg: '#A8D8E8F4',
  hourlyChipText: '#35586C',
  hourlyHint: '#6E8BA0',
  hourlyPillBg: '#B8E0EEF8',
  hourlyPillBorder: '#4088A0B0',
  hourlyTime: '#35586C',
  hourlyTemp: '#173242',
  hourlyMeta: '#5E7C92',
  moreRowBg: '#A0D0E4F0',
  moreRowBorder: '#488098B0',
  moreTitle: '#10344C',
  moreSub: '#527289',
  moreArrow: '#2E7CB8',
  shadowSoft: '#1735480C',
  shadowCard: '#17354814',
  shadowSearch: '#2A55702A',
  shadowFab: '#2E7CB838',
  error: '#BC3838',
  dialogNeutral: '#566574',
  dialogAccent: '#2E7CB8',
  listRow: '#98C8DCEC',
  deleteBtn: '#C24A4A'
};

const PALETTE_STORM: WeatherUiPalette = {
  textPrimary: '#121824',
  textSecondary: '#283444',
  textMuted: '#465464',
  textSubtle: '#5E6C78',
  pageTitle: '#0E1420',
  heroTemp: '#102030',
  metaDim: '#344050',
  searchTint: '#A8B4C8',
  searchShadow: '#1A243632',
  searchLabel: '#151C28',
  inputFill: '#D8E4E8F0',
  accent: '#374E96',
  accentDeep: '#283878',
  onAccent: '#FFFFFF',
  ghostBtnBg: '#C8D4DCE8',
  ghostBtnText: '#283878',
  ghostBtnBorder: '#6880A8',
  heroCardBg: '#C8D4DCE8',
  heroCardBorder: '#5090A0B8',
  metricsCardBg: '#B8C8D4E4',
  metricsCardBorder: '#488090A8',
  metricsTitle: '#161E30',
  metricsBody: '#3A4654',
  adviceShell: '#C8D4DCE8',
  adviceInner: '#A8B4C4D8',
  adviceTitle: '#303640',
  adviceBody: '#383C48',
  hourlyModuleBg: '#CCD0DCE8',
  hourlyModuleBorder: '#4890A0AC',
  hourlyTitle: '#151C28',
  hourlyChipBg: '#98A8BCD0',
  hourlyChipText: '#2E3848',
  hourlyHint: '#6A7584',
  hourlyPillBg: '#B0BCD0DC',
  hourlyPillBorder: '#408090A0',
  hourlyTime: '#2E3848',
  hourlyTemp: '#151C28',
  hourlyMeta: '#576272',
  moreRowBg: '#90A8B8CC',
  moreRowBorder: '#48708898',
  moreTitle: '#161E30',
  moreSub: '#4A5666',
  moreArrow: '#374E96',
  shadowSoft: '#0F162010',
  shadowCard: '#0F162016',
  shadowSearch: '#1A243638',
  shadowFab: '#374E9640',
  error: '#C93838',
  dialogNeutral: '#5A5F6B',
  dialogAccent: '#374E96',
  listRow: '#90A0B4C8',
  deleteBtn: '#C24A4A'
};

function paletteIndexFromCode(code: number): number {
  if (code === 0) {
    return 0;
  }
  if (code >= 1 && code <= 3) {
    return 1;
  }
  if (code >= 45 && code <= 48) {
    return 2;
  }
  if (code >= 51 && code <= 67) {
    return 3;
  }
  if (code >= 71 && code <= 77) {
    return 4;
  }
  if (code >= 80 && code <= 99) {
    return 5;
  }
  return 1;
}

const PALETTES: WeatherUiPalette[] = [
  PALETTE_CLEAR,
  PALETTE_CLOUD,
  PALETTE_FOG,
  PALETTE_RAIN,
  PALETTE_SNOW,
  PALETTE_STORM
];

export function weatherUiPalette(code: number): WeatherUiPalette {
  return PALETTES[paletteIndexFromCode(code)];
}

export function weatherBackgroundGradient(code: number): Array<[string, number]> {
  if (code === 0) {
    return [['#4A9FFF', 0.0], ['#8EC5FF', 0.45], ['#E8F4FF', 1.0]];
  }
  if (code >= 1 && code <= 3) {
    return [['#7D93A8', 0.0], ['#AAB8C5', 0.5], ['#DFE6EC', 1.0]];
  }
  if (code >= 45 && code <= 48) {
    return [['#8A96A3', 0.0], ['#B5BDC6', 0.55], ['#E4E8ED', 1.0]];
  }
  if (code >= 51 && code <= 67) {
    return [['#3D5A80', 0.0], ['#6B8BAA', 0.5], ['#B8CDE0', 1.0]];
  }
  if (code >= 71 && code <= 77) {
    return [['#6A8CA8', 0.0], ['#9EB8CC', 0.5], ['#EAF2F8', 1.0]];
  }
  if (code >= 80 && code <= 99) {
    return [['#2C3A52', 0.0], ['#4B5D78', 0.45], ['#8FA0B5', 1.0]];
  }
  return [['#94A3B8', 0.0], ['#CBD5E1', 0.55], ['#F1F5F9', 1.0]];
}
