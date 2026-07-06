// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchPlaceholder => 'Search station name or address...';

  @override
  String updatingIn(Object sec) {
    return 'Updating in $sec seconds';
  }

  @override
  String get routeNotFound => 'Route not found';

  @override
  String electricBikeError(Object err) {
    return 'Failed to get electric bike data: $err';
  }

  @override
  String get noElectricBikes => 'No electric bikes available at this station';

  @override
  String get bikeNumber => 'Bike No: ';

  @override
  String get pillarNumber => 'Pillar No: ';

  @override
  String get ok => 'OK';

  @override
  String get distance => 'Distance: ';

  @override
  String get address => 'Address: ';

  @override
  String get availableBikes => 'YouBike 2.0: ';

  @override
  String get availableElectricBikes => 'YouBike 2.0E: ';

  @override
  String get emptySpaces => 'Empty Slots: ';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get autoRefresh => 'Auto Refresh';

  @override
  String get loading => 'Loading YouBike data...';

  @override
  String get param_settings => 'Parameter Settings';

  @override
  String get about => 'About';

  @override
  String get app_reset => 'App Reset';

  @override
  String loading_prefix(Object progress) {
    return 'Loading: $progress%';
  }

  @override
  String get init_success => 'Initialization complete';

  @override
  String init_error(Object error) {
    return 'Initialization error: $error';
  }

  @override
  String get notice_no_speed => '❌Do not speed or ride in reverse';

  @override
  String get notice_no_sidewalk =>
      '❌Do not change lanes arbitrarily on sidewalks';

  @override
  String get notice_no_phone => '❌Do not use your phone while riding';

  @override
  String get notice_no_brake => '❌Avoid harsh braking while riding';

  @override
  String get notice_seat_height =>
      '✔️Remember to adjust the seat to a proper height';

  @override
  String get notice_lights_work =>
      '✔️Ensure that both front and rear lights are working';

  @override
  String get notice_insurance => '✔️Remember to get bicycle accident insurance';

  @override
  String get notice_take_belongings => '✔️Take your belongings from the basket';
}
