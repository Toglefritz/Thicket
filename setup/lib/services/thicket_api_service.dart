import 'dart:convert';

import 'package:http/http.dart' as http;

/// Communicates with the Thicket backend to register projects and manage API tokens.
///
/// The backend runs on Cloud Run and owns all GCP resources (Firestore, Gemini). Users interact with it through this
/// service rather than provisioning their own infrastructure.
class ThicketApiService {
  /// Creates a service instance targeting the given backend URL.
  ThicketApiService({
    required String accessToken,
    String? baseUrl,
  })  : _accessToken = accessToken,
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  /// The default Thicket backend URL.
  ///
  /// Set via compile-time constant for flexibility across environments.
  static const String _defaultBaseUrl = String.fromEnvironment(
    'THICKET_API_URL',
    defaultValue: 'https://thicket-agent-1081534978416.us-central1.run.app',
  );

  /// OAuth2 access token used to authenticate the user with the backend.
  final String _accessToken;

  /// Base URL of the Thicket backend API.
  final String _baseUrl;

  /// Registers a new project with the Thicket backend.
  ///
  /// The backend creates a scoped partition in Firestore for this project and returns a project ID and API token that
  /// the MCP server and webhooks use to authenticate future requests.
  ///
  /// Returns a [RegistrationResult] containing the project ID and API token.
  Future<RegistrationResult> registerProject({
    required String projectName,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$_baseUrl/projects'),
      headers: <String, String>{
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'projectName': projectName,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to register project: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

    final String? projectId = body['projectId'] as String?;
    final String? apiToken = body['apiToken'] as String?;

    if (projectId == null || apiToken == null) {
      throw Exception(
        'Unexpected response from server: missing projectId or apiToken',
      );
    }

    return RegistrationResult(
      projectId: projectId,
      apiToken: apiToken,
      agentUrl: body['agentUrl'] as String? ?? _baseUrl,
    );
  }

  /// Joins an existing project by requesting a new API token from the Thicket backend.
  ///
  /// The backend verifies the project exists and issues a fresh token for this collaborator.
  ///
  /// Returns a [RegistrationResult] containing the project ID and new API token.
  Future<RegistrationResult> joinProject({
    required String projectId,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$_baseUrl/projects/join'),
      headers: <String, String>{
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'projectId': projectId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to join project: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

    final String? returnedProjectId = body['projectId'] as String?;
    final String? apiToken = body['apiToken'] as String?;

    if (returnedProjectId == null || apiToken == null) {
      throw Exception(
        'Unexpected response from server: missing projectId or apiToken',
      );
    }

    return RegistrationResult(
      projectId: returnedProjectId,
      apiToken: apiToken,
      agentUrl: body['agentUrl'] as String? ?? _baseUrl,
    );
  }
}

/// The result of registering a project with the Thicket backend.
class RegistrationResult {
  /// Creates a registration result.
  const RegistrationResult({
    required this.projectId,
    required this.apiToken,
    required this.agentUrl,
  });

  /// The unique Thicket project ID assigned by the backend.
  final String projectId;

  /// An API token that authenticates future requests for this project.
  final String apiToken;

  /// The URL where webhooks should be sent for this project.
  final String agentUrl;
}
