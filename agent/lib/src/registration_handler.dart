import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:thicket/thicket.dart';

import 'store_resolver.dart';

/// Handles project registration by creating a new scoped partition in Firestore.
///
/// Generates a unique project ID and API token, writes a metadata document to Firestore to initialize the project's
/// storage partition, and returns the credentials the client needs to send future events.
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

    final IdGenerator generator = IdGenerator();
    final String projectId = generator.generate();
    final String apiToken = 'thk_${generator.generateShort(length: 32)}';

    final String gcpProjectId = Platform.environment['GCP_PROJECT_ID'] ?? '';
    if (gcpProjectId.isEmpty) {
      return Response.internalServerError(
          body: 'GCP_PROJECT_ID environment variable is not set');
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
        'gcpProjectId': gcpProjectId,
      }),
      headers: <String, String>{'content-type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Registration failed: $e');
  }
}
