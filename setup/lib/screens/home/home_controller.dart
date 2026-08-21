import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../models/ide_type.dart';
import '../../services/google_auth_service.dart';
import '../../services/hook_installer_service.dart';
import '../../services/mcp_installer_service.dart';
import '../../services/thicket_api_service.dart';
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

  /// Text controller for the project directory path input.
  final TextEditingController projectPathController = TextEditingController();

  /// The registration result returned by the backend.
  RegistrationResult? _registrationResult;

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

  // MARK: Actions

  /// Initiates the Google OAuth2 sign-in flow.
  ///
  /// Opens the system browser to the Google consent page and starts a local HTTP server to receive the redirect. On
  /// success, advances to the project naming step.
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

  /// Registers the project with the Thicket backend and writes the local config.
  ///
  /// Validates that the project name and directory are not empty, sends the registration request, then writes
  /// `.thicket/project.json` in the specified directory.
  Future<void> registerProject() async {
    final String projectName = projectNameController.text.trim();
    if (projectName.isEmpty) {
      setState(() {
        _error = 'Please enter a project name.';
      });
      return;
    }

    final String projectPath = projectPathController.text.trim();
    if (projectPath.isEmpty) {
      setState(() {
        _error = 'Please specify a project directory.';
      });
      return;
    }

    if (!Directory(projectPath).existsSync()) {
      setState(() {
        _error = 'Directory does not exist: $projectPath';
      });
      return;
    }

    // Check if an existing Thicket project is already configured in this directory.
    final File existingConfig = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );
    if (existingConfig.existsSync()) {
      try {
        final String content = existingConfig.readAsStringSync();
        _existingProjectConfig = jsonDecode(content) as Map<String, dynamic>;
        setState(() {
          _error = null;
          _currentStep = SetupStep.joinProject;
        });
        return;
      } catch (_) {
        // If the file is malformed, proceed with new registration.
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

      // Write the local config file to the specified directory.
      _writeProjectConfig(result, projectName, projectPath);

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
      _writeCredentials(result.apiToken, projectPath);

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
  /// First activates the Thicket MCP server package from GitHub using `dart pub global activate`, then writes the MCP
  /// config file in the project directory at the path expected by [ide], and installs hooks that prompt the agent to
  /// recall context on prompt submission and record knowledge after completing a task.
  Future<void> installMcpServer(IdeType ide) async {
    final String projectPath = projectPathController.text.trim();

    setState(() {
      _error = null;
    });

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

  /// Writes `.thicket/project.json` and `.thicket/credentials.json` in the specified project directory.
  ///
  /// The project config contains non-sensitive metadata (project ID, name, agent URL) and is safe to commit. The
  /// credentials file contains the API token and is automatically added to `.gitignore`.
  void _writeProjectConfig(
    RegistrationResult result,
    String projectName,
    String projectPath,
  ) {
    final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));

    if (!thicketDir.existsSync()) {
      thicketDir.createSync(recursive: true);
    }

    // Write the non-sensitive project configuration.
    final Map<String, dynamic> projectConfig = <String, dynamic>{
      'projectId': result.projectId,
      'projectName': projectName,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'storageMode': 'cloud',
      'agentUrl': result.agentUrl,
      'gcpProjectId': result.gcpProjectId ?? 'thicket-505111',
    };

    final File projectFile = File(p.join(thicketDir.path, 'project.json'));
    projectFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(projectConfig),
    );

    // Write credentials and update .gitignore.
    _writeCredentials(result.apiToken, projectPath);
  }

  /// Writes `.thicket/credentials.json` with the given API token and ensures it is gitignored.
  void _writeCredentials(String apiToken, String projectPath) {
    final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));

    if (!thicketDir.existsSync()) {
      thicketDir.createSync(recursive: true);
    }

    final Map<String, dynamic> credentials = <String, dynamic>{
      'apiToken': apiToken,
    };

    final File credentialsFile =
        File(p.join(thicketDir.path, 'credentials.json'));
    credentialsFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(credentials),
    );

    _ensureGitignore(projectPath);
  }

  /// Appends `.thicket/credentials.json` to the project's `.gitignore` if not already present.
  void _ensureGitignore(String projectPath) {
    const String entry = '.thicket/credentials.json';
    final File gitignore = File(p.join(projectPath, '.gitignore'));

    if (gitignore.existsSync()) {
      final String content = gitignore.readAsStringSync();
      if (content.contains(entry)) {
        return;
      }
      // Append with a preceding newline if the file doesn't end with one.
      final String prefix = content.endsWith('\n') ? '' : '\n';
      gitignore.writeAsStringSync('$prefix$entry\n', mode: FileMode.append);
    } else {
      gitignore.writeAsStringSync('$entry\n');
    }
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
