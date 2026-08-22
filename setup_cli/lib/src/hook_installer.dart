/// Agent Hook Installer
///
/// Installs agent hooks that prompt the IDE's AI agent to interact with the Thicket world model at two key points:
///
/// 1. **Before responding** (recall): The agent searches for relevant prior knowledge before starting work.
/// 2. **After completing a task** (record): The agent reflects on what it learned and stores durable knowledge.
///
/// Each IDE has its own hook format. Antigravity uses shell scripts referenced from `.agents/hooks.json`, while Kiro
/// uses individual JSON files in `.kiro/hooks/`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ide_type.dart';

/// The prompt injected when the user submits a message, reminding the agent to recall relevant context.
///
/// Instructs the agent to search the Thicket world model for lessons, patterns, architectural decisions, or constraints
/// that previous sessions discovered. If nothing relevant is found, the agent proceeds normally.
const String _recallPrompt = 'Before responding, search the Thicket world model for knowledge relevant '
    'to this request. Use the search tool from the Thicket MCP server with '
    'the current workspace path as the projectPath argument.\n\n'
    'Look for lessons, patterns, architectural decisions, or constraints that '
    'previous sessions discovered about this codebase. When you find something '
    'relevant, briefly mention what you found and how it informs your approach.\n\n'
    'If the search returns no results or the tool is unavailable, proceed '
    'normally without mentioning Thicket to the user.';

/// The prompt injected after a task completes, reminding the agent to record what it learned.
///
/// Instructs the agent to reflect on whether it discovered something genuinely reusable (architecture insights,
/// rationale, constraints, conventions) and if so, store it using the Thicket MCP server's remember tool. Explicitly
/// discourages recording trivial or obvious information.
const String _recordPrompt = 'You just completed a task. Reflect on whether you discovered something '
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

/// Installs agent hooks for [ide] in the target [projectPath].
///
/// Delegates to the appropriate IDE-specific installer based on the selected IDE type. Both formats achieve the same
/// goal (injecting recall and record prompts at the right moments) but use different file structures and formats.
void installHooks(IdeType ide, String projectPath) {
  switch (ide) {
    case IdeType.antigravity:
      _installAntigravityHooks(projectPath);
    case IdeType.kiro:
      _installKiroHooks(projectPath);
  }
}

/// Writes hooks in Antigravity's `.agents/` format.
///
/// Antigravity hooks are shell scripts that output JSON on stdout. For prompt injection, the `PreInvocation` event
/// outputs `injectSteps` with an `ephemeralMessage`. The scripts are written to `.agents/scripts/` and referenced from
/// `.agents/hooks.json`.
///
/// Creates three files:
/// - `.agents/scripts/thicket_recall.sh` — outputs the recall prompt as an ephemeral message.
/// - `.agents/scripts/thicket_record.sh` — outputs the record prompt as an ephemeral message.
/// - `.agents/hooks.json` — registers both scripts with PreInvocation and PostInvocation triggers.
void _installAntigravityHooks(String projectPath) {
  final Directory scriptsDir = Directory(
    p.join(projectPath, '.agents', 'scripts'),
  );
  if (!scriptsDir.existsSync()) {
    scriptsDir.createSync(recursive: true);
  }

  // Write the recall script.
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

  // Write the record script.
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

  // Write or merge hooks.json.
  final File hooksFile = File(p.join(projectPath, '.agents', 'hooks.json'));
  Map<String, dynamic> hooks;
  if (hooksFile.existsSync()) {
    final String existing = hooksFile.readAsStringSync();
    hooks = existing.trim().isNotEmpty ? jsonDecode(existing) as Map<String, dynamic> : <String, dynamic>{};
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
///
/// Creates two files:
/// - `.kiro/hooks/thicket-recall.json` — triggered on `UserPromptSubmit`, injects the recall prompt.
/// - `.kiro/hooks/thicket-record.json` — triggered on `Stop`, injects the record prompt.
void _installKiroHooks(String projectPath) {
  final Directory hooksDir = Directory(
    p.join(projectPath, '.kiro', 'hooks'),
  );
  if (!hooksDir.existsSync()) {
    hooksDir.createSync(recursive: true);
  }

  // Recall hook — fires when the user submits a prompt.
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

  // Record hook — fires after a task completes.
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

  File(p.join(hooksDir.path, 'thicket-recall.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(recallHook),
  );
  File(p.join(hooksDir.path, 'thicket-record.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(recordHook),
  );
}
