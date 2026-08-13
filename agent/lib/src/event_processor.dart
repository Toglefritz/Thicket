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
    // ignore: avoid_redundant_argument_values
    storageMode: StorageMode.cloud,
    gcpProjectId: gcpProjectId,
  );

  activeStore = await StoreResolver.createFirestoreStore(identity);

  final String prompt = 'Process the following normalized event:\n'
      'Source: $source\n'
      'Event Type: $eventType\n'
      'Project: $thicketProjectId\n'
      'Payload: ${jsonEncode(payload)}\n\n'
      '1. Use the recall tool to check your existing world model for context '
      'relevant to this event. If this is the first event you have processed '
      'for this project, start by defining a schema (see system instructions).\n'
      '2. Analyze the event payload to identify new knowledge, patterns, '
      'constraints, or relationships worth recording.\n'
      '3. Update the world model (remember new items, forget or replace '
      'obsolete ones) using the remember and forget tools.\n'
      '4. Provide a concise summary of what you learned or updated.';

  final GenerateResponseHelper<dynamic> response = await ai.generate(
    // Gemini 3.5 Flash is required for the All Things Agentic Hackathon
    model: googleAI.gemini('gemini-3.5-flash'),
    prompt: prompt,
    system: 'You are Thicket Agent, an autonomous codebase learning assistant. '
        'Your goal is to build, maintain, and query a persistent world model '
        'of the project you are working in.\n\n'
        'You receive normalized events from development tools (GitHub, GitLab, '
        'Slack, file changes, CI pipelines, etc.). Use the Thicket world model '
        'tools (remember, recall, forget) to store, retrieve, and remove '
        'knowledge.\n\n'
        'World Model Schema:\n'
        'You are responsible for defining the schema of the world model '
        'yourself. The schema should be tailored to the project you are '
        'observing. Choose collection names and data structures that best '
        'represent the knowledge domains relevant to this particular project. '
        'The schema should evolve as you learn more about the project.\n\n'
        'When processing the first event for a project, begin by creating a '
        'special record (in a collection of your choosing) that describes your '
        'current schema: the collections you intend to use and what each one '
        'represents. Update this record whenever you add new collections or '
        'change the structure.\n\n'
        'Tool Usage:\n'
        '- remember: provide collection (string) and data (an object with the '
        'entity properties you define).\n'
        '- recall: provide collection (string) to retrieve all records in that '
        'collection.\n'
        '- forget: provide collection (string) and id (string) to remove a '
        'record that is no longer accurate or relevant.',
    toolNames: <String>['remember', 'recall', 'forget'],
    maxTurns: 20,
  );

  return response.text;
}
