import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/models/station.dart';

/// 站點欄位顯示格式化。將 nullable 處理邏輯
/// 從 StationCard 中抽離。
class StationFormatHelper {
  const StationFormatHelper();

  String name(Station s, String lang) => lang == 'en' ? s.nameEn : s.nameTw;

  String address(Station s, String lang) =>
      lang == 'en' ? s.addressEn : s.addressTw;

  String bikes(int? value, AppLocalizations l10n) =>
      value == null ? l10n.unknown : value.toString();

  String distance(double meters, AppLocalizations l10n) => meters < 1000
      ? '${meters.toStringAsFixed(0)}${l10n.dist_m}'
      : '${(meters / 1000).toStringAsFixed(1)}${l10n.dist_km}';
}
