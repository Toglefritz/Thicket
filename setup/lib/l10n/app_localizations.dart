import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Thicket Setup'**
  String get appTitle;

  /// Main heading on the sign-in step
  ///
  /// In en, this message translates to:
  /// **'Set up Thicket'**
  String get welcomeHeading;

  /// Description text on the sign-in step
  ///
  /// In en, this message translates to:
  /// **'Thicket gives your AI agents a persistent world model. Sign in with your Google account to register a project.'**
  String get welcomeDescription;

  /// Label for the Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get buttonSignIn;

  /// Status text shown while waiting for the OAuth redirect
  ///
  /// In en, this message translates to:
  /// **'Waiting for sign-in...'**
  String get signInWaiting;

  /// Heading on the project naming step
  ///
  /// In en, this message translates to:
  /// **'Name your project'**
  String get nameProjectHeading;

  /// Description on the project naming step
  ///
  /// In en, this message translates to:
  /// **'Give your project a name and specify the directory where it lives.'**
  String get nameProjectDescription;

  /// Label for the project name text field
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get labelProjectName;

  /// Label for the project directory path text field
  ///
  /// In en, this message translates to:
  /// **'Project directory'**
  String get labelProjectPath;

  /// Label for the button that registers the project
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get buttonRegister;

  /// Status text shown while registration is in progress
  ///
  /// In en, this message translates to:
  /// **'Creating your project...'**
  String get registeringStatus;

  /// Heading shown when setup is complete
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get completeHeading;

  /// Description shown when setup is complete, after both registration and MCP installation
  ///
  /// In en, this message translates to:
  /// **'Your project is registered and your IDE is configured. Thicket is ready to use.'**
  String get completeDescription;

  /// Label for the project ID in the summary
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get labelProjectId;

  /// Label for the agent endpoint URL in the summary
  ///
  /// In en, this message translates to:
  /// **'Agent URL'**
  String get labelAgentUrl;

  /// Label for the API token in the summary
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get labelApiToken;

  /// Label for the done button on the completion step
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get buttonDone;

  /// Generic error message display
  ///
  /// In en, this message translates to:
  /// **'{error}'**
  String errorGeneric(String error);

  /// Heading on the IDE selection step
  ///
  /// In en, this message translates to:
  /// **'Choose your IDE'**
  String get selectIdeHeading;

  /// Description on the IDE selection step explaining why an IDE must be chosen
  ///
  /// In en, this message translates to:
  /// **'Select the IDE you use so Thicket can install its MCP server configuration.'**
  String get selectIdeDescription;

  /// Label for the IDE name in the completion summary
  ///
  /// In en, this message translates to:
  /// **'IDE'**
  String get labelIde;

  /// Label for the MCP configuration file path in the completion summary
  ///
  /// In en, this message translates to:
  /// **'MCP config'**
  String get labelMcpConfig;

  /// Heading shown when an existing Thicket project is detected in the directory
  ///
  /// In en, this message translates to:
  /// **'Existing project found'**
  String get joinProjectHeading;

  /// Description explaining the join flow when a project.json already exists
  ///
  /// In en, this message translates to:
  /// **'This directory already has a Thicket project configured. Join it to get your own API credentials.'**
  String get joinProjectDescription;

  /// Label for the button that joins an existing project
  ///
  /// In en, this message translates to:
  /// **'Join project'**
  String get buttonJoinProject;

  /// Label for the button that resets the wizard to create a new project instead
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get buttonStartOver;

  /// Status text shown while the join request is in progress
  ///
  /// In en, this message translates to:
  /// **'Joining project...'**
  String get joiningStatus;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
