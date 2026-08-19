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
      'Before responding, search the Thicket world model for knowledge relevant '
      'to this request. Use the search tool from the Thicket MCP server with '
      'the current workspace path as the projectPath argument.\n\n'
      'Look for lessons, patterns, architectural decisions, or constraints that '
      'previous sessions discovered about this codebase. When you find something '
      'relevant, briefly mention what you found and how it informs your approach.';

  /// The prompt injected after a task completes, reminding the agent to record what it learned.
  static const String _recordPrompt =
      'You just completed a task. Reflect on whether you discovered something '
      'that would help a future agent (or yourself) work more effectively in '
      'this codebase. The goal is to form **durable knowledge**, not to log '
      'what you did.\n\n'
      'Good knowledge entries answer questions like:\n'
      '- "How does [X system] actually work?" (architecture insights)\n'
      '- "Why is [Y] done this way?" (rationale behind decisions)\n'
      '- "What should you watch out for when changing [Z]?" (constraints, gotchas)\n'
      '- "What pattern does this codebase follow for [W]?" (conventions)\n\n'
      'Do NOT record:\n'
      '- Simple task completions ("I added a button to the screen")\n'
      '- Mechanical changes that are obvious from reading the code\n'
      '- Information that is already captured in code comments or docs\n\n'
      'If you did learn something genuinely reusable, use the remember tool '
      'from the Thicket MCP server. Store it in an appropriate collection '
      '(e.g., "architecture", "conventions", "decisions", "gotchas"). Write '
      'the summary as a concise lesson, not a narrative of what you did. Use '
      'the current workspace path as the projectPath argument.\n\n'
      'If nothing worth preserving was learned, that is fine — do not force it.';

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
  /// Antigravity hooks are shell commands that receive JSON on stdin and output JSON on stdout. For prompt injection,
  /// the `PreInvocation` event outputs `injectSteps` with an `ephemeralMessage`. The scripts are written to
  /// `.agents/scripts/` and referenced from `.agents/hooks.json`.
  static void _installAntigravityHooks(String projectPath) {
    final Directory agentsDir = Directory(p.join(projectPath, '.agents'));
    if (!agentsDir.existsSync()) {
      agentsDir.createSync(recursive: true);
    }

    final Directory scriptsDir = Directory(
      p.join(agentsDir.path, 'scripts'),
    );
    if (!scriptsDir.existsSync()) {
      scriptsDir.createSync(recursive: true);
    }

    // Write the recall script (injects a prompt before the model runs).
    final File recallScript = File(
      p.join(scriptsDir.path, 'thicket_recall.sh'),
    );
    recallScript.writeAsStringSync(
      '#!/bin/sh\n'
      "cat <<'EOF'\n"
      '${jsonEncode(<String, dynamic>{
            'injectSteps': <Map<String, dynamic>>[
              <String, dynamic>{'ephemeralMessage': _recallPrompt},
            ],
          })}\n'
      'EOF\n',
    );
    Process.runSync('chmod', <String>['+x', recallScript.path]);

    // Write the record script (injects a prompt after tool calls finish).
    final File recordScript = File(
      p.join(scriptsDir.path, 'thicket_record.sh'),
    );
    recordScript.writeAsStringSync(
      '#!/bin/sh\n'
      "cat <<'EOF'\n"
      '${jsonEncode(<String, dynamic>{
            'injectSteps': <Map<String, dynamic>>[
              <String, dynamic>{'ephemeralMessage': _recordPrompt},
            ],
          })}\n'
      'EOF\n',
    );
    Process.runSync('chmod', <String>['+x', recordScript.path]);

    // Write the hooks.json configuration.
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
          'type': 'command',
          'command': './scripts/thicket_recall.sh',
        },
      ],
    };

    hooks['thicket-record'] = <String, dynamic>{
      'PostInvocation': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'command',
          'command': './scripts/thicket_record.sh',
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
    final Directory hooksDir = Directory(p.join(projectPath, '.kiro', 'hooks'));
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

    final File recallFile = File(p.join(hooksDir.path, 'thicket-recall.json'));
    recallFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(recallHook),
    );

    final File recordFile = File(p.join(hooksDir.path, 'thicket-record.json'));
    recordFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(recordHook),
    );
  }
}
