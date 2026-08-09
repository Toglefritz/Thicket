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
  /// **'Dashboard'**
  String get appTitle;

  /// Subtitle text for the Audit Log Stream page
  ///
  /// In en, this message translates to:
  /// **'Real-time history of events dispatched and cognitive agent actions.'**
  String get auditLogSubtitle;

  /// Label for the button that opens the add entity dialog
  ///
  /// In en, this message translates to:
  /// **'ADD ENTITY'**
  String get buttonAddEntity;

  /// Label for the cancel button in dialogs
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get buttonCancel;

  /// Label for the delete button in the confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get buttonDelete;

  /// Text inside the button used to send mock webhooks to the agent
  ///
  /// In en, this message translates to:
  /// **'DISPATCH SIMULATED WEBHOOK'**
  String get buttonDispatchWebhook;

  /// Label for the button that refreshes the world model database
  ///
  /// In en, this message translates to:
  /// **'REFRESH DB'**
  String get buttonRefreshDb;

  /// Label for the save button in the add entity dialog
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get buttonSave;

  /// Label for the update button in the edit entity dialog
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get buttonUpdate;

  /// Confirmation message shown before deleting an entity
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete entity \"{id}\"?'**
  String confirmDeleteEntity(String id);

  /// The title displayed in the sidebar header
  ///
  /// In en, this message translates to:
  /// **'Thicket Console'**
  String get consoleTitle;

  /// Label showing the creation timestamp of an entity
  ///
  /// In en, this message translates to:
  /// **'Created: {timestamp}'**
  String entityCreatedAt(String timestamp);

  /// Label showing the last modification timestamp of an entity
  ///
  /// In en, this message translates to:
  /// **'Modified: {timestamp}'**
  String entityModifiedAt(String timestamp);

  /// Short timestamp shown in the entity list tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String entityUpdatedAtTime(String time);

  /// Validation error shown in the add entity dialog when the ID field is left blank
  ///
  /// In en, this message translates to:
  /// **'ID cannot be empty'**
  String get errorIdCannotBeEmpty;

  /// Error message shown in entity dialogs when the JSON input is malformed
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON: {error}'**
  String errorInvalidJson(String error);

  /// Snackbar error message shown when the webhook payload cannot be parsed as JSON
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON Payload: {error}'**
  String errorInvalidJsonPayload(String error);

  /// Hint text inside the entity ID input field
  ///
  /// In en, this message translates to:
  /// **'e.g. exp_a2b3'**
  String get hintEntityId;

  /// Label for the panel displaying agent reasoning outputs
  ///
  /// In en, this message translates to:
  /// **'AGENT REASONING & RESPONSE LOGS'**
  String get labelAgentReasoning;

  /// Label for the agent runtime connection status in the sidebar
  ///
  /// In en, this message translates to:
  /// **'AGENT RUNTIME'**
  String get labelAgentRuntime;

  /// Label for the collection dropdown selector
  ///
  /// In en, this message translates to:
  /// **'COLLECTION'**
  String get labelCollection;

  /// Label for the list of entities under a collection
  ///
  /// In en, this message translates to:
  /// **'ENTITIES'**
  String get labelEntities;

  /// Label for the entity ID input field in the dialog
  ///
  /// In en, this message translates to:
  /// **'ENTITY ID (Short generator)'**
  String get labelEntityId;

  /// Label for the event template dropdown selector
  ///
  /// In en, this message translates to:
  /// **'EVENT TEMPLATE'**
  String get labelEventTemplate;

  /// Label for the JSON payload editor text field
  ///
  /// In en, this message translates to:
  /// **'JSON PAYLOAD'**
  String get labelJsonPayload;

  /// Label for the project path input field in the sidebar
  ///
  /// In en, this message translates to:
  /// **'PROJECT PATH'**
  String get labelProjectPath;

  /// Label for the entity data properties input field in the dialog
  ///
  /// In en, this message translates to:
  /// **'PROPERTIES (JSON Map)'**
  String get labelProperties;

  /// Header for the raw entity JSON view
  ///
  /// In en, this message translates to:
  /// **'RAW DATA DATA OBJECT'**
  String get labelRawData;

  /// Label for the raw response JSON code block
  ///
  /// In en, this message translates to:
  /// **'RAW PAYLOAD RESPONSE'**
  String get labelRawPayloadResponse;

  /// Label for the lamp switch when it is in the off position
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get lampOff;

  /// Label for the lamp switch when it is in the on position
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get lampOn;

  /// Label for the Audit Log Stream tab in the sidebar menu
  ///
  /// In en, this message translates to:
  /// **'Audit Log Stream'**
  String get menuAuditLogStream;

  /// Label for the Webhook Simulator tab in the sidebar menu
  ///
  /// In en, this message translates to:
  /// **'Webhook Simulator'**
  String get menuWebhookSimulator;

  /// Label for the World Model Explorer tab in the sidebar menu
  ///
  /// In en, this message translates to:
  /// **'World Model Explorer'**
  String get menuWorldModelExplorer;

  /// Message shown when no database collections are found
  ///
  /// In en, this message translates to:
  /// **'No collections detected in the world model database storage mode.'**
  String get noCollectionsNotice;

  /// Message shown when the selected collection is empty
  ///
  /// In en, this message translates to:
  /// **'No entities in collection.'**
  String get noEntitiesNotice;

  /// Placeholder message shown when there are no audit logs yet
  ///
  /// In en, this message translates to:
  /// **'No logged operations. Try triggering a webhook event to start.'**
  String get noLogsNotice;

  /// Placeholder text shown when no webhook has been dispatched yet
  ///
  /// In en, this message translates to:
  /// **'No webhook sent yet in this session. Trigger an event on the left.'**
  String get noWebhookSentNotice;

  /// Message prompting user to check their project path
  ///
  /// In en, this message translates to:
  /// **'Ensure your project path is correct and initialized at {path}'**
  String projectPathNotice(String path);

  /// Placeholder message shown when no entity has been selected yet
  ///
  /// In en, this message translates to:
  /// **'Select an entity to inspect detail properties.'**
  String get selectEntityNotice;

  /// Status text shown when the agent server is offline
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get statusOffline;

  /// Status text shown when the agent server is online
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get statusOnline;

  /// Display label for the filesystem modification event template in the webhook simulator dropdown
  ///
  /// In en, this message translates to:
  /// **'Local Filesystem Change'**
  String get templateFilesystemChange;

  /// Display label for the GitHub push event template in the webhook simulator dropdown
  ///
  /// In en, this message translates to:
  /// **'GitHub Git Push Event'**
  String get templateGithubPush;

  /// Display label for the Slack message event template in the webhook simulator dropdown
  ///
  /// In en, this message translates to:
  /// **'Slack Channel Query'**
  String get templateSlackQuery;

  /// Title of the dialog used to add a new entity
  ///
  /// In en, this message translates to:
  /// **'Add World Model Entity'**
  String get titleAddEntity;

  /// Title of the delete entity confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Entity'**
  String get titleDeleteEntity;

  /// Title of the dialog used to edit an existing entity
  ///
  /// In en, this message translates to:
  /// **'Edit Entity {id}'**
  String titleEditEntity(String id);

  /// Tooltip for the delete button on an entity detail card
  ///
  /// In en, this message translates to:
  /// **'Delete entity'**
  String get tooltipDeleteEntity;

  /// Tooltip for the edit button on an entity detail card
  ///
  /// In en, this message translates to:
  /// **'Edit properties'**
  String get tooltipEditProperties;

  /// Fallback text shown when the active tab does not match any known view
  ///
  /// In en, this message translates to:
  /// **'Unknown View State'**
  String get unknownViewState;

  /// Information message shown at the bottom of the sidebar when running on Web platform
  ///
  /// In en, this message translates to:
  /// **'Running on Web: Database file read/write is simulated in-memory.'**
  String get webSimulationNotice;

  /// Subtitle text for the Webhook Simulator page
  ///
  /// In en, this message translates to:
  /// **'Manually dispatch structured repository events to test the cognitive loop.'**
  String get webhookSimulatorSubtitle;

  /// Title shown on a successful webhook dispatch response card
  ///
  /// In en, this message translates to:
  /// **'WEBHOOK SUCCESS'**
  String get webhookSuccessTitle;

  /// Subtitle text for the World Model Explorer page
  ///
  /// In en, this message translates to:
  /// **'Browse collections and inspect, edit, or delete dynamic world model entities.'**
  String get worldModelExplorerSubtitle;
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
    'that was used.',
  );
}
