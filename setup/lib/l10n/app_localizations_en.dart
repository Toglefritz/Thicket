// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Thicket Setup';

  @override
  String get welcomeHeading => 'Set up Thicket';

  @override
  String get welcomeDescription =>
      'Thicket gives your AI agents a persistent world model. Sign in with your Google account to register a project.';

  @override
  String get buttonSignIn => 'Sign in with Google';

  @override
  String get signInWaiting => 'Waiting for sign-in...';

  @override
  String get nameProjectHeading => 'Name your project';

  @override
  String get nameProjectDescription =>
      'Give your project a name so you can identify it later.';

  @override
  String get labelProjectName => 'Project name';

  @override
  String get buttonRegister => 'Create project';

  @override
  String get registeringStatus => 'Creating your project...';

  @override
  String get completeHeading => 'You\'re all set';

  @override
  String get completeDescription =>
      'Your project is registered. The configuration has been saved to .thicket/project.json.';

  @override
  String get labelProjectId => 'Project ID';

  @override
  String get labelAgentUrl => 'Agent URL';

  @override
  String get labelApiToken => 'API Token';

  @override
  String get buttonDone => 'Done';

  @override
  String errorGeneric(String error) {
    return '$error';
  }
}
