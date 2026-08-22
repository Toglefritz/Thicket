/// Google OAuth2 Authentication
///
/// Implements the OAuth2 authorization code flow for CLI applications. Opens the user's default browser to the Google
/// consent page, starts a temporary HTTP server on localhost to receive the authorization code redirect, and exchanges
/// the code for an access token.
///
/// This module is designed for native (desktop/server) environments only. The loopback redirect approach does not work
/// in sandboxed or web environments.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The OAuth2 client ID for the Thicket CLI application.
///
/// Resolved in order of priority:
/// 1. Compile-time constant via `-DGOOGLE_OAUTH_CLIENT_ID=...` (used with `dart compile exe`).
/// 2. Platform environment variable `GOOGLE_OAUTH_CLIENT_ID` (used with `dart run`).
///
/// This client ID must be registered in the Thicket GCP project with a loopback redirect URI.
final String _clientId =
    const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID').isNotEmpty
        ? const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID')
        : Platform.environment['GOOGLE_OAUTH_CLIENT_ID'] ?? '';

/// The OAuth2 client secret for the Thicket CLI application.
///
/// Resolved in order of priority:
/// 1. Compile-time constant via `-DGOOGLE_OAUTH_CLIENT_SECRET=...` (used with `dart compile exe`).
/// 2. Platform environment variable `GOOGLE_OAUTH_CLIENT_SECRET` (used with `dart run`).
final String _clientSecret =
    const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_SECRET').isNotEmpty
        ? const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_SECRET')
        : Platform.environment['GOOGLE_OAUTH_CLIENT_SECRET'] ?? '';

/// The port on which the local OAuth redirect server listens.
///
/// This must match the port configured in the redirect URI registered with the OAuth client in Google Cloud Console
/// (e.g., `http://localhost:9876/callback`).
const int _redirectPort = 9876;

/// The OAuth2 scopes requested during sign-in.
///
/// Currently requests the `cloud-platform` scope, which gives the backend access to GCP resources on behalf of the
/// user. The scope is broad but access is narrowly controlled by the backend's IAM roles.
const List<String> _scopes = <String>[
  'https://www.googleapis.com/auth/cloud-platform',
];

/// Performs the complete OAuth2 sign-in flow and returns an access token.
///
/// This function:
/// 1. Constructs the Google authorization URL with the configured client ID and scopes.
/// 2. Binds a temporary HTTP server on `localhost:9876` to receive the redirect.
/// 3. Opens the user's default browser to the Google consent page.
/// 4. Waits up to 3 minutes for the user to complete the consent flow.
/// 5. Receives the authorization code from the redirect and exchanges it for an access token.
///
/// Throws an [Exception] if the flow times out, is cancelled, or if the token exchange fails.
Future<String> signIn() async {
  const String redirectUri = 'http://localhost:$_redirectPort/callback';

  final Uri authUrl = Uri.https(
    'accounts.google.com',
    '/o/oauth2/v2/auth',
    <String, String>{
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': _scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
    },
  );

  // Start the local redirect server before opening the browser.
  final Completer<String> codeCompleter = Completer<String>();
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    _redirectPort,
  );

  server.listen((HttpRequest request) async {
    if (request.uri.path == '/callback') {
      final String? code = request.uri.queryParameters['code'];
      final String? error = request.uri.queryParameters['error'];

      if (code != null) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('<html><body><h2>Sign-in complete.</h2> '
              '<p>You can close this window.</p></body></html>');
        await request.response.close();
        codeCompleter.complete(code);
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.html
          ..write('<html><body><h2>Sign-in failed.</h2> '
              '<p>${error ?? "Unknown error"}</p></body></html>');
        await request.response.close();
        codeCompleter.completeError(
          Exception(error ?? 'Authorization was denied'),
        );
      }
    }
  });

  // Open the user's default browser to the consent page.
  await _openBrowser(authUrl.toString());

  try {
    // Wait for the authorization code with a timeout.
    final String code = await codeCompleter.future.timeout(
      const Duration(minutes: 3),
    );

    // Exchange the authorization code for an access token.
    return await _exchangeCode(code, redirectUri);
  } finally {
    await server.close();
  }
}

/// Exchanges an authorization code for an access token by calling Google's token endpoint.
///
/// Sends a POST request to `https://oauth2.googleapis.com/token` with the authorization code, client credentials, and
/// redirect URI. Returns the access token string on success.
///
/// Throws an [Exception] if the token endpoint returns a non-200 status or the response is missing the access token.
Future<String> _exchangeCode(String code, String redirectUri) async {
  final http.Response response = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: <String, String>{
      'code': code,
      'client_id': _clientId,
      'client_secret': _clientSecret,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Token exchange failed: ${response.statusCode} ${response.body}',
    );
  }

  final Map<String, dynamic> tokenData =
      jsonDecode(response.body) as Map<String, dynamic>;
  final String? accessToken = tokenData['access_token'] as String?;

  if (accessToken == null || accessToken.isEmpty) {
    throw Exception('No access token in response');
  }

  return accessToken;
}

/// Opens the given [url] in the user's default system browser.
///
/// Uses platform-specific commands: `open` on macOS, `xdg-open` on Linux, and `start` on Windows.
Future<void> _openBrowser(String url) async {
  if (Platform.isMacOS) {
    await Process.run('open', <String>[url]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', <String>[url]);
  } else if (Platform.isWindows) {
    await Process.run('start', <String>[url], runInShell: true);
  }
}
