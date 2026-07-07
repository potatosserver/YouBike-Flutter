// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'YouBike Station Search';

  @override
  String get app_full_title => 'YouBike Site Search : A simple, beautiful site search engine';

  @override
  String get use_location => 'Use Location';

  @override
  String get input_placeholder => 'Please enter station name or address';

  @override
  String get countdown_suffix => ' sec update';

  @override
  String get settings_title => 'System Settings';

  @override
  String get settings_basic => 'Basic Settings';

  @override
  String get settings_github => 'GitHub Repositories';

  @override
  String get settings_location => 'Location Service';

  @override
  String get settings_dark_mode => 'Dark Mode';

  @override
  String get settings_language => 'Chinese/English';

  @override
  String get settings_language_title => 'Language Settings';

  @override
  String get settings_theme => 'Theme Mode';

  @override
  String get settings_debug => 'System Debug Logs';

  @override
  String get log_copied => 'Logs copied to clipboard';

  @override
  String get settings_region => 'Region';

  @override
  String get electric_bike_details_title => 'Electric Bikes - ';

  @override
  String get bike_number_label => 'Bike No.: ';

  @override
  String get pillar_number_label => 'Pillar No.: ';

  @override
  String get battery_power_label => 'Battery: ';

  @override
  String get no_electric_bikes => 'No electric bikes available at this station.';

  @override
  String get failed_to_get_bike_data => 'Failed to get electric bike data.';

  @override
  String get getting_bike_data => 'Getting electric bike data...';

  @override
  String get region_taipei => 'Taipei City';

  @override
  String get region_new_taipei => 'New Taipei City';

  @override
  String get region_taoyuan => 'Taoyuan City';

  @override
  String get region_hsinchu_county => 'Hsinchu County';

  @override
  String get region_hsinchu_city => 'Hsinchu City';

  @override
  String get region_science_park => 'Hsinchu Science Park';

  @override
  String get region_miaoli => 'Miaoli County';

  @override
  String get region_taichung => 'Taichung City';

  @override
  String get region_chiayi => 'Chiayi City';

  @override
  String get region_tainan => 'Tainan City';

  @override
  String get region_kaohsiung => 'Kaohsiung City';

  @override
  String get region_pingtung => 'Pingtung County';

  @override
  String get region_taitung => 'Taitung County';

  @override
  String get routeNotFound => 'Route not found';

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
  String get autoRefresh => 'Auto Refresh';

  @override
  String get param_settings => 'Parameter Settings';

  @override
  String get about => 'About';

  @override
  String get app_reset => 'App Reset';

  @override
  String get init_success => 'Initialization complete';

  @override
  String get notice_no_speed => '❌Do not speed or ride in reverse';

  @override
  String get notice_no_sidewalk => '❌Do not change lanes arbitrarily on sidewalks';

  @override
  String get notice_no_phone => '❌Do not use your phone while riding';

  @override
  String get notice_no_brake => '❌Avoid harsh braking while riding';

  @override
  String get notice_seat_height => '✔️Remember to adjust the seat to a proper height';

  @override
  String get notice_lights_work => '✔️Ensure that both front and rear lights are working';

  @override
  String get notice_insurance => '✔️Remember to get bicycle accident insurance';

  @override
  String get notice_take_belongings => '✔️Take your belongings from the basket';

  @override
  String updatingIn(String sec) {
    return 'Updating in $sec seconds';
  }

  @override
  String electricBikeError(String err) {
    return 'Failed to get electric bike data: $err';
  }

  @override
  String loading_prefix(String progress) {
    return 'Loading: $progress%';
  }

  @override
  String init_error(String error) {
    return 'Initialization error: $error';
  }

  @override
  String get locationTrackingEnabled => 'Location tracking enabled';

  @override
  String get noStationsFound => 'No stations found';

  @override
  String get navigationUnavailable => 'Navigation unavailable';

  @override
  String get updating => 'Updating...';

  @override
  String get sec => 'seconds';
}
