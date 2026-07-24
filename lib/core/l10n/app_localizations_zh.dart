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
  String get rentableBikes => '可借車輛數：';

  @override
  String get popupAvailableBikesLabel => '2.0';

  @override
  String get popupRentableBikesLabel => '可借';

  @override
  String get popupAvailableElectricBikesLabel => '2.0 E';

  @override
  String get popupEmptySpacesLabel => '空位';

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

  @override
  String get permission_location_title => '定位權限';

  @override
  String get permission_location_desc =>
      'YouBike 需要您的位置資訊來顯示附近的站點與距離。我們不會在背景追蹤您的位置。';

  @override
  String get permission_denied_title => '權限已被永久拒絕';

  @override
  String get permission_denied_content =>
      '您已永久拒絕定位權限。請前往裝置設定手動授予權限，或使用地區選擇來查看站點。';

  @override
  String get open_settings => '開啟設定';

  @override
  String get grant_permission => '授予權限';

  @override
  String get skip_permission_label => '暫時略過';

  @override
  String get skip_permission_confirm => '確認略過';

  @override
  String get skip_location_title => '略過定位權限';

  @override
  String get skip_location_desc =>
      '若略過定位權限，將使用您選擇的地區中心作為預設位置，無法顯示與您即時距離。您可以隨時在設定中開啟定位。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get setup_complete => '開始使用';

  @override
  String get setup_continue => '繼續';

  @override
  String get permission_notification_title => '通知權限';

  @override
  String get permission_notification_desc =>
      '啟用通知以接收 YouBike 站點資訊更新、推播訊息與重要提醒。您可以隨時在系統設定中變更此選項。';

  @override
  String get skip_notification_title => '略過通知權限';

  @override
  String get skip_notification_desc =>
      '若略過通知權限，您將不會收到 YouBike 的推播訊息與即站點更新提醒。您可以隨時在系統設定中開啟通知。';

  @override
  String get settings_notification_service => '通知服務';

  @override
  String get permission_group_title => '權限';

  @override
  String get notification_service_disable_title => '關閉通知服務';

  @override
  String get notification_service_disable_content =>
      'YouBike 通知是由系統的「應用程式通知」權限控制。請前往系統設定手動關閉通知權限。';

  @override
  String get about_youbike => '關於 YouBike';

  @override
  String get about_youbike_content =>
      'YouBike 站點搜尋是一款簡潔、美觀的 YouBike 即時查詢 App，使用 Flutter 打造，支援全台 13 個縣市的微笑單車站點搜尋與步行導航。';

  @override
  String get developer_label => '開發者：Andrew Cho (卓稟鈞)';

  @override
  String get github_source_code => 'GitHub 原始碼';

  @override
  String version_label(String version) {
    return '版本：$version';
  }

  @override
  String get view_release_notes => '查看版本資訊';

  @override
  String get view_changelog => '查看版本日誌';

  @override
  String get beta_features_page_title => 'Beta 版';

  @override
  String get beta_providers_group_title => '自行車系統';

  @override
  String get beta_moovo_provider => 'Moovo 自行車系統';

  @override
  String get beta_moovo_subtitle => '啟用後將陸續加入 Moovo 站點支援，目前處於實驗階段，可能造成不穩定。';

  @override
  String get check_for_updates => '檢查更新';

  @override
  String get latest_version_installed => '目前已是最新版本。';

  @override
  String get update_check_failed => '檢查更新失敗，請檢查您的網路連線。';

  @override
  String get update_available => '可用更新';

  @override
  String get downloading_update => '正在下載更新...';

  @override
  String get download_completed_install => '下載完成。請點選安裝以完成更新。';

  @override
  String get no_compatible_apk => '找不到相容的 APK。';

  @override
  String get manual_download_github => '你可以從 GitHub 手動下載此版本。';

  @override
  String get release_details_available => '可在 GitHub 查看發行說明。';

  @override
  String get preparing_download => '準備下載...';

  @override
  String get retry => '重試';

  @override
  String get install => '安裝';

  @override
  String get open_github => '開啟 GitHub';

  @override
  String get open_google_play => '開啟 Google Play 商店';

  @override
  String get release_notes => '版本說明';

  @override
  String get download => '下載';

  @override
  String get close => '關閉';

  @override
  String get rerun_setup => '查看歡迎頁面';

  @override
  String get clear_data_button => '清除所有應用程式資料';

  @override
  String get clear_data_confirm_title => '確認刪除';

  @override
  String get clear_data_confirm_content => '此操作將永久刪除所有應用程式資料，包括您的設定。此操作無法復原。';

  @override
  String get data_cleared_success => '應用程式資料已成功清除。';

  @override
  String get app_reset_desc => '此操作將清除所有應用程式資料和設定，將應用程式還原至初始狀態。';

  @override
  String get welcome_title => '歡迎使用 YouBike';

  @override
  String get welcome_message => 'YouBike 站點搜尋幫助您快速找到附近的微笑單車站點，查詢即時車輛數量與步行導航。';

  @override
  String get get_started => '開始使用';
}
