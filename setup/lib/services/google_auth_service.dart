import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Handles the Google OAuth2 sign-in flow using a local redirect server.
///
/// Opens the user's browser to the Google consent page and starts a temporary HTTP server on localhost to receive the
/// authorization code redirect. Exchanges the code for an access token and returns it.
class GoogleAuthService {
  /// The OAuth2 client ID for the Thicket installer application.
  ///
  /// This client ID is registered in the Thicket GCP project and configured for desktop (loopback) redirect URIs.
  /// It does not grant access to any resources; it only enables the consent flow.
  static const String _clientId =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');

  /// The OAuth2 client secret for the Thicket installer application.
  static const String _clientSecret =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_SECRET');

  /// The port used for the local OAuth redirect server.
  static const int _redirectPort = 9876;

  /// The OAuth2 scopes needed to provision GCP resources and access Gemini.
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  /// Initiates the OAuth2 sign-in flow and returns an access token.
  ///
  /// Opens the system browser to Google's consent page and waits for the redirect on a local HTTP server. Once the
  /// authorization code is received, exchanges it for an access token.
  ///
  /// Throws an exception if the flow fails or is cancelled.
  static Future<String> signIn() async {
    const String redirectUri = 'http://localhost:$_redirectPort/callback';

    final Uri authUrl =
        Uri.https('accounts.google.com', '/o/oauth2/v2/auth', <String, String>{
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': _scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
    });

    // Start the local redirect server before opening the browser.
    final Completer<String> codeCompleter = Completer<String>();
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, _redirectPort);

    server.listen((HttpRequest request) async {
      if (request.uri.path == '/callback') {
        final String? code = request.uri.queryParameters['code'];
        final String? error = request.uri.queryParameters['error'];

        if (code != null) {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(
                '<html><body><h2>Sign-in complete.</h2><p>You can close this window.</p></body></html>');
          await request.response.close();
          codeCompleter.complete(code);
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.html
            ..write(
                '<html><body><h2>Sign-in failed.</h2><p>${error ?? "Unknown error"}</p></body></html>');
          await request.response.close();
          codeCompleter
              .completeError(Exception(error ?? 'Authorization was denied'));
        }
      }
    });

    // Open the browser to the consent page.
    await _openBrowser(authUrl.toString());

    try {
      // Wait for the authorization code (with a timeout).
      final String code =
          await codeCompleter.future.timeout(const Duration(minutes: 3));

      // Exchange the code for an access token.
      final String accessToken = await _exchangeCode(code, redirectUri);
      return accessToken;
    } finally {
      await server.close();
    }
  }

  /// Exchanges an authorization code for an access token.
  static Future<String> _exchangeCode(String code, String redirectUri) async {
    final http.Response response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded'
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
          'Token exchange failed: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> tokenData =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String? accessToken = tokenData['access_token'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token in response');
    }

    return accessToken;
  }

  /// Opens the given URL in the system default browser.
  static Future<void> _openBrowser(String url) async {
    if (Platform.isMacOS) {
      await Process.run('open', <String>[url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', <String>[url]);
    } else if (Platform.isWindows) {
      await Process.run('start', <String>[url], runInShell: true);
    }
  }
}
