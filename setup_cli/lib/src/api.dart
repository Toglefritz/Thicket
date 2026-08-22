/// Thicket Backend API Client
///
/// Provides functions for communicating with the Thicket backend running on Cloud Run. Handles project registration
/// (creating new projects) and joining existing projects. All requests are authenticated with the user's OAuth2 access
/// token obtained during sign-in.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The default Thicket backend URL.
///
/// Resolved in order of priority:
/// 1. Compile-time constant via `-DTHICKET_API_URL=...`.
/// 2. Platform environment variable `THICKET_API_URL`.
/// 3. The production Cloud Run URL as a hardcoded fallback.
final String defaultBaseUrl =
    const String.fromEnvironment('THICKET_API_URL').isNotEmpty
        ? const String.fromEnvironment('THICKET_API_URL')
        : Platform.environment['THICKET_API_URL'] ??
            'https://thicket-agent-1081534978416.us-central1.run.app';

/// Registers a new project with the Thicket backend.
///
/// Sends a POST request to `/projects` with the user's [accessToken] and desired [projectName]. The backend creates a
/// scoped partition in Firestore and returns a project ID, API token, and agent URL.
///
/// Returns the raw response body as a decoded JSON map containing at minimum `projectId`, `apiToken`, and `agentUrl`.
///
/// Throws an [Exception] if the backend returns a non-success status code or the response is missing required fields.
Future<Map<String, dynamic>> registerProject(
  String accessToken,
  String projectName,
) async {
  final http.Response response = await http.post(
    Uri.parse('$defaultBaseUrl/projects'),
    headers: <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{'projectName': projectName}),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(
      'Registration failed: ${response.statusCode} ${response.body}',
    );
  }

  final Map<String, dynamic> body =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (body['projectId'] == null || body['apiToken'] == null) {
    throw Exception(
      'Unexpected response from server: missing projectId or apiToken',
    );
  }

  return body;
}

/// Joins an existing Thicket project by requesting a new API token from the backend.
///
/// Sends a POST request to `/projects/join` with the user's [accessToken] and the [projectId] of the project to join.
/// The backend verifies the project exists and issues a fresh token for this collaborator.
///
/// Returns the raw response body as a decoded JSON map containing at minimum `projectId`, `apiToken`, and `agentUrl`.
///
/// Throws an [Exception] if the backend returns a non-success status code or the response is missing required fields.
Future<Map<String, dynamic>> joinProject(
  String accessToken,
  String projectId,
) async {
  final http.Response response = await http.post(
    Uri.parse('$defaultBaseUrl/projects/join'),
    headers: <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{'projectId': projectId}),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(
      'Join failed: ${response.statusCode} ${response.body}',
    );
  }

  final Map<String, dynamic> body =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (body['projectId'] == null || body['apiToken'] == null) {
    throw Exception(
      'Unexpected response from server: missing projectId or apiToken',
    );
  }

  return body;
}
