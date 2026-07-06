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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search station name or address...'**
  String get searchPlaceholder;

  /// No description provided for @updatingIn.
  ///
  /// In en, this message translates to:
  /// **'Updating in {sec} seconds'**
  String updatingIn(Object sec);

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @electricBikeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get electric bike data: {err}'**
  String electricBikeError(Object err);

  /// No description provided for @noElectricBikes.
  ///
  /// In en, this message translates to:
  /// **'No electric bikes available at this station'**
  String get noElectricBikes;

  /// No description provided for @bikeNumber.
  ///
  /// In en, this message translates to:
  /// **'Bike No: '**
  String get bikeNumber;

  /// No description provided for @pillarNumber.
  ///
  /// In en, this message translates to:
  /// **'Pillar No: '**
  String get pillarNumber;

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

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @autoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto Refresh'**
  String get autoRefresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading YouBike data...'**
  String get loading;

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

  /// No description provided for @loading_prefix.
  ///
  /// In en, this message translates to:
  /// **'Loading: {progress}%'**
  String loading_prefix(Object progress);

  /// No description provided for @init_success.
  ///
  /// In en, this message translates to:
  /// **'Initialization complete'**
  String get init_success;

  /// No description provided for @init_error.
  ///
  /// In en, this message translates to:
  /// **'Initialization error: {error}'**
  String init_error(Object error);

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
