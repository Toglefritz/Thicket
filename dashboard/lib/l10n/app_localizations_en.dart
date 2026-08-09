// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dashboard';

  @override
  String get auditLogSubtitle =>
      'Real-time history of events dispatched and cognitive agent actions.';

  @override
  String get buttonAddEntity => 'ADD ENTITY';

  @override
  String get buttonCancel => 'CANCEL';

  @override
  String get buttonDelete => 'DELETE';

  @override
  String get buttonDispatchWebhook => 'DISPATCH SIMULATED WEBHOOK';

  @override
  String get buttonRefreshDb => 'REFRESH DB';

  @override
  String get buttonSave => 'SAVE';

  @override
  String get buttonUpdate => 'UPDATE';

  @override
  String confirmDeleteEntity(String id) {
    return 'Are you sure you want to permanently delete entity \"$id\"?';
  }

  @override
  String get consoleTitle => 'Thicket Console';

  @override
  String entityCreatedAt(String timestamp) {
    return 'Created: $timestamp';
  }

  @override
  String entityModifiedAt(String timestamp) {
    return 'Modified: $timestamp';
  }

  @override
  String entityUpdatedAtTime(String time) {
    return 'Updated $time';
  }

  @override
  String get errorIdCannotBeEmpty => 'ID cannot be empty';

  @override
  String errorInvalidJson(String error) {
    return 'Invalid JSON: $error';
  }

  @override
  String errorInvalidJsonPayload(String error) {
    return 'Invalid JSON Payload: $error';
  }

  @override
  String get hintEntityId => 'e.g. exp_a2b3';

  @override
  String get labelAgentReasoning => 'AGENT REASONING & RESPONSE LOGS';

  @override
  String get labelAgentRuntime => 'AGENT RUNTIME';

  @override
  String get labelCollection => 'COLLECTION';

  @override
  String get labelEntities => 'ENTITIES';

  @override
  String get labelEntityId => 'ENTITY ID (Short generator)';

  @override
  String get labelEventTemplate => 'EVENT TEMPLATE';

  @override
  String get labelJsonPayload => 'JSON PAYLOAD';

  @override
  String get labelProjectPath => 'PROJECT PATH';

  @override
  String get labelProperties => 'PROPERTIES (JSON Map)';

  @override
  String get labelRawData => 'RAW DATA DATA OBJECT';

  @override
  String get labelRawPayloadResponse => 'RAW PAYLOAD RESPONSE';

  @override
  String get lampOff => 'OFF';

  @override
  String get lampOn => 'ON';

  @override
  String get menuAuditLogStream => 'Audit Log Stream';

  @override
  String get menuWebhookSimulator => 'Webhook Simulator';

  @override
  String get menuWorldModelExplorer => 'World Model Explorer';

  @override
  String get noCollectionsNotice =>
      'No collections detected in the world model database storage mode.';

  @override
  String get noEntitiesNotice => 'No entities in collection.';

  @override
  String get noLogsNotice =>
      'No logged operations. Try triggering a webhook event to start.';

  @override
  String get noWebhookSentNotice =>
      'No webhook sent yet in this session. Trigger an event on the left.';

  @override
  String projectPathNotice(String path) {
    return 'Ensure your project path is correct and initialized at $path';
  }

  @override
  String get selectEntityNotice =>
      'Select an entity to inspect detail properties.';

  @override
  String get statusOffline => 'OFFLINE';

  @override
  String get statusOnline => 'ONLINE';

  @override
  String get templateFilesystemChange => 'Local Filesystem Change';

  @override
  String get templateGithubPush => 'GitHub Git Push Event';

  @override
  String get templateSlackQuery => 'Slack Channel Query';

  @override
  String get titleAddEntity => 'Add World Model Entity';

  @override
  String get titleDeleteEntity => 'Delete Entity';

  @override
  String titleEditEntity(String id) {
    return 'Edit Entity $id';
  }

  @override
  String get tooltipDeleteEntity => 'Delete entity';

  @override
  String get tooltipEditProperties => 'Edit properties';

  @override
  String get unknownViewState => 'Unknown View State';

  @override
  String get webSimulationNotice =>
      'Running on Web: Database file read/write is simulated in-memory.';

  @override
  String get webhookSimulatorSubtitle =>
      'Manually dispatch structured repository events to test the cognitive loop.';

  @override
  String get webhookSuccessTitle => 'WEBHOOK SUCCESS';

  @override
  String get worldModelExplorerSubtitle =>
      'Browse collections and inspect, edit, or delete dynamic world model entities.';
}
