import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:thicket/thicket.dart';

import 'store_resolver.dart';

/// Handles requests to join an existing project by issuing a new API token.
///
/// Verifies that the project exists in Firestore by loading its metadata document, then generates a fresh API token for
/// the joining collaborator.
Future<Response> handleProjectJoin(Request request) async {
  try {
    final String payloadString = await request.readAsString();
    final Map<String, dynamic> body =
        jsonDecode(payloadString) as Map<String, dynamic>;

    final String? projectId = body['projectId'] as String?;
    if (projectId == null || projectId.isEmpty) {
      return Response.badRequest(
        body: 'Missing required parameter: projectId',
      );
    }

    final String gcpProjectId = Platform.environment['GCP_PROJECT_ID'] ?? '';
    if (gcpProjectId.isEmpty) {
      return Response.internalServerError(
        body: 'GCP_PROJECT_ID environment variable is not set',
      );
    }

    String? accessToken = Platform.environment['GOOGLE_ACCESS_TOKEN'];
    final String? apiKey = Platform.environment['FIREBASE_API_KEY'];

    if (accessToken == null && apiKey == null) {
      accessToken = await StoreResolver.fetchMetadataAccessToken();
    }

    final FirestoreEntityStore store = FirestoreEntityStore(
      gcpProjectId: gcpProjectId,
      thicketProjectId: projectId,
      accessToken: accessToken,
      apiKey: apiKey,
      databaseId: Platform.environment['FIRESTORE_DATABASE_ID'] ??
          'thicket-world-model',
    );

    // Verify the project exists by loading its metadata.
    final Map<String, dynamic>? metadata = await store.load(
      collection: '_meta',
      id: 'project_metadata',
    );

    if (metadata == null) {
      return Response.notFound(
        jsonEncode(<String, dynamic>{
          'error': 'Project not found: $projectId',
        }),
        headers: <String, String>{'content-type': 'application/json'},
      );
    }

    // Generate a new API token for this collaborator.
    final IdGenerator generator = IdGenerator();
    final String newApiToken = 'thk_${generator.generateShort(length: 32)}';

    final String host = request.requestedUri.host;
    final int port = request.requestedUri.port;
    final String scheme = request.requestedUri.scheme;
    final String agentUrl = port == 443 || port == 80
        ? '$scheme://$host/events'
        : '$scheme://$host:$port/events';

    return Response.ok(
      jsonEncode(<String, dynamic>{
        'projectId': projectId,
        'apiToken': newApiToken,
        'agentUrl': agentUrl,
      }),
      headers: <String, String>{'content-type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Join failed: $e');
  }
}
