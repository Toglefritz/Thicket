import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ide_type.dart';
import '../../services/config_generator_service.dart';
// Conditional imports for native-only services.
import '../../services/file_writer_service.dart'
    if (dart.library.html) '../../services/file_writer_service_noop.dart';
import '../../services/google_auth_service.dart';
import '../../services/hook_installer_service.dart'
    if (dart.library.html) '../../services/hook_installer_service_noop.dart';
import '../../services/mcp_installer_service.dart'
    if (dart.library.html) '../../services/mcp_installer_service_noop.dart';
import '../../services/thicket_api_service.dart';
import '../../services/web_download_service_stub.dart'
    if (dart.library.html) '../../services/web_download_service.dart';
import 'home_route.dart';
import 'home_view.dart';

/// The discrete steps the wizard progresses through.
enum SetupStep {
  /// User signs in with their Google account.
  signIn,

  /// User names their project before registration.
  nameProject,

  /// An existing project was detected; user confirms joining it.
  joinProject,

  /// Registration (or join) in progress with the Thicket backend.
  registering,

  /// User selects which IDE to configure with the Thicket MCP server.
  selectIde,

  /// Registration complete; config written to disk.
  complete,
}

/// Controller for the setup wizard screen.
///
/// Orchestrates the project setup flow: sign in with Google, name the project (or join an existing one), register it
/// with the Thicket backend, select an IDE for MCP integration, and install the MCP server configuration.
///
/// On web, file-system operations are skipped and the user is shown copyable configuration JSON instead.
class HomeController extends State<HomeRoute> {
  /// The current wizard step.
  SetupStep _currentStep = SetupStep.signIn;

  /// Error message to display if something goes wrong.
  String? _error;

  /// The OAuth2 access token obtained after sign-in.
  late String? _accessToken;

  /// Whether the sign-in flow is currently in progress.
  bool _isSigningIn = false;

  /// Whether project registration is currently in progress.
  bool _isRegistering = false;

  /// Text controller for the project name input.
  final TextEditingController projectNameController = TextEditingController();

  /// Text controller for the project directory path input (desktop only).
  final TextEditingController projectPathController = TextEditingController();

  /// The registration result returned by the backend.
  RegistrationResult? _registrationResult;

  /// The project name used during registration, stored for display in the web completion step.
  String? _registeredProjectName;

  /// The IDE selected by the user for MCP configuration.
  IdeType? _selectedIde;

  /// The absolute path to the MCP config file that was written, shown on the completion step so the user knows where it
  /// landed.
  String? _mcpConfigPath;

  /// The existing project configuration loaded from `.thicket/project.json` when joining.
  Map<String, dynamic>? _existingProjectConfig;

  // MARK: Getters

  /// The current wizard step.
  SetupStep get currentStep => _currentStep;

  /// Current error message, if any.
  String? get error => _error;

  /// Whether sign-in is currently in progress.
  bool get isSigningIn => _isSigningIn;

  /// Whether registration is currently in progress.
  bool get isRegistering => _isRegistering;

  /// The registration result after successful project creation.
  RegistrationResult? get registrationResult => _registrationResult;

  /// The IDE the user selected for MCP integration, or null if not yet chosen.
  IdeType? get selectedIde => _selectedIde;

  /// The absolute path to the MCP config that was written, or null if the IDE selection step has not completed.
  String? get mcpConfigPath => _mcpConfigPath;

  /// The existing project configuration, available during the join flow.
  Map<String, dynamic>? get existingProjectConfig => _existingProjectConfig;

  /// Whether the app is running in a web browser.
  bool get isRunningOnWeb => kIsWeb;

  // MARK: Actions

  /// Initiates the Google OAuth2 sign-in flow.
  ///
  /// On desktop, opens the system browser to the Google consent page and starts a local HTTP server to receive the
  /// redirect. On web, opens a popup for the implicit grant flow. On success, advances to the project naming step.
  Future<void> signIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });

    try {
      final String token = await GoogleAuthService.signIn();
      _accessToken = token;

      setState(() {
        _isSigningIn = false;
        _currentStep = SetupStep.nameProject;
      });
    } catch (e) {
      setState(() {
        _isSigningIn = false;
        _error = e.toString();
      });
    }
  }

  /// Registers the project with the Thicket backend.
  ///
  /// On desktop, validates that the project name and directory are not empty, sends the registration request, then
  /// writes `.thicket/project.json` in the specified directory.
  ///
  /// On web, only the project name is required. The configuration is shown as copyable JSON on the completion step.
  Future<void> registerProject() async {
    final String projectName = projectNameController.text.trim();
    if (projectName.isEmpty) {
      setState(() {
        _error = 'Please enter a project name.';
      });
      return;
    }

    // On desktop, validate the project path.
    if (!kIsWeb) {
      final String projectPath = projectPathController.text.trim();
      if (projectPath.isEmpty) {
        setState(() {
          _error = 'Please specify a project directory.';
        });
        return;
      }

      if (!FileWriterService.directoryExists(projectPath)) {
        setState(() {
          _error = 'Directory does not exist: $projectPath';
        });
        return;
      }

      // Check if an existing Thicket project is already configured in this directory.
      final Map<String, dynamic>? existing =
          FileWriterService.readExistingConfig(projectPath);
      if (existing != null) {
        _existingProjectConfig = existing;
        setState(() {
          _error = null;
          _currentStep = SetupStep.joinProject;
        });
        return;
      }
    }

    setState(() {
      _isRegistering = true;
      _error = null;
      _currentStep = SetupStep.registering;
    });

    try {
      final ThicketApiService api =
          ThicketApiService(accessToken: _accessToken!);
      final RegistrationResult result =
          await api.registerProject(projectName: projectName);
      _registrationResult = result;
      _registeredProjectName = projectName;

      // On desktop, write the local config files then go to IDE selection.
      // On web, go to IDE selection (files will be shown on completion).
      if (!kIsWeb) {
        final String projectPath = projectPathController.text.trim();
        FileWriterService.writeProjectConfig(
          result: result,
          projectName: projectName,
          projectPath: projectPath,
        );
      }

      setState(() {
        _isRegistering = false;
        _currentStep = SetupStep.selectIde;
      });
    } catch (e) {
      setState(() {
        _isRegistering = false;
        _currentStep = SetupStep.nameProject;
        _error = e.toString();
      });
    }
  }

  /// Joins an existing Thicket project by requesting a new API token from the backend.
  ///
  /// Uses the project ID from the existing `.thicket/project.json` to authenticate with the backend and obtain a fresh
  /// token. Only writes `credentials.json`; the existing `project.json` is left untouched.
  ///
  /// This flow is only available on desktop where the existing config can be detected.
  Future<void> joinExistingProject() async {
    final String projectPath = projectPathController.text.trim();
    final String? projectId = _existingProjectConfig?['projectId'] as String?;

    if (projectId == null || projectId.isEmpty) {
      setState(() {
        _error = 'Invalid project configuration: missing projectId.';
      });
      return;
    }

    setState(() {
      _isRegistering = true;
      _error = null;
      _currentStep = SetupStep.registering;
    });

    try {
      final ThicketApiService api =
          ThicketApiService(accessToken: _accessToken!);
      final RegistrationResult result =
          await api.joinProject(projectId: projectId);
      _registrationResult = result;

      // Only write credentials — project.json already exists.
      if (!kIsWeb) {
        FileWriterService.writeCredentials(
          apiToken: result.apiToken,
          projectPath: projectPath,
        );
      }

      setState(() {
        _isRegistering = false;
        _currentStep = SetupStep.selectIde;
      });
    } catch (e) {
      setState(() {
        _isRegistering = false;
        _currentStep = SetupStep.joinProject;
        _error = e.toString();
      });
    }
  }

  /// Installs the Thicket MCP server configuration and agent hooks for the selected IDE.
  ///
  /// On desktop, activates the Thicket MCP server package from GitHub using `dart pub global activate`, then writes the
  /// MCP config file in the project directory at the path expected by [ide], and installs hooks that prompt the agent to
  /// recall context on prompt submission and record knowledge after completing a task.
  ///
  /// On web, stores the selected IDE and advances to the completion step where all configuration files are displayed for
  /// manual download.
  Future<void> installMcpServer(IdeType ide) async {
    setState(() {
      _error = null;
    });

    if (kIsWeb) {
      setState(() {
        _selectedIde = ide;
        _currentStep = SetupStep.complete;
      });
      return;
    }

    final String projectPath = projectPathController.text.trim();

    try {
      // Activate the Thicket MCP server globally from GitHub.
      await McpInstallerService.activateFromGitHub();

      final String configPath = McpInstallerService.install(
        ide: ide,
        projectPath: projectPath,
      );

      HookInstallerService.install(
        ide: ide,
        projectPath: projectPath,
      );

      setState(() {
        _selectedIde = ide;
        _mcpConfigPath = configPath;
        _error = null;
        _currentStep = SetupStep.complete;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  /// Returns all configuration file entries for display on the web completion step.
  ///
  /// Each entry is a pair of (relative file path, file content). Includes project config, credentials, MCP config, and
  /// agent hooks for the selected IDE.
  List<MapEntry<String, String>> get webConfigEntries {
    final RegistrationResult? result = _registrationResult;
    if (result == null || _selectedIde == null) {
      return <MapEntry<String, String>>[];
    }

    final List<MapEntry<String, String>> entries = <MapEntry<String, String>>[
      MapEntry<String, String>(
        '.thicket/project.json',
        ConfigGeneratorService.projectConfigJson(
          result: result,
          projectName: _registeredProjectName ?? '',
        ),
      ),
      MapEntry<String, String>(
        '.thicket/credentials.json',
        ConfigGeneratorService.credentialsJson(apiToken: result.apiToken),
      ),
      ConfigGeneratorService.mcpConfigEntry(_selectedIde!),
      ...ConfigGeneratorService.hookEntries(_selectedIde!),
    ];

    return entries;
  }

  /// Copies the given text to the system clipboard and shows a snackbar confirmation.
  Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Downloads all configuration files as a ZIP archive (web only).
  void downloadAllConfigs() {
    WebDownloadService.downloadAsZip(entries: webConfigEntries);
  }

  /// Downloads a single configuration file (web only).
  void downloadSingleFile(String fileName, String content) {
    // Use just the filename without directory path for the download.
    final String name = fileName.split('/').last;
    WebDownloadService.downloadFile(fileName: name, content: content);
  }

  /// Resets the wizard back to the initial sign-in step.
  ///
  /// Clears all state accumulated during the flow so the user can start fresh.
  void reset() {
    setState(() {
      _currentStep = SetupStep.signIn;
      _error = null;
      _accessToken = null;
      _isSigningIn = false;
      _isRegistering = false;
      _registrationResult = null;
      _registeredProjectName = null;
      _selectedIde = null;
      _mcpConfigPath = null;
      _existingProjectConfig = null;
      projectNameController.clear();
      projectPathController.clear();
    });
  }

  /// Resets the error state so the user can try the current step again.
  void clearError() {
    setState(() {
      _error = null;
    });
  }

  @override
  void dispose() {
    projectNameController.dispose();
    projectPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
