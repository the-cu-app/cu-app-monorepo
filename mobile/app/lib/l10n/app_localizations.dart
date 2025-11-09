import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'CU.APP'**
  String get appTitle;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Services screen title
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// Transactions screen title
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Transfer screen title
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Accounts section title
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// Pinned accounts section title
  ///
  /// In en, this message translates to:
  /// **'Pinned Accounts'**
  String get pinnedAccounts;

  /// All accounts section title
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get allAccounts;

  /// Account balance label
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Current balance label
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// Available balance label
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableBalance;

  /// Primary account indicator
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get primary;

  /// Checking account type
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// Savings account type
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// Credit card account type
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// Mortgage account type
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get mortgage;

  /// Personal loan account type
  ///
  /// In en, this message translates to:
  /// **'Personal Loan'**
  String get personalLoan;

  /// Money market account type
  ///
  /// In en, this message translates to:
  /// **'Money Market'**
  String get moneyMarket;

  /// Brokerage account type
  ///
  /// In en, this message translates to:
  /// **'Brokerage'**
  String get brokerage;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Scan QR code button
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// Find ATM button
  ///
  /// In en, this message translates to:
  /// **'Find ATM'**
  String get findAtm;

  /// Appointments button
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// Help button
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Card management service
  ///
  /// In en, this message translates to:
  /// **'Card Management'**
  String get cardManagement;

  /// Connect accounts service
  ///
  /// In en, this message translates to:
  /// **'Connect Accounts'**
  String get connectAccounts;

  /// Spending analytics service
  ///
  /// In en, this message translates to:
  /// **'Spending Analytics'**
  String get spendingAnalytics;

  /// Net worth service
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get netWorth;

  /// Transfer money service
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get transferMoney;

  /// Pay bills service
  ///
  /// In en, this message translates to:
  /// **'Pay Bills'**
  String get payBills;

  /// Deposit check service
  ///
  /// In en, this message translates to:
  /// **'Deposit Check'**
  String get depositCheck;

  /// Apply for loan service
  ///
  /// In en, this message translates to:
  /// **'Apply for Loan'**
  String get applyForLoan;

  /// Open account service
  ///
  /// In en, this message translates to:
  /// **'Open Account'**
  String get openAccount;

  /// Customer support service
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get customerSupport;

  /// Recent transactions section
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// Game zone section
  ///
  /// In en, this message translates to:
  /// **'CU.APP Game Zone'**
  String get gameZone;

  /// Chat GPT section
  ///
  /// In en, this message translates to:
  /// **'CU.APPGPT'**
  String get chatGpt;

  /// Build strategy section
  ///
  /// In en, this message translates to:
  /// **'Build Strategy'**
  String get buildStrategy;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
