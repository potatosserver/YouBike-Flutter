import 'package:youbike_android/core/l10n/app_localizations.dart';
import 'package:youbike_android/data/models/station.dart';

/// Formats Station fields for display. Keeps nullable-handling logic
/// out of StationCard widget.
class StationFormatHelper {
  const StationFormatHelper();

  String name(Station s, String lang) =>
      lang == 'en' ? s.nameEn : s.nameTw;

  String address(Station s, String lang) =>
      lang == 'en' ? s.addressEn : s.addressTw;

  String bikes(int? value, AppLocalizations l10n) =>
      value == null ? l10n.unknown : value.toString();

  String distance(double meters, AppLocalizations l10n) =>
      meters < 1000
          ? '${meters.toStringAsFixed(0)}${l10n.dist_m}'
          : '${(meters / 1000).toStringAsFixed(1)}${l10n.dist_km}';
}