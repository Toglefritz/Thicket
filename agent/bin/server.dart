/// Thicket Agent Server Module
///
/// This module implements the main entrypoint and webhook router for the Thicket event-driven agent. It parses incoming
/// webhook requests, initializes a stateful Gemini chat session with structured Thicket storage tools, and executes the
/// cognitive loop to learn from codebase changes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:thicket/thicket.dart';

/// Resolves project configuration and constructs the appropriate entity store.
///
/// First attempts to resolve identity from environment variables (for cloud deployments where no filesystem config is
/// available). Falls back to reading `.thicket/project.json` from the provided project path for local development.
class StoreResolver {
  /// Safely resolves the user's home directory across different operating systems.
  static String getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          Platform.environment['APPDATA'] ??
          '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Resolves the project identity, preferring environment variables over local files.
  ///
  /// On cloud deployments (Cloud Run, GCE), the identity is constructed entirely from environment variables
  /// (`THICKET_PROJECT_ID`, `GCP_PROJECT_ID`, etc.) without touching the filesystem. For local development, falls back
  /// to reading the `.thicket/project.json` file at [projectPath].
  ///
  /// Throws [StateError] if neither environment variables nor a local identity file can provide the identity.
  static ProjectIdentity readIdentity(String projectPath) {
    // Try environment variables first (works on Cloud Run without any local files).
    final ProjectIdentity? envIdentity = IdentityResolver.fromEnvironment(
      Platform.environment,
    );
    if (envIdentity != null) {
      return envIdentity;
    }

    // Fall back to reading the local identity file.
    final File identityFile = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!identityFile.existsSync()) {
      throw StateError(
        'Project identity could not be resolved. Set THICKET_PROJECT_ID and GCP_PROJECT_ID environment variables, '
        'or ensure .thicket/project.json exists at: $projectPath',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(identityFile.readAsStringSync()) as Map<String, dynamic>;
    return ProjectIdentity.fromJson(json);
  }

  /// Creates a [FirestoreEntityStore] for projects using cloud storage.
  ///
  /// Requires the `GCP_PROJECT_ID` environment variable (or the value from project.json) for authentication.
  /// On Cloud Run, automatically fetches an access token from the instance metadata server.
  static Future<FirestoreEntityStore> createFirestoreStore(
      ProjectIdentity identity) async {
    final String? gcpProjectId =
        identity.gcpProjectId ?? Platform.environment['GCP_PROJECT_ID'];

    if (gcpProjectId == null || gcpProjectId.isEmpty) {
      throw StateError(
        'Cloud storage mode requires a GCP project ID. Set gcpProjectId in .thicket/project.json or the '
        'GCP_PROJECT_ID environment variable.',
      );
    }

    String? accessToken = Platform.environment['GOOGLE_ACCESS_TOKEN'];
    final String? apiKey = Platform.environment['FIREBASE_API_KEY'];

    // On Cloud Run, fetch an access token from the metadata server if none is explicitly provided.
    if (accessToken == null && apiKey == null) {
      accessToken = await _fetchMetadataAccessToken();
    }

    return FirestoreEntityStore(
      gcpProjectId: gcpProjectId,
      thicketProjectId: identity.projectId,
      accessToken: accessToken,
      apiKey: apiKey,
      databaseId: Platform.environment['FIRESTORE_DATABASE_ID'] ??
          'thicket-world-model',
    );
  }

  /// Creates a local [EntityStore] for projects using centralized or in-repo storage.
  static EntityStore createLocalStore(
      ProjectIdentity identity, String projectPath) {
    if (identity.storageMode == StorageMode.inRepo) {
      return EntityStore(
          storagePath: p.join(projectPath, '.thicket', 'world_model'));
    }

    final String home = getHomeDirectory();
    if (home.isEmpty) {
      throw StateError('Home directory environment variable is not set');
    }

    return EntityStore(
        storagePath: p.join(home, '.thicket', 'projects', identity.projectId));
  }

  /// Fetches an access token from the GCE instance metadata server.
  ///
  /// This is available on Cloud Run, Compute Engine, and other GCP managed compute. Returns null if the metadata
  /// server is not reachable (e.g. running locally).
  static Future<String?> _fetchMetadataAccessToken() async {
    try {
      final http.Response response = await http.get(
        Uri.parse(
          'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
        ),
        headers: <String, String>{'Metadata-Flavor': 'Google'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        return body['access_token'] as String?;
      }
    } catch (_) {
      // Not running on GCP infrastructure; return null.
    }
    return null;
  }
}

/// Schema definition for the `remember` tool exposed to Gemini.
///
/// Allows the agent to save or update JSON entities in a collection.
final FunctionDeclaration rememberDeclaration = FunctionDeclaration(
  'remember',
  'Saves or updates a JSON entity in a specified collection in the project world model.',
  Schema(
    SchemaType.object,
    properties: <String, Schema>{
      'projectPath': Schema(SchemaType.string,
          description: 'Absolute path to the project root.'),
      'collection': Schema(SchemaType.string,
          description:
              'The target collection name (e.g., "experiences", "beliefs").'),
      'id': Schema(SchemaType.string,
          description:
              'Optional unique identifier. If omitted, a new one is generated.'),
      'data': Schema(SchemaType.object,
          description:
              'The flexible JSON payload containing the entity properties.'),
    },
    requiredProperties: <String>['projectPath', 'collection', 'data'],
  ),
);

/// Schema definition for the `recall` tool exposed to Gemini.
///
/// Allows the agent to retrieve entities from a collection.
final FunctionDeclaration recallDeclaration = FunctionDeclaration(
  'recall',
  'Retrieves entities from a specified collection in the project world model.',
  Schema(
    SchemaType.object,
    properties: <String, Schema>{
      'projectPath': Schema(SchemaType.string,
          description: 'Absolute path to the project root.'),
      'collection':
          Schema(SchemaType.string, description: 'The target collection name.'),
      'id': Schema(SchemaType.string,
          description: 'Optional identifier of a specific entity to retrieve.'),
    },
    requiredProperties: <String>['projectPath', 'collection'],
  ),
);

/// Schema definition for the `forget` tool exposed to Gemini.
///
/// Allows the agent to delete a specific entity from a collection.
final FunctionDeclaration forgetDeclaration = FunctionDeclaration(
  'forget',
  'Deletes an entity from a specified collection in the project world model.',
  Schema(
    SchemaType.object,
    properties: <String, Schema>{
      'projectPath': Schema(SchemaType.string,
          description: 'Absolute path to the project root.'),
      'collection':
          Schema(SchemaType.string, description: 'The target collection name.'),
      'id': Schema(SchemaType.string,
          description: 'The unique identifier of the entity to delete.'),
    },
    requiredProperties: <String>['projectPath', 'collection', 'id'],
  ),
);

/// Schema definition for the `investigateCodebase` tool exposed to Gemini.
///
/// Allows the agent to read local files in the project to gather context.
final FunctionDeclaration investigateDeclaration = FunctionDeclaration(
  'investigateCodebase',
  'Reads the content of a file in the codebase to understand context.',
  Schema(
    SchemaType.object,
    properties: <String, Schema>{
      'projectPath': Schema(SchemaType.string,
          description: 'Absolute path to the project root.'),
      'relativePath': Schema(SchemaType.string,
          description: 'Relative path of the file to inspect.'),
    },
    requiredProperties: <String>['projectPath', 'relativePath'],
  ),
);

/// Handles executing the `remember` tool called by Gemini.
///
/// Saves or updates the entity in the target project's world model store. Resolves the appropriate storage backend
/// (Firestore or local) based on the project's configuration.
Future<Map<String, dynamic>> handleRemember(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String;
  final String collection = args['collection'] as String;
  final String? id = args['id'] as String?;
  final Map<String, dynamic> data = args['data'] as Map<String, dynamic>;

  final ProjectIdentity identity = StoreResolver.readIdentity(projectPath);

  final DateTime now = DateTime.now().toUtc();
  final String entityId;
  final WorldModelEntity entity;

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store =
        await StoreResolver.createFirestoreStore(identity);

    if (id != null && id.isNotEmpty) {
      entityId = id;
      final Map<String, dynamic>? existing =
          await store.load(collection: collection, id: entityId);
      if (existing != null) {
        final WorldModelEntity original = WorldModelEntity.fromJson(existing);
        entity = WorldModelEntity(
            id: entityId,
            createdAt: original.createdAt,
            updatedAt: now,
            data: data);
        await store.update(collection: collection, entity: entity);
      } else {
        entity = WorldModelEntity(
            id: entityId, createdAt: now, updatedAt: now, data: data);
        await store.save(collection: collection, entity: entity);
      }
    } else {
      final IdGenerator generator = IdGenerator();
      entityId = generator.generateShort();
      entity = WorldModelEntity(
          id: entityId, createdAt: now, updatedAt: now, data: data);
      await store.save(collection: collection, entity: entity);
    }
  } else {
    final EntityStore store =
        StoreResolver.createLocalStore(identity, projectPath);

    if (id != null && id.isNotEmpty) {
      entityId = id;
      final Map<String, dynamic>? existing =
          await store.load(collection: collection, id: entityId);
      if (existing != null) {
        final WorldModelEntity original = WorldModelEntity.fromJson(existing);
        entity = WorldModelEntity(
            id: entityId,
            createdAt: original.createdAt,
            updatedAt: now,
            data: data);
        await store.update(collection: collection, entity: entity);
      } else {
        entity = WorldModelEntity(
            id: entityId, createdAt: now, updatedAt: now, data: data);
        await store.save(collection: collection, entity: entity);
      }
    } else {
      final IdGenerator generator = IdGenerator();
      entityId = generator.generateShort();
      entity = WorldModelEntity(
          id: entityId, createdAt: now, updatedAt: now, data: data);
      await store.save(collection: collection, entity: entity);
    }
  }

  return <String, dynamic>{
    'status': 'saved',
    'id': entityId,
    'entity': entity.toJson(),
  };
}

/// Handles executing the `recall` tool called by Gemini.
///
/// Retrieves a single entity by ID or lists all entities in the collection. Uses the project's configured storage
/// backend.
Future<Map<String, dynamic>> handleRecall(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String;
  final String collection = args['collection'] as String;
  final String? id = args['id'] as String?;

  final ProjectIdentity identity = StoreResolver.readIdentity(projectPath);

  Map<String, dynamic>? entityJson;
  List<Map<String, dynamic>> allJson;

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store =
        await StoreResolver.createFirestoreStore(identity);

    if (id != null && id.isNotEmpty) {
      entityJson = await store.load(collection: collection, id: id);
    } else {
      allJson = await store.listAll(collection: collection);
      final List<WorldModelEntity> entities =
          allJson.map(WorldModelEntity.fromJson).toList();
      entities.sort(
        (WorldModelEntity a, WorldModelEntity b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      return <String, dynamic>{
        'count': entities.length,
        'entities': entities.map((WorldModelEntity e) => e.toJson()).toList(),
      };
    }
  } else {
    final EntityStore store =
        StoreResolver.createLocalStore(identity, projectPath);

    if (id != null && id.isNotEmpty) {
      entityJson = await store.load(collection: collection, id: id);
    } else {
      allJson = await store.listAll(collection: collection);
      final List<WorldModelEntity> entities =
          allJson.map(WorldModelEntity.fromJson).toList();
      entities.sort(
        (WorldModelEntity a, WorldModelEntity b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      return <String, dynamic>{
        'count': entities.length,
        'entities': entities.map((WorldModelEntity e) => e.toJson()).toList(),
      };
    }
  }

  if (entityJson != null) {
    final WorldModelEntity entity = WorldModelEntity.fromJson(entityJson);
    return <String, dynamic>{
      'count': 1,
      'entities': <Map<String, dynamic>>[entity.toJson()],
    };
  } else {
    return <String, dynamic>{
      'count': 0,
      'entities': <Map<String, dynamic>>[],
    };
  }
}

/// Handles executing the `forget` tool called by Gemini.
///
/// Deletes the entity by ID from the specified collection using the project's configured storage backend.
Future<Map<String, dynamic>> handleForget(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String;
  final String collection = args['collection'] as String;
  final String id = args['id'] as String;

  final ProjectIdentity identity = StoreResolver.readIdentity(projectPath);
  bool success;

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store =
        await StoreResolver.createFirestoreStore(identity);
    success = await store.delete(collection: collection, id: id);
  } else {
    final EntityStore store =
        StoreResolver.createLocalStore(identity, projectPath);
    success = await store.delete(collection: collection, id: id);
  }

  return <String, dynamic>{
    'status': success ? 'deleted' : 'not_found',
    'id': id,
  };
}

/// Handles executing the `investigateCodebase` tool called by Gemini.
///
/// Reads and returns the raw file content from the project path.
Future<Map<String, dynamic>> handleInvestigate(
  Map<String, dynamic> args,
) async {
  final String projectPath = args['projectPath'] as String;
  final String relativePath = args['relativePath'] as String;

  final File file = File(p.join(projectPath, relativePath));
  if (!file.existsSync()) {
    return <String, dynamic>{
      'status': 'error',
      'message': 'File not found: $relativePath',
    };
  }

  final String content = await file.readAsString();
  return <String, dynamic>{
    'status': 'success',
    'content': content,
  };
}

/// Normalizes and processes the webhook event using a Gemini chat session.
///
/// Initializes a stateful chat, prompts the model with the event details, coordinates the tool execution loop, and
/// returns the final agent report.
Future<String> processEvent({
  required String apiKey,
  required String source,
  required String eventType,
  required String projectPath,
  required Map<String, dynamic> payload,
}) async {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-3.5-flash',
    apiKey: apiKey,
    systemInstruction: Content.system(
        'You are Thicket Agent, an autonomous codebase learning assistant. '
        'Your goal is to build, maintain, and query a persistent world model '
        'of the codebase/project you are working in.\n\n'
        'You receive normalized events from development tools (GitHub, GitLab, '
        'Slack, file changes). Use the Thicket world model tools (remember, '
        'recall, forget) and investigateCodebase tool to retrieve context, '
        'read files if necessary, decide what is worth learning or updating, '
        'and update the world model accordingly.'),
    tools: <Tool>[
      Tool(
        functionDeclarations: <FunctionDeclaration>[
          rememberDeclaration,
          recallDeclaration,
          forgetDeclaration,
          investigateDeclaration,
        ],
      ),
    ],
  );

  final ChatSession chat = model.startChat();

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

  GenerateContentResponse response =
      await chat.sendMessage(Content.text(prompt));

  while (response.functionCalls.isNotEmpty) {
    final List<FunctionResponse> responses = <FunctionResponse>[];

    for (final FunctionCall call in response.functionCalls) {
      Map<String, dynamic> result;
      try {
        if (call.name == 'remember') {
          result = await handleRemember(call.args);
        } else if (call.name == 'recall') {
          result = await handleRecall(call.args);
        } else if (call.name == 'forget') {
          result = await handleForget(call.args);
        } else if (call.name == 'investigateCodebase') {
          result = await handleInvestigate(call.args);
        } else {
          result = <String, dynamic>{'error': 'Unknown function: ${call.name}'};
        }
      } catch (e) {
        result = <String, dynamic>{'error': e.toString()};
      }

      responses.add(FunctionResponse(call.name, result));
    }

    response = await chat.sendMessage(Content.functionResponses(responses));
  }

  return response.text ?? 'No response';
}

/// Handles project registration by creating a new scoped partition in Firestore.
///
/// Generates a unique project ID and API token, writes a metadata document to Firestore to initialize the project's
/// storage partition, and returns the credentials the client needs.
Future<Response> handleProjectRegistration(Request request) async {
  try {
    final String payloadString = await request.readAsString();
    final Map<String, dynamic> body =
        jsonDecode(payloadString) as Map<String, dynamic>;

    final String? projectName = body['projectName'] as String?;
    if (projectName == null || projectName.isEmpty) {
      return Response.badRequest(
          body: 'Missing required parameter: projectName');
    }

    // Generate a unique project ID and API token.
    final IdGenerator generator = IdGenerator();
    final String projectId = generator.generate();
    final String apiToken = 'thk_${generator.generateShort(length: 32)}';

    // Resolve the GCP project ID from environment.
    final String gcpProjectId = Platform.environment['GCP_PROJECT_ID'] ?? '';
    if (gcpProjectId.isEmpty) {
      return Response.internalServerError(
        body: 'GCP_PROJECT_ID environment variable is not set',
      );
    }

    String? accessToken = Platform.environment['GOOGLE_ACCESS_TOKEN'];
    final String? apiKey = Platform.environment['FIREBASE_API_KEY'];

    // On Cloud Run, fetch a token from the metadata server if none is explicitly set.
    if (accessToken == null && apiKey == null) {
      accessToken = await StoreResolver._fetchMetadataAccessToken();
    }

    final FirestoreEntityStore store = FirestoreEntityStore(
      gcpProjectId: gcpProjectId,
      thicketProjectId: projectId,
      accessToken: accessToken,
      apiKey: apiKey,
      databaseId: Platform.environment['FIRESTORE_DATABASE_ID'] ??
          'thicket-world-model',
    );

    // Write a metadata entity to Firestore to initialize the project partition.
    final DateTime now = DateTime.now().toUtc();
    final WorldModelEntity metadata = WorldModelEntity(
      id: 'project_metadata',
      createdAt: now,
      updatedAt: now,
      data: <String, dynamic>{
        'projectName': projectName,
        'apiToken': apiToken,
        'createdAt': now.toIso8601String(),
      },
    );

    await store.save(collection: '_meta', entity: metadata);

    // Determine the agent URL from the request.
    final String host = request.requestedUri.host;
    final int port = request.requestedUri.port;
    final String scheme = request.requestedUri.scheme;
    final String agentUrl = port == 443 || port == 80
        ? '$scheme://$host/events'
        : '$scheme://$host:$port/events';

    return Response.ok(
      jsonEncode(<String, dynamic>{
        'projectId': projectId,
        'apiToken': apiToken,
        'agentUrl': agentUrl,
      }),
      headers: <String, String>{'content-type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Registration failed: $e');
  }
}

/// Main entrypoint for the event-driven Thicket Agent server.
///
/// Exposes endpoints for event processing and project registration. Listens on the port specified by the `PORT`
/// environment variable (defaulting to 8080).
void main(List<String> args) async {
  final Router router = Router()
    ..post('/projects', handleProjectRegistration)
    ..post('/events', (Request request) async {
      final String payloadString = await request.readAsString();
      final Map<String, dynamic> body =
          jsonDecode(payloadString) as Map<String, dynamic>;

      final String? source = body['source'] as String?;
      final String? eventType = body['eventType'] as String?;
      final String? projectPath = body['projectPath'] as String?;
      final Map<String, dynamic> payload =
          body['payload'] as Map<String, dynamic>? ?? <String, dynamic>{};

      if (source == null || eventType == null || projectPath == null) {
        return Response.badRequest(
            body:
                'Missing required parameters: source, eventType, projectPath');
      }

      final String apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        return Response.internalServerError(
            body: 'GEMINI_API_KEY environment variable is not set');
      }

      try {
        final String summary = await processEvent(
          apiKey: apiKey,
          source: source,
          eventType: eventType,
          projectPath: projectPath,
          payload: payload,
        );

        return Response.ok(
          jsonEncode(
              <String, dynamic>{'status': 'success', 'summary': summary}),
          headers: <String, String>{'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

  // Cloud Run sets the PORT environment variable
  final String portStr = Platform.environment['PORT'] ?? '8080';
  final int port = int.tryParse(portStr) ?? 8080;

  final HttpServer server =
      await io.serve(router.call, InternetAddress.anyIPv4, port);
  print('Thicket Agent listening on port ${server.port}');
}
