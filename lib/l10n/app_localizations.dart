import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'YouBike Finder',
      'searchPlaceholder': 'Search for stations...',
      'settings': 'Settings',
      'location': 'My Location',
      'refresh': 'Refresh',
      'debug': 'Debug',
      'recentStations': 'Recent Stations',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'about': 'About',
      'updatingIn': 'Updating in {seconds}s',
      'electricBikeDetailsTitle': 'Electric Bike Details: {name}',
      'gettingBikeData': 'Fetching bike data...',
      'bikeNumber': 'Bike No: {no}',
      'pillarNumber': 'Pillar No: {no}',
      'batteryPower': 'Battery: {power}%',
      'noElectricBikes': 'No electric bikes available',
      'electricBikeError': 'Failed to get electric bike info: {error}',
      'routeTo': 'Route to {name}',
      'calculatingRoute': 'Calculating route...',
      'routeNotFound': 'Route not found',
      'distance': 'Distance: {dist}',
      'estimatedTime': 'Estimated Time: {time} minutes',
      'retry': 'Retry',
      'ok': 'OK',
      'loading': 'Loading: {progress}%',
      'loadingNotice': 'Notice: {notice}',
    },
    'zh': {
      'appTitle': 'YouBike 站點搜尋',
      'searchPlaceholder': '搜尋站點名稱...',
      'settings': '設定',
      'location': '我的位置',
      'refresh': '重新整理',
      'debug': '偵錯',
      'recentStations': '最近站牌',
      'darkMode': '深色模式',
      'language': '語言',
      'about': '關於',
      'updatingIn': '更新於 {seconds}s',
      'electricBikeDetailsTitle': '電輔車詳細資訊: {name}',
      'gettingBikeData': '正在獲取車輛資料...',
      'bikeNumber': '車號: {no}',
      'pillarNumber': '車位: {no}',
      'batteryPower': '電量: {power}%',
      'noElectricBikes': '目前無可用電輔車',
      'electricBikeError': '獲取電輔車資訊失敗: {error}',
      'routeTo': '前往 {name} 的路線',
      'calculatingRoute': '計算路線中...',
      'routeNotFound': '找不到路線',
      'distance': '距離: {dist}',
      'estimatedTime': '預計時間: {time} 分鐘',
      'retry': '重整',
      'ok': '確定',
      'loading': '載入中：{progress}%',
      'loadingNotice': '通知: {notice}',
    },
  };

  String translate(String key, [Map<String, String>? params]) {
    String lang = locale.languageCode;
    String value = _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceFirst('{$k}', v);
      });
    }
    return value;
  }

  String get appTitle => translate('appTitle');
  String get searchPlaceholder => translate('searchPlaceholder');
  String get settings => translate('settings');
  String get location => translate('location');
  String get refresh => translate('refresh');
  String get debug => translate('debug');
  String get recentStations => translate('recentStations');
  String get darkMode => translate('darkMode');
  String get language => translate('language');
  String get about => translate('about');
  String updatingIn(String seconds) => translate('updatingIn', {'seconds': seconds});
  String electricBikeDetailsTitle(String name) => translate('electricBikeDetailsTitle', {'name': name});
  String get gettingBikeData => translate('gettingBikeData');
  String bikeNumber(String no) => translate('bikeNumber', {'no': no});
  String pillarNumber(String no) => translate('pillarNumber', {'no': no});
  String batteryPower(String power) => translate('batteryPower', {'power': power});
  String get noElectricBikes => translate('noElectricBikes');
  String electricBikeError(String error) => translate('electricBikeError', {'error': error});
  String routeTo(String name) => translate('routeTo', {'name': name});
  String get calculatingRoute => translate('calculatingRoute');
  String get routeNotFound => translate('routeNotFound');
  String distance(String dist) => translate('distance', {'dist': dist});
  String estimatedTime(String time) => translate('estimatedTime', {'time': time});
  String get retry => translate('retry');
  String get ok => translate('ok');
  String loading(String progress) => translate('loading', {'progress': progress});
  String loadingNotice(String notice) => translate('loadingNotice', {'notice': notice});
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
