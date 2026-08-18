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

  /// Registration in progress with the Thicket backend.
  registering,

  /// User selects which IDE to configure with the Thicket MCP server.
  selectIde,

  /// Registration complete; config written to disk.
  complete,
}

/// Controller for the setup wizard screen.
///
/// Orchestrates the project setup flow: sign in with Google, name the project, register it with the Thicket backend,
/// select an IDE for MCP integration, and install the MCP server configuration. On completion, both
/// `.thicket/project.json` and the IDE's MCP config are written to disk.
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

  /// Installs the Thicket MCP server configuration and agent hooks for the selected IDE.
  ///
  /// Writes the MCP config file in the project directory at the path expected by [ide], then installs hooks that prompt
  /// the agent to recall context on prompt submission and record knowledge after completing a task. Uses the Thicket
  /// repo location (derived from this app's own executable path) to construct the server launch command.
  void installMcpServer(IdeType ide) {
    final String projectPath = projectPathController.text.trim();

    // Resolve the Thicket repository root. The setup app lives at <thicket>/setup, so we go one level up from the setup
    // package directory. Platform.script points to the running Dart file within the setup package.
    final String thicketRoot =
        p.dirname(p.dirname(Platform.script.toFilePath()));

    try {
      final String configPath = McpInstallerService.install(
        ide: ide,
        projectPath: projectPath,
        thicketRootPath: thicketRoot,
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

  /// Writes `.thicket/project.json` in the specified project directory.
  void _writeProjectConfig(
      RegistrationResult result, String projectName, String projectPath) {
    final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));

    if (!thicketDir.existsSync()) {
      thicketDir.createSync(recursive: true);
    }

    final Map<String, dynamic> config = <String, dynamic>{
      'projectId': result.projectId,
      'projectName': projectName,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'storageMode': 'cloud',
      'agentUrl': result.agentUrl,
      'apiToken': result.apiToken,
    };

    final File configFile = File(p.join(thicketDir.path, 'project.json'));
    configFile
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(config));
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
