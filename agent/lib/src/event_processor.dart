import 'dart:convert';

import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

/// Processes a webhook event using Genkit with Gemini and the registered tools.
///
/// Constructs a prompt from the event metadata and payload, then invokes Gemini with access to the world model tools.
/// Genkit orchestrates the multi-turn tool calling loop internally and returns the model's final summary of what it
/// learned or updated.
Future<String> processEvent({
  required Genkit ai,
  required String source,
  required String eventType,
  required String projectPath,
  required Map<String, dynamic> payload,
}) async {
  final String prompt = 'Process the following normalized event:\n'
      'Source: $source\n'
      'Event Type: $eventType\n'
      'Project Path: $projectPath\n'
      'Payload: ${jsonEncode(payload)}\n\n'
      "1. Recall existing beliefs or experiences in the 'beliefs' and 'experiences' "
      'collections related to this event.\n'
      '2. Analyze the event payload to identify new learnings, rules, or constraints.\n'
      '3. Investigate the codebase using investigateCodebase if you need to read file contents.\n'
      '4. Update the world model (remember new items, or forget/update obsolete ones) '
      'using the remember/forget tools.\n'
      '5. Provide a concise summary of what you learned or updated in the world model.';

  final GenerateResponseHelper<dynamic> response = await ai.generate(
    model: googleAI.gemini('gemini-2.5-flash'),
    prompt: prompt,
    system: 'You are Thicket Agent, an autonomous codebase learning assistant. '
        'Your goal is to build, maintain, and query a persistent world model '
        'of the codebase/project you are working in.\n\n'
        'You receive normalized events from development tools (GitHub, GitLab, '
        'Slack, file changes). Use the Thicket world model tools (remember, '
        'recall, forget) and investigateCodebase tool to retrieve context, '
        'read files if necessary, decide what is worth learning or updating, '
        'and update the world model accordingly.',
    toolNames: <String>['remember', 'recall', 'forget', 'investigateCodebase'],
  );

  return response.text;
}
