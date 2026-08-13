import 'dart:convert';
import 'dart:io';

import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:thicket/thicket.dart';

import 'genkit_setup.dart';
import 'store_resolver.dart';

/// Processes a webhook event using Genkit with Gemini and the registered tools.
///
/// The [thicketProjectId] identifies which project's world model to read from and write to. This value comes from
/// the webhook payload (sent by the client, which reads it from its local `.thicket/project.json`). The GCP project ID
/// comes from the server's environment since all projects share a single Firestore instance.
Future<String> processEvent({
  required Genkit ai,
  required String source,
  required String eventType,
  required String thicketProjectId,
  required Map<String, dynamic> payload,
}) async {
  final String gcpProjectId = Platform.environment['GCP_PROJECT_ID'] ?? '';
  if (gcpProjectId.isEmpty) {
    throw StateError(
        'GCP_PROJECT_ID environment variable must be set on the server.');
  }

  final ProjectIdentity identity = ProjectIdentity(
    projectId: thicketProjectId,
    projectName: thicketProjectId,
    createdAt: DateTime.utc(1970),
    storageMode: StorageMode.cloud,
    gcpProjectId: gcpProjectId,
  );

  activeStore = await StoreResolver.createFirestoreStore(identity);

  final String prompt = 'Process the following normalized event:\n'
      'Source: $source\n'
      'Event Type: $eventType\n'
      'Project: $thicketProjectId\n'
      'Payload: ${jsonEncode(payload)}\n\n'
      "1. Recall existing beliefs or experiences in the 'beliefs' and 'experiences' "
      'collections related to this event.\n'
      '2. Analyze the event payload to identify new learnings, rules, or constraints.\n'
      '3. Update the world model (remember new items, or forget/update obsolete ones) '
      'using the remember/forget tools.\n'
      '4. Provide a concise summary of what you learned or updated in the world model.';

  final GenerateResponseHelper<dynamic> response = await ai.generate(
    // Gemini 3.5 Flash is required for the All Things Agentic Hackathon
    model: googleAI.gemini('gemini-3.5-flash'),
    prompt: prompt,
    system: 'You are Thicket Agent, an autonomous codebase learning assistant. '
        'Your goal is to build, maintain, and query a persistent world model '
        'of the codebase/project you are working in.\n\n'
        'You receive normalized events from development tools (GitHub, GitLab, '
        'Slack, file changes). Use the Thicket world model tools (remember, '
        'recall, forget) to retrieve context, decide what is worth learning or '
        'updating, and update the world model accordingly.\n\n'
        'When using the remember tool, provide: collection (string like "beliefs", '
        '"experiences", "concepts"), and data (an object with the entity properties). '
        'When using recall, provide: collection (string). When using forget, provide: '
        'collection (string) and id (string).',
    toolNames: <String>['remember', 'recall', 'forget'],
    maxTurns: 20,
  );

  return response.text;
}
