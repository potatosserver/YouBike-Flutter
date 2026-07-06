// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get searchPlaceholder => '搜尋站點名稱或地址...';

  @override
  String updatingIn(Object sec) {
    return '即時資料將在 $sec 秒後更新';
  }

  @override
  String get routeNotFound => '找不到前往該站點的路徑';

  @override
  String electricBikeError(Object err) {
    return '取得電輔車資料失敗: $err';
  }

  @override
  String get noElectricBikes => '目前該站點沒有可用電輔車';

  @override
  String get bikeNumber => '車號: ';

  @override
  String get pillarNumber => '車位: ';

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
  String get settings => '設定';

  @override
  String get darkMode => '深色模式';

  @override
  String get language => '語言選擇';

  @override
  String get autoRefresh => '自動刷新';

  @override
  String get loading => '正在載入 YouBike 資料...';

  @override
  String get param_settings => '參數設定';

  @override
  String get about => '關於';

  @override
  String get app_reset => '重設 App';

  @override
  String loading_prefix(Object progress) {
    return '載入中：$progress%';
  }

  @override
  String get init_success => '初始化完成';

  @override
  String init_error(Object error) {
    return '初始化過程出錯: $error';
  }

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
}
