import 'package:genkit/genkit.dart';
import 'package:genkit/plugin.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:thicket/thicket.dart';

import 'tool_handlers.dart';

/// The currently active Firestore store for the in-flight request.
///
/// This is set before each `ai.generate` call and read by the tool handlers. Genkit tools are registered at startup
/// and cannot accept per-request parameters directly, so this shared variable bridges that gap. This is safe because
/// Cloud Run processes one request at a time per instance by default.
FirestoreEntityStore? activeStore;

/// Initializes the Genkit instance with the Google AI plugin and registers all Thicket tools.
///
/// The registered tools allow Gemini to interact with the Thicket world model during event processing. Genkit handles
/// the tool calling loop (including thought signatures) automatically.
Genkit initializeGenkit() {
  final Genkit ai = Genkit(plugins: <GenkitPlugin>[googleAI()]);

  ai.defineTool(
    name: 'remember',
    description:
        'Saves or updates a JSON entity in a specified collection in the project world model. '
        'Required fields: collection (string), data (object with the entity properties). '
        'Optional: id (string, if updating an existing entity).',
    fn: (Map<String, dynamic> input,
        ToolFnArgs<Map<String, dynamic>> context) async {
      return handleRemember(input, activeStore!);
    },
  );

  ai.defineTool(
    name: 'recall',
    description:
        'Retrieves entities from a specified collection in the project world model. '
        'Required fields: collection (string). Optional: id (string, to retrieve a specific entity). '
        'If no id is given, returns all entities in the collection.',
    fn: (Map<String, dynamic> input,
        ToolFnArgs<Map<String, dynamic>> context) async {
      return handleRecall(input, activeStore!);
    },
  );

  ai.defineTool(
    name: 'forget',
    description:
        'Deletes an entity from a specified collection in the project world model. '
        'Required fields: collection (string), id (string).',
    fn: (Map<String, dynamic> input,
        ToolFnArgs<Map<String, dynamic>> context) async {
      return handleForget(input, activeStore!);
    },
  );

  ai.defineTool(
    name: 'investigateCodebase',
    description:
        'Reads the content of a file in the codebase to understand context. '
        'Required fields: projectPath (string), relativePath (string). '
        'Note: this only works when the agent has local filesystem access.',
    fn: (Map<String, dynamic> input,
        ToolFnArgs<Map<String, dynamic>> context) async {
      return handleInvestigate(input);
    },
  );

  return ai;
}
