import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Handles the Google OAuth2 sign-in flow for web using the implicit grant.
///
/// On web, we cannot start a local HTTP server. Instead, this implementation opens a popup window to the Google consent
/// page with `response_type=token`. Google redirects back to the same origin with the access token in the URL fragment.
/// A listener on the popup's navigation detects the token and completes the flow.
class GoogleAuthService {
  /// The OAuth2 client ID for the Thicket installer application.
  static const String _clientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');

  /// The OAuth2 scopes needed to identify the user.
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  /// Initiates the OAuth2 implicit grant flow and returns an access token.
  ///
  /// Opens a popup window to Google's consent page. After the user grants permission, Google redirects back to
  /// `/oauth_callback.html` on the same origin with the access token in the URL fragment. A `message` event from the
  /// popup delivers the token back to this window.
  ///
  /// Throws an exception if the flow fails, is cancelled, or times out.
  static Future<String> signIn() async {
    final String redirectUri = '${html.window.location.origin}/oauth_callback.html';

    final Uri authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', <String, String>{
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'response_type': 'token',
      'scope': _scopes.join(' '),
      'prompt': 'consent',
      'include_granted_scopes': 'true',
    });

    final Completer<String> tokenCompleter = Completer<String>();

    // Listen for a postMessage from the popup containing the access token.
    late final StreamSubscription<html.MessageEvent> subscription;
    subscription = html.window.onMessage.listen((html.MessageEvent event) {
      // Only accept messages from our own origin.
      if (event.origin != html.window.location.origin) return;

      final dynamic data = event.data;
      if (data is Map) {
        final String? accessToken = data['access_token'] as String?;
        final String? error = data['error'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          tokenCompleter.complete(accessToken);
          subscription.cancel();
        } else if (error != null) {
          tokenCompleter.completeError(Exception('OAuth error: $error'));
          subscription.cancel();
        }
      }
    });

    // Open the consent page in a popup.
    final html.WindowBase? popup = html.window.open(
      authUrl.toString(),
      'thicket_oauth',
      'width=500,height=700,menubar=no,toolbar=no,location=yes',
    );

    if (popup == null) {
      subscription.cancel();
      throw Exception(
        'Failed to open sign-in popup. Please allow popups for this site.',
      );
    }

    // Poll to detect if the user closed the popup without completing sign-in.
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      if (popup.closed == true && !tokenCompleter.isCompleted) {
        timer.cancel();
        subscription.cancel();
        tokenCompleter.completeError(Exception('Sign-in was cancelled.'));
      }
      if (tokenCompleter.isCompleted) {
        timer.cancel();
      }
    });

    try {
      return await tokenCompleter.future.timeout(const Duration(minutes: 3));
    } on TimeoutException {
      subscription.cancel();
      throw Exception('Sign-in timed out. Please try again.');
    }
  }
}
