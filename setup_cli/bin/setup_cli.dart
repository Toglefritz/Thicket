/// Thicket Setup CLI
///
/// Command-line interface for registering projects with the Thicket platform. Guides the user through a four-step
/// wizard:
///
/// 1. **Sign in** — Opens the browser for Google OAuth2 and receives the access token.
/// 2. **Configure** — Collects the project name and directory, registers with the backend.
/// 3. **Select IDE** — Asks which agentic IDE the user works with.
/// 4. **Install** — Activates the MCP server globally and writes config + hook files.
///
/// Usage:
/// ```bash
/// dart run bin/setup_cli.dart
/// ```
///
/// Or compile to a native binary:
/// ```bash
/// dart compile exe bin/setup_cli.dart -o thicket-setup
/// ./thicket-setup
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:setup_cli/src/api.dart' as api;
import 'package:setup_cli/src/auth.dart' as auth;
import 'package:setup_cli/src/console.dart' as console;
import 'package:setup_cli/src/file_writer.dart' as file_writer;
import 'package:setup_cli/src/hook_installer.dart' as hooks;
import 'package:setup_cli/src/ide_type.dart';
import 'package:setup_cli/src/mcp_installer.dart' as mcp;

/// Entry point for the Thicket setup CLI wizard.
///
/// Runs the four-step interactive flow: sign-in, project configuration, IDE selection, and MCP/hook installation. Exits
/// with code 1 if any critical step fails.
Future<void> main(List<String> args) async {
  console.printBanner();

  // ─── Step 1: Sign in ─────────────────────────────────────────────────────
  final String accessToken = await _stepSignIn();

  stdout.writeln();
  console.printDivider();
  stdout.writeln();

  // ─── Step 2: Configure project ───────────────────────────────────────────
  final _ProjectResult projectResult = await _stepConfigureProject(accessToken);

  stdout.writeln();
  console.printDivider();
  stdout.writeln();

  // ─── Step 3: Select IDE ──────────────────────────────────────────────────
  final IdeType selectedIde = _stepSelectIde();

  stdout.writeln();
  console.printDivider();
  stdout.writeln();

  // ─── Step 4: Install MCP server and hooks ────────────────────────────────
  await _stepInstall(selectedIde, projectResult.projectPath);

  stdout.writeln();
  console.printDivider();
  stdout.writeln();

  // ─── Summary ─────────────────────────────────────────────────────────────
  _printSummary(projectResult.result, selectedIde);
}

/// Executes Step 1: Google OAuth2 sign-in.
///
/// Prints the step header, opens the browser for authentication, and returns the access token on success. Exits the
/// process with code 1 if sign-in fails.
Future<String> _stepSignIn() async {
  console.printStep(1, 4, 'Sign in with Google');
  console.printInfo('Opening your browser for authentication...');
  stdout.writeln();

  try {
    final String accessToken = await auth.signIn();
    console.printSuccess('Signed in successfully.');
    return accessToken;
  } catch (e) {
    console.printError('Sign-in failed: $e');
    exit(1);
  }
}

/// Executes Step 2: Project configuration and registration.
///
/// Prompts for the project directory (defaulting to the current working directory). If an existing `.thicket/
/// project.json` is found, offers the user the option to join. Otherwise, prompts for a project name and registers a
/// new project with the Thicket backend.
///
/// Returns a [_ProjectResult] containing the API response and the confirmed project path. Exits with code 1 on failure.
Future<_ProjectResult> _stepConfigureProject(String accessToken) async {
  console.printStep(2, 4, 'Configure your project');
  stdout.writeln();

  final String projectPath = console.prompt(
    'Project directory',
    defaultValue: Directory.current.path,
  );
  if (projectPath.isEmpty || !Directory(projectPath).existsSync()) {
    console.printError('Directory does not exist: $projectPath');
    exit(1);
  }

  // Check for an existing Thicket project in the directory.
  final File existingConfig = File(
    p.join(projectPath, '.thicket', 'project.json'),
  );

  late final Map<String, dynamic> result;

  if (existingConfig.existsSync()) {
    result = await _handleExistingProject(
      accessToken,
      projectPath,
      existingConfig,
    );
  } else {
    result = await _handleNewProject(accessToken, projectPath);
  }

  return _ProjectResult(result: result, projectPath: projectPath);
}

/// Handles the case where an existing `.thicket/project.json` is found.
///
/// Displays the existing project details and prompts the user to either join the project (obtaining fresh credentials)
/// or start a new registration from scratch.
///
/// Returns the API response map. Exits with code 1 on failure.
Future<Map<String, dynamic>> _handleExistingProject(
  String accessToken,
  String projectPath,
  File existingConfig,
) async {
  stdout.writeln();
  console.printWarning('Existing Thicket project found in this directory.');

  try {
    final Map<String, dynamic> existing = jsonDecode(existingConfig.readAsStringSync()) as Map<String, dynamic>;
    console.printInfo(
      'Project: ${existing['projectName']} (${existing['projectId']})',
    );
    stdout.writeln();

    final String join = console.prompt(
      'Join this project? (y/n)',
      defaultValue: 'y',
    );

    if (join.toLowerCase() == 'y') {
      stdout.writeln();
      console.printInfo('Joining project...');
      final Map<String, dynamic> result = await api.joinProject(
        accessToken,
        existing['projectId'] as String,
      );
      file_writer.writeCredentials(result['apiToken'] as String, projectPath);
      console.printSuccess('Joined project. Credentials written.');
      return result;
    } else {
      return await _handleNewProject(accessToken, projectPath);
    }
  } catch (e) {
    console.printError('Failed: $e');
    exit(1);
  }
}

/// Handles registration of a brand-new project.
///
/// Prompts for a project name, calls the Thicket backend to register, and writes the project config and credentials
/// files to the `.thicket/` directory.
///
/// Returns the API response map. Exits with code 1 on failure.
Future<Map<String, dynamic>> _handleNewProject(
  String accessToken,
  String projectPath,
) async {
  console.printInfo('Starting fresh registration...');
  final String projectName = console.prompt('Project name');
  if (projectName.isEmpty) {
    console.printError('Project name cannot be empty.');
    exit(1);
  }

  stdout.writeln();
  console.printInfo('Registering project with Thicket...');

  try {
    final Map<String, dynamic> result = await api.registerProject(
      accessToken,
      projectName,
    );
    file_writer.writeProjectConfig(result, projectName, projectPath);
    console.printSuccess('Project registered.');
    console.printSuccess('Configuration written to .thicket/');
    return result;
  } catch (e) {
    console.printError('Registration failed: $e');
    exit(1);
  }
}

/// Executes Step 3: IDE selection.
///
/// Presents a numbered list of supported IDEs and prompts the user to select one. Returns the chosen [IdeType]. Exits
/// with code 1 if the selection is invalid.
IdeType _stepSelectIde() {
  console.printStep(3, 4, 'Select your IDE');
  stdout.writeln();

  final int ideChoice = console.promptChoice(
    'Which IDE will you use with Thicket?',
    IdeType.values.map((IdeType ide) => ide.displayName).toList(),
  );

  if (ideChoice == 0) {
    console.printError('Invalid selection.');
    exit(1);
  }

  return IdeType.values[ideChoice - 1];
}

/// Executes Step 4: MCP server activation and hook installation.
///
/// Attempts to globally activate the Thicket MCP server package from GitHub, then writes the MCP config file and agent
/// hooks for the selected IDE. If activation fails (e.g., no network), prints a warning with manual instructions but
/// continues with config/hook installation.
Future<void> _stepInstall(IdeType ide, String projectPath) async {
  console.printStep(4, 4, 'Install Thicket MCP server');
  stdout.writeln();
  console.printInfo('Activating Thicket MCP server from GitHub...');

  try {
    await mcp.activateMcpServer();
    console.printSuccess('MCP server package activated globally.');
  } catch (e) {
    console.printWarning('Could not activate MCP server: $e');
    console.printInfo('You can activate it manually later with:');
    console.printInfo(
      '  dart pub global activate --source git '
      'https://github.com/Toglefritz/Thicket.git --git-path interface',
    );
    stdout.writeln();
  }

  console.printInfo('Writing MCP configuration for ${ide.displayName}...');
  mcp.installMcpConfig(ide, projectPath);
  console.printSuccess('MCP config written to ${ide.configRelativePath}');

  console.printInfo('Installing agent hooks...');
  hooks.installHooks(ide, projectPath);
  console.printSuccess('Agent hooks installed.');
}

/// Prints the final summary box showing project details and configuration paths.
///
/// Displays the project ID, agent URL, selected IDE, and MCP config path in a bordered box format with cyan highlights.
void _printSummary(Map<String, dynamic> result, IdeType ide) {
  stdout.writeln(
    '${console.green}${console.bold}  Setup complete.${console.reset}',
  );
  stdout.writeln();
  stdout.writeln(
    '  ${console.dim}+-----------------------------------------+${console.reset}',
  );
  stdout.writeln(
    '  ${console.dim}|${console.reset}  Project ID   '
    '${console.cyan}${result['projectId']}${console.reset}',
  );
  stdout.writeln(
    '  ${console.dim}|${console.reset}  Agent URL    '
    '${console.cyan}${result['agentUrl'] ?? api.defaultBaseUrl}${console.reset}',
  );
  stdout.writeln(
    '  ${console.dim}|${console.reset}  IDE          '
    '${console.cyan}${ide.displayName}${console.reset}',
  );
  stdout.writeln(
    '  ${console.dim}|${console.reset}  MCP config   '
    '${console.cyan}${ide.configRelativePath}${console.reset}',
  );
  stdout.writeln(
    '  ${console.dim}+-----------------------------------------+${console.reset}',
  );
  stdout.writeln();
  stdout.writeln(
    '  ${console.dim}Your AI agent will now accumulate knowledge',
  );
  stdout.writeln('  as it works in this project.${console.reset}');
  stdout.writeln();
}

/// Internal result type bundling the API response with the confirmed project path.
///
/// Used to pass both pieces of information from [_stepConfigureProject] back to the main flow without using a tuple or
/// positional record.
class _ProjectResult {
  /// Creates a project result.
  const _ProjectResult({
    required this.result,
    required this.projectPath,
  });

  /// The decoded JSON response from the Thicket backend (register or join).
  final Map<String, dynamic> result;

  /// The absolute path to the user's project directory.
  final String projectPath;
}
