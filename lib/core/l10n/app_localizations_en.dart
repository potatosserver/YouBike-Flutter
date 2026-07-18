// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get init_starting => 'Starting...';

  @override
  String get init_locating => 'Locating...';

  @override
  String get app_full_title =>
      'YouBike Site Search : A simple, beautiful site search engine';

  @override
  String get use_location => 'Use Location';

  @override
  String get input_placeholder => 'Enter station name or address';

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
  String get settings_language => 'Language';

  @override
  String get settings_language_title => 'Language';

  @override
  String get lang_zh => 'Traditional Chinese';

  @override
  String get lang_en => 'English';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_region => 'Region';

  @override
  String get countdown_unit => ' sec';

  @override
  String get countdown_text => 'update';

  @override
  String get dist_m => 'meters';

  @override
  String get dist_km => 'km';

  @override
  String get electric_bike_details_title => 'Electric Bikes - ';

  @override
  String get bike_number_label => 'Bike No.: ';

  @override
  String get pillar_number_label => 'Pillar No.: ';

  @override
  String get battery_power_label => 'Battery: ';

  @override
  String get no_electric_bikes =>
      'No electric bikes available at this station.';

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
  String get popupAvailableBikesLabel => '2.0';

  @override
  String get popupAvailableElectricBikesLabel => '2.0 E';

  @override
  String get popupEmptySpacesLabel => 'Empty';

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

  @override
  String updatingIn(String sec) {
    return '$sec sec update';
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

  @override
  String get go_to => 'Go to ';

  @override
  String get unknown => 'Unknown';

  @override
  String get init_syncing => 'Syncing GPS data...';

  @override
  String get init_updating => 'Updating stations...';

  @override
  String get update_stations => 'Update Stations';

  @override
  String get init_requesting_permission => 'Requesting location permission...';

  @override
  String get init_verifying_permission => 'Verifying permission status...';

  @override
  String get init_map_engine => 'Starting map engine...';

  @override
  String get init_map_tiles => 'Configuring map tiles...';

  @override
  String get init_clustering => 'Initializing station clusters...';

  @override
  String get stations => 'stations';

  @override
  String init_syncing_stations(int count) {
    return 'Syncing $count stations...';
  }

  @override
  String get permission_location_title => 'Location Permission';

  @override
  String get permission_location_desc =>
      'YouBike needs your location to show nearby stations and distances. We do not track your location in the background.';

  @override
  String get permission_denied_title => 'Permission Permanently Denied';

  @override
  String get permission_denied_content =>
      'You have permanently denied location permission. Please go to your device settings to grant it manually, or use region selection to browse stations.';

  @override
  String get open_settings => 'Open Settings';

  @override
  String get grant_permission => 'Grant Permission';

  @override
  String get skip_permission_label => 'Skip for now';

  @override
  String get skip_permission_confirm => 'Confirm Skip';

  @override
  String get skip_location_title => 'Skip Location Permission';

  @override
  String get skip_location_desc =>
      'If you skip location permission, your selected region center will be used as the default position, and real-time distance cannot be shown. You can enable location anytime in Settings.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get setup_complete => 'Get Started';

  @override
  String get settings_logs => 'View Logs';

  @override
  String get about_youbike => 'About YouBike';

  @override
  String get about_youbike_content =>
      'YouBike Station Search is a clean, beautiful real-time YouBike finder built with Flutter, supporting 13 regions across Taiwan with station search and walking navigation.';

  @override
  String get developer_label => 'Developer: Andrew Cho';

  @override
  String get github_source_code => 'GitHub Source Code';

  @override
  String version_label(String version) {
    return 'Version: $version';
  }

  @override
  String get view_release_notes => 'View Release Notes';

  @override
  String get view_changelog => 'View Changelog';

  @override
  String get check_for_updates => 'Check for Updates';

  @override
  String get latest_version_installed =>
      'You are already using the latest version.';

  @override
  String get update_check_failed =>
      'Failed to check for updates. Please check your network connection.';

  @override
  String get update_available => 'Update Available';

  @override
  String get downloading_update => 'Downloading update...';

  @override
  String get download_completed_install =>
      'Download completed. Tap Install to finish the update.';

  @override
  String get no_compatible_apk =>
      'No compatible APK could be found for this device.';

  @override
  String get manual_download_github =>
      'You can download the release manually from GitHub.';

  @override
  String get release_details_available =>
      'Release details are available on GitHub.';

  @override
  String get preparing_download => 'Preparing download...';

  @override
  String get retry => 'Retry';

  @override
  String get install => 'Install';

  @override
  String get open_github => 'Open GitHub';

  @override
  String get open_google_play => 'Open Google Play';

  @override
  String get release_notes => 'Release Notes';

  @override
  String get download => 'Download';

  @override
  String get close => 'Close';

  @override
  String get rerun_setup => 'View Welcome Page';

  @override
  String get clear_data_button => 'Clear All App Data';

  @override
  String get clear_data_confirm_title => 'Confirm Deletion';

  @override
  String get clear_data_confirm_content =>
      'This will permanently delete all app data, including your settings. This action cannot be undone.';

  @override
  String get data_cleared_success => 'App data has been successfully cleared.';

  @override
  String get app_reset_desc =>
      'This will clear all app data and settings, restoring the app to its initial state.';

  @override
  String get clear_logs_confirm_title => 'Confirm Clear Logs';

  @override
  String get clear_logs_confirm_content =>
      'Are you sure you want to clear all app logs? This action cannot be undone.';

  @override
  String get logs_cleared => 'Logs cleared.';

  @override
  String get no_logs => 'No logs yet.';

  @override
  String get clear_all_logs => 'Clear All Logs';

  @override
  String get welcome_title => 'Welcome to YouBike';

  @override
  String get welcome_message =>
      'YouBike Station Search helps you quickly find nearby YouBike stations, check real-time bike availability, and get walking directions.';

  @override
  String get get_started => 'Get Started';
}
