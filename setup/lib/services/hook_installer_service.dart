import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/ide_type.dart';

/// Installs agent hooks that prompt the IDE's AI agent to record relevant information into the Thicket world model.
///
/// Each IDE has its own hook configuration format and file location. This service writes the appropriate files for the
/// selected IDE so that the agent is reminded to use the Thicket MCP tools at two points:
///
/// 1. After the user submits a prompt (opportunity to recall context from the world model).
/// 2. After completing a task (opportunity to record new knowledge into the world model).
///
/// The hook content is intentionally generic. It does not prescribe specific collection names or schema; the agent
/// decides what is worth recording based on the work it just performed.
class HookInstallerService {
  const HookInstallerService._();

  /// The prompt injected when the user submits a message, reminding the agent to recall relevant context.
  static const String _recallPrompt =
      'Before responding, consider whether the Thicket world model contains '
      'context relevant to this request. If so, use the recall tool from the '
      'Thicket MCP server to retrieve it. Use the project path of the current '
      'workspace as the projectPath argument.';

  /// The prompt injected after a task completes, reminding the agent to record what it learned.
  static const String _recordPrompt =
      'You have just completed a task. Consider whether anything you learned, '
      'decided, or observed during this task is worth recording in the Thicket '
      'world model for future reference. This could include architectural '
      'decisions, patterns discovered, constraints encountered, or other '
      'project knowledge. If so, use the remember tool from the Thicket MCP '
      'server to store it. Use the project path of the current workspace as '
      'the projectPath argument.';

  /// Installs hooks for [ide] in the target [projectPath].
  ///
  /// The hook format depends on the IDE. This method delegates to the appropriate IDE-specific writer.
  static void install({
    required IdeType ide,
    required String projectPath,
  }) {
    switch (ide) {
      case IdeType.antigravity:
        _installAntigravityHooks(projectPath);
      case IdeType.kiro:
        _installKiroHooks(projectPath);
    }
  }

  /// Writes hooks in Antigravity's `.agents/` format.
  ///
  /// Antigravity uses a single `hooks.json` file at `.agents/hooks.json` with trigger-keyed entries. Each trigger maps
  /// to a list of actions. The `agent` type injects a prompt into the conversation context.
  static void _installAntigravityHooks(String projectPath) {
    final Directory agentsDir = Directory(p.join(projectPath, '.agents'));
    if (!agentsDir.existsSync()) {
      agentsDir.createSync(recursive: true);
    }

    final File hooksFile = File(p.join(agentsDir.path, 'hooks.json'));

    // Merge with existing hooks if the file already exists.
    Map<String, dynamic> hooks;
    if (hooksFile.existsSync()) {
      final String existing = hooksFile.readAsStringSync();
      hooks = existing.trim().isNotEmpty
          ? jsonDecode(existing) as Map<String, dynamic>
          : <String, dynamic>{};
    } else {
      hooks = <String, dynamic>{};
    }

    hooks['thicket-recall'] = <String, dynamic>{
      'PreInvocation': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'agent',
          'message': _recallPrompt,
        },
      ],
    };

    hooks['thicket-record'] = <String, dynamic>{
      'Stop': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'agent',
          'message': _recordPrompt,
        },
      ],
    };

    hooksFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(hooks),
    );
  }

  /// Writes hooks in Kiro's `.kiro/hooks/<id>.json` format.
  ///
  /// Kiro stores each hook as a separate JSON file. The `agent` action type injects a static prompt into the model
  /// context when the trigger fires.
  static void _installKiroHooks(String projectPath) {
    final Directory hooksDir =
        Directory(p.join(projectPath, '.kiro', 'hooks'));
    if (!hooksDir.existsSync()) {
      hooksDir.createSync(recursive: true);
    }

    // Hook that fires when the user submits a prompt.
    final Map<String, dynamic> recallHook = <String, dynamic>{
      'version': 'v1',
      'hooks': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Thicket Recall',
          'trigger': 'UserPromptSubmit',
          'action': <String, dynamic>{
            'type': 'agent',
            'prompt': _recallPrompt,
          },
        },
      ],
    };

    // Hook that fires after a task completes.
    final Map<String, dynamic> recordHook = <String, dynamic>{
      'version': 'v1',
      'hooks': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Thicket Record',
          'trigger': 'Stop',
          'action': <String, dynamic>{
            'type': 'agent',
            'prompt': _recordPrompt,
          },
        },
      ],
    };

    final File recallFile =
        File(p.join(hooksDir.path, 'thicket-recall.json'));
    recallFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(recallHook),
    );

    final File recordFile =
        File(p.join(hooksDir.path, 'thicket-record.json'));
    recordFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(recordHook),
    );
  }
}
