import 'package:genkit/genkit.dart';
import 'package:genkit/plugin.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

import 'tool_handlers.dart';

/// Initializes the Genkit instance with the Google AI plugin and registers all Thicket tools.
///
/// The registered tools allow Gemini to interact with the Thicket world model during event processing. Genkit handles
/// the tool calling loop (including thought signatures) automatically.
Genkit initializeGenkit() {
  final Genkit ai = Genkit(plugins: <GenkitPlugin>[googleAI()]);

  ai.defineTool(
    name: 'remember',
    description: 'Saves or updates a JSON entity in a specified collection in the project world model.',
    fn: (Map<String, dynamic> input, ToolFnArgs<Map<String, dynamic>> context) async {
      return handleRemember(input);
    },
  );

  ai.defineTool(
    name: 'recall',
    description:
        'Retrieves entities from a specified collection in the project world model. Returns all entities if no ID is '
        'specified.',
    fn: (Map<String, dynamic> input, ToolFnArgs<Map<String, dynamic>> context) async {
      return handleRecall(input);
    },
  );

  ai.defineTool(
    name: 'forget',
    description: 'Deletes an entity from a specified collection in the project world model.',
    fn: (Map<String, dynamic> input, ToolFnArgs<Map<String, dynamic>> context) async {
      return handleForget(input);
    },
  );

  ai.defineTool(
    name: 'investigateCodebase',
    description: 'Reads the content of a file in the codebase to understand context.',
    fn: (Map<String, dynamic> input, ToolFnArgs<Map<String, dynamic>> context) async {
      return handleInvestigate(input);
    },
  );

  return ai;
}
