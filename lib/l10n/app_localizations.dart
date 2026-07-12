import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @init_starting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get init_starting;

  /// No description provided for @init_locating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get init_locating;

  /// No description provided for @app_full_title.
  ///
  /// In en, this message translates to:
  /// **'YouBike Site Search : A simple, beautiful site search engine'**
  String get app_full_title;

  /// No description provided for @use_location.
  ///
  /// In en, this message translates to:
  /// **'Use Location'**
  String get use_location;

  /// No description provided for @input_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter station name or address'**
  String get input_placeholder;

  /// No description provided for @countdown_suffix.
  ///
  /// In en, this message translates to:
  /// **' sec update'**
  String get countdown_suffix;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get settings_title;

  /// No description provided for @settings_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic Settings'**
  String get settings_basic;

  /// No description provided for @settings_github.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repositories'**
  String get settings_github;

  /// No description provided for @settings_location.
  ///
  /// In en, this message translates to:
  /// **'Location Service'**
  String get settings_location;

  /// No description provided for @settings_dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_dark_mode;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_language_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language_title;

  /// No description provided for @lang_zh.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get lang_zh;

  /// No description provided for @lang_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get lang_en;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get settings_region;

  /// No description provided for @countdown_unit.
  ///
  /// In en, this message translates to:
  /// **' sec'**
  String get countdown_unit;

  /// No description provided for @countdown_text.
  ///
  /// In en, this message translates to:
  /// **'update'**
  String get countdown_text;

  /// No description provided for @dist_m.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get dist_m;

  /// No description provided for @dist_km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get dist_km;

  /// No description provided for @electric_bike_details_title.
  ///
  /// In en, this message translates to:
  /// **'Electric Bikes - '**
  String get electric_bike_details_title;

  /// No description provided for @bike_number_label.
  ///
  /// In en, this message translates to:
  /// **'Bike No.: '**
  String get bike_number_label;

  /// No description provided for @pillar_number_label.
  ///
  /// In en, this message translates to:
  /// **'Pillar No.: '**
  String get pillar_number_label;

  /// No description provided for @battery_power_label.
  ///
  /// In en, this message translates to:
  /// **'Battery: '**
  String get battery_power_label;

  /// No description provided for @no_electric_bikes.
  ///
  /// In en, this message translates to:
  /// **'No electric bikes available at this station.'**
  String get no_electric_bikes;

  /// No description provided for @failed_to_get_bike_data.
  ///
  /// In en, this message translates to:
  /// **'Failed to get electric bike data.'**
  String get failed_to_get_bike_data;

  /// No description provided for @getting_bike_data.
  ///
  /// In en, this message translates to:
  /// **'Getting electric bike data...'**
  String get getting_bike_data;

  /// No description provided for @region_taipei.
  ///
  /// In en, this message translates to:
  /// **'Taipei City'**
  String get region_taipei;

  /// No description provided for @region_new_taipei.
  ///
  /// In en, this message translates to:
  /// **'New Taipei City'**
  String get region_new_taipei;

  /// No description provided for @region_taoyuan.
  ///
  /// In en, this message translates to:
  /// **'Taoyuan City'**
  String get region_taoyuan;

  /// No description provided for @region_hsinchu_county.
  ///
  /// In en, this message translates to:
  /// **'Hsinchu County'**
  String get region_hsinchu_county;

  /// No description provided for @region_hsinchu_city.
  ///
  /// In en, this message translates to:
  /// **'Hsinchu City'**
  String get region_hsinchu_city;

  /// No description provided for @region_science_park.
  ///
  /// In en, this message translates to:
  /// **'Hsinchu Science Park'**
  String get region_science_park;

  /// No description provided for @region_miaoli.
  ///
  /// In en, this message translates to:
  /// **'Miaoli County'**
  String get region_miaoli;

  /// No description provided for @region_taichung.
  ///
  /// In en, this message translates to:
  /// **'Taichung City'**
  String get region_taichung;

  /// No description provided for @region_chiayi.
  ///
  /// In en, this message translates to:
  /// **'Chiayi City'**
  String get region_chiayi;

  /// No description provided for @region_tainan.
  ///
  /// In en, this message translates to:
  /// **'Tainan City'**
  String get region_tainan;

  /// No description provided for @region_kaohsiung.
  ///
  /// In en, this message translates to:
  /// **'Kaohsiung City'**
  String get region_kaohsiung;

  /// No description provided for @region_pingtung.
  ///
  /// In en, this message translates to:
  /// **'Pingtung County'**
  String get region_pingtung;

  /// No description provided for @region_taitung.
  ///
  /// In en, this message translates to:
  /// **'Taitung County'**
  String get region_taitung;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance: '**
  String get distance;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address: '**
  String get address;

  /// No description provided for @availableBikes.
  ///
  /// In en, this message translates to:
  /// **'YouBike 2.0: '**
  String get availableBikes;

  /// No description provided for @availableElectricBikes.
  ///
  /// In en, this message translates to:
  /// **'YouBike 2.0E: '**
  String get availableElectricBikes;

  /// No description provided for @emptySpaces.
  ///
  /// In en, this message translates to:
  /// **'Empty Slots: '**
  String get emptySpaces;

  /// No description provided for @autoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto Refresh'**
  String get autoRefresh;

  /// No description provided for @param_settings.
  ///
  /// In en, this message translates to:
  /// **'Parameter Settings'**
  String get param_settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @app_reset.
  ///
  /// In en, this message translates to:
  /// **'App Reset'**
  String get app_reset;

  /// No description provided for @init_success.
  ///
  /// In en, this message translates to:
  /// **'Initialization complete'**
  String get init_success;

  /// No description provided for @notice_no_speed.
  ///
  /// In en, this message translates to:
  /// **'❌Do not speed or ride in reverse'**
  String get notice_no_speed;

  /// No description provided for @notice_no_sidewalk.
  ///
  /// In en, this message translates to:
  /// **'❌Do not change lanes arbitrarily on sidewalks'**
  String get notice_no_sidewalk;

  /// No description provided for @notice_no_phone.
  ///
  /// In en, this message translates to:
  /// **'❌Do not use your phone while riding'**
  String get notice_no_phone;

  /// No description provided for @notice_no_brake.
  ///
  /// In en, this message translates to:
  /// **'❌Avoid harsh braking while riding'**
  String get notice_no_brake;

  /// No description provided for @notice_seat_height.
  ///
  /// In en, this message translates to:
  /// **'✔️Remember to adjust the seat to a proper height'**
  String get notice_seat_height;

  /// No description provided for @notice_lights_work.
  ///
  /// In en, this message translates to:
  /// **'✔️Ensure that both front and rear lights are working'**
  String get notice_lights_work;

  /// No description provided for @notice_insurance.
  ///
  /// In en, this message translates to:
  /// **'✔️Remember to get bicycle accident insurance'**
  String get notice_insurance;

  /// No description provided for @notice_take_belongings.
  ///
  /// In en, this message translates to:
  /// **'✔️Take your belongings from the basket'**
  String get notice_take_belongings;

  /// No description provided for @updatingIn.
  ///
  /// In en, this message translates to:
  /// **'{sec} sec update'**
  String updatingIn(String sec);

  /// No description provided for @electricBikeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get electric bike data: {err}'**
  String electricBikeError(String err);

  /// No description provided for @loading_prefix.
  ///
  /// In en, this message translates to:
  /// **'Loading: {progress}%'**
  String loading_prefix(String progress);

  /// No description provided for @init_error.
  ///
  /// In en, this message translates to:
  /// **'Initialization error: {error}'**
  String init_error(String error);

  /// No description provided for @locationTrackingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Location tracking enabled'**
  String get locationTrackingEnabled;

  /// No description provided for @noStationsFound.
  ///
  /// In en, this message translates to:
  /// **'No stations found'**
  String get noStationsFound;

  /// No description provided for @navigationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Navigation unavailable'**
  String get navigationUnavailable;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @sec.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get sec;

  /// No description provided for @go_to.
  ///
  /// In en, this message translates to:
  /// **'Go to '**
  String get go_to;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @init_syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing GPS data...'**
  String get init_syncing;

  /// No description provided for @init_updating.
  ///
  /// In en, this message translates to:
  /// **'Updating stations...'**
  String get init_updating;

  /// No description provided for @update_stations.
  ///
  /// In en, this message translates to:
  /// **'Update Stations'**
  String get update_stations;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
