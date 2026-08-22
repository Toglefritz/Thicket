import 'dart:convert';

import '../models/ide_type.dart';
import 'thicket_api_service.dart';

/// Generates configuration file contents for display on web without writing to the file system.
///
/// On web, the setup wizard cannot write files directly to the user's machine. Instead, this service produces the JSON
/// content that the user should manually place in their project. The output matches exactly what the desktop version
/// writes via the file writer, MCP installer, and hook installer services.
class ConfigGeneratorService {
  const ConfigGeneratorService._();

  /// Generates the content for `.thicket/project.json`.
  static String projectConfigJson({
    required RegistrationResult result,
    required String projectName,
  }) {
    final Map<String, dynamic> config = <String, dynamic>{
      'projectId': result.projectId,
      'projectName': projectName,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'storageMode': 'cloud',
      'agentUrl': result.agentUrl,
      'gcpProjectId': result.gcpProjectId ?? 'thicket-505111',
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  /// Generates the content for `.thicket/credentials.json`.
  static String credentialsJson({required String apiToken}) {
    final Map<String, dynamic> credentials = <String, dynamic>{
      'apiToken': apiToken,
    };

    return const JsonEncoder.withIndent('  ').convert(credentials);
  }

  /// Generates the MCP server configuration content for the given [ide].
  ///
  /// Returns a map with the relative file path as key and JSON content as value.
  static MapEntry<String, String> mcpConfigEntry(IdeType ide) {
    final Map<String, dynamic> thicketServer = <String, dynamic>{
      'command': 'dart',
      'args': <String>[
        'pub',
        'global',
        'run',
        'thicket_interface:thicket',
      ],
    };

    final Map<String, dynamic> config = <String, dynamic>{
      'mcpServers': <String, dynamic>{
        'thicket': thicketServer,
      },
    };

    return MapEntry<String, String>(
      ide.configRelativePath,
      const JsonEncoder.withIndent('  ').convert(config),
    );
  }

  /// Generates the agent hook file contents for the given [ide].
  ///
  /// Returns a list of map entries where the key is the relative file path and the value is the file content.
  static List<MapEntry<String, String>> hookEntries(IdeType ide) {
    switch (ide) {
      case IdeType.antigravity:
        return _antigravityHookEntries();
      case IdeType.kiro:
        return _kiroHookEntries();
    }
  }

  static List<MapEntry<String, String>> _antigravityHookEntries() {
    // Recall script
    final String recallScriptContent = '#!/bin/sh\n'
        "cat <<'EOF'\n"
        '${jsonEncode(<String, dynamic>{
          'injectSteps': <Map<String, dynamic>>[
            <String, dynamic>{'ephemeralMessage': _recallPrompt},
          ],
        })}\n'
        'EOF\n';

    // Record script
    final String recordScriptContent = '#!/bin/sh\n'
        "cat <<'EOF'\n"
        '${jsonEncode(<String, dynamic>{
          'injectSteps': <Map<String, dynamic>>[
            <String, dynamic>{'ephemeralMessage': _recordPrompt},
          ],
        })}\n'
        'EOF\n';

    // hooks.json
    final Map<String, dynamic> hooks = <String, dynamic>{
      'thicket-recall': <String, dynamic>{
        'PreInvocation': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'command',
            'command': './scripts/thicket_recall.sh',
          },
        ],
      },
      'thicket-record': <String, dynamic>{
        'PostInvocation': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'command',
            'command': './scripts/thicket_record.sh',
          },
        ],
      },
    };

    return <MapEntry<String, String>>[
      MapEntry<String, String>(
        '.agents/hooks.json',
        const JsonEncoder.withIndent('  ').convert(hooks),
      ),
      MapEntry<String, String>(
        '.agents/scripts/thicket_recall.sh',
        recallScriptContent,
      ),
      MapEntry<String, String>(
        '.agents/scripts/thicket_record.sh',
        recordScriptContent,
      ),
    ];
  }

  static List<MapEntry<String, String>> _kiroHookEntries() {
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

    return <MapEntry<String, String>>[
      MapEntry<String, String>(
        '.kiro/hooks/thicket-recall.json',
        const JsonEncoder.withIndent('  ').convert(recallHook),
      ),
      MapEntry<String, String>(
        '.kiro/hooks/thicket-record.json',
        const JsonEncoder.withIndent('  ').convert(recordHook),
      ),
    ];
  }

  /// The prompt injected when the user submits a message, reminding the agent to recall relevant context.
  static const String _recallPrompt =
      'Before responding, search the Thicket world model for knowledge relevant '
      'to this request. Use the search tool from the Thicket MCP server with '
      'the current workspace path as the projectPath argument.\n\n'
      'Look for lessons, patterns, architectural decisions, or constraints that '
      'previous sessions discovered about this codebase. When you find something '
      'relevant, briefly mention what you found and how it informs your approach.\n\n'
      'If the search returns no results or the tool is unavailable, proceed '
      'normally without mentioning Thicket to the user.';

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
}
