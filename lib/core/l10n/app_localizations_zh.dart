// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get init_starting => '啟動中...';

  @override
  String get init_locating => '定位中...';

  @override
  String get app_full_title => 'YouBike 站點搜尋 : 一個簡單、美觀、低流量的YouBike站點搜尋器';

  @override
  String get use_location => '使用定位';

  @override
  String get input_placeholder => '請輸入站點名稱、地址';

  @override
  String get countdown_suffix => '秒後更新';

  @override
  String get settings_title => '系統設定';

  @override
  String get settings_basic => '基本設定';

  @override
  String get settings_github => 'GitHub 儲存庫';

  @override
  String get settings_location => '位置服務';

  @override
  String get settings_dark_mode => '深色模式';

  @override
  String get settings_language => '語言';

  @override
  String get settings_language_title => '語言';

  @override
  String get lang_zh => '繁體中文';

  @override
  String get lang_en => 'English';

  @override
  String get settings_theme => '主題';

  @override
  String get settings_region => '地區選擇';

  @override
  String get countdown_unit => '秒後';

  @override
  String get countdown_text => '更新';

  @override
  String get dist_m => '公尺';

  @override
  String get dist_km => '公里';

  @override
  String get electric_bike_details_title => '電輔車列表 - ';

  @override
  String get bike_number_label => '車輛編號：';

  @override
  String get pillar_number_label => '停車柱編號：';

  @override
  String get battery_power_label => '電量：';

  @override
  String get no_electric_bikes => '此站點目前沒有可用的電輔車。';

  @override
  String get failed_to_get_bike_data => '無法取得電輔車資料。';

  @override
  String get getting_bike_data => '取得電輔車資料中...';

  @override
  String get region_taipei => '台北市';

  @override
  String get region_new_taipei => '新北市';

  @override
  String get region_taoyuan => '桃園市';

  @override
  String get region_hsinchu_county => '新竹縣';

  @override
  String get region_hsinchu_city => '新竹市';

  @override
  String get region_science_park => '新竹科學園區';

  @override
  String get region_miaoli => '苗栗縣';

  @override
  String get region_taichung => '台中市';

  @override
  String get region_chiayi => '嘉義市';

  @override
  String get region_tainan => '臺南市';

  @override
  String get region_kaohsiung => '高雄市';

  @override
  String get region_pingtung => '屏東縣';

  @override
  String get region_taitung => '臺東縣';

  @override
  String get routeNotFound => '找不到前往該站點的路徑';

  @override
  String get ok => '確定';

  @override
  String get distance => '距離: ';

  @override
  String get address => '地址: ';

  @override
  String get availableBikes => 'YouBike 2.0: ';

  @override
  String get availableElectricBikes => 'YouBike 2.0E: ';

  @override
  String get emptySpaces => '可停空位數: ';

  @override
  String get autoRefresh => '自動刷新';

  @override
  String get param_settings => '參數設定';

  @override
  String get about => '關於';

  @override
  String get app_reset => '重設 App';

  @override
  String get init_success => '初始化完成';

  @override
  String get notice_no_speed => '❌勿超速或逆向騎乘';

  @override
  String get notice_no_sidewalk => '❌勿隨意變換車道在行人道上騎乘';

  @override
  String get notice_no_phone => '❌勿在車輛行駛中使用手機';

  @override
  String get notice_no_brake => '❌騎乘中勿緊急煞車';

  @override
  String get notice_seat_height => '✔️記得調整座墊至適宜高度';

  @override
  String get notice_lights_work => '✔️確認前後車燈功能正常';

  @override
  String get notice_insurance => '✔️記得投保公共自行車傷害險';

  @override
  String get notice_take_belongings => '✔️記得帶走置物籃內的隨身物品';

  @override
  String updatingIn(String sec) {
    return '$sec秒後更新';
  }

  @override
  String electricBikeError(String err) {
    return '取得電輔車資料失敗: $err';
  }

  @override
  String loading_prefix(String progress) {
    return '載入中：$progress%';
  }

  @override
  String init_error(String error) {
    return '初始化過程出錯: $error';
  }

  @override
  String get locationTrackingEnabled => '位置追蹤已開啟';

  @override
  String get noStationsFound => '找不到符合的站點';

  @override
  String get navigationUnavailable => '導航服務不可用';

  @override
  String get updating => '更新中...';

  @override
  String get sec => '秒';

  @override
  String get go_to => '前往 ';

  @override
  String get unknown => '未知';

  @override
  String get init_syncing => '同步 GPS 數據中...';

  @override
  String get init_updating => '更新站點資料中...';

  @override
  String get update_stations => '更新站點';

  @override
  String get init_requesting_permission => '請求定位權限...';

  @override
  String get init_verifying_permission => '驗證權限狀態...';

  @override
  String get init_map_engine => '啟動地圖渲染引擎...';

  @override
  String get init_map_tiles => '配置區域地圖快取...';

  @override
  String get init_clustering => '初始化站點集群...';

  @override
  String get stations => '站點';

  @override
  String init_syncing_stations(int count) {
    return '同步 $count 個站點中...';
  }
}
