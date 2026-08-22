/// Platform-aware Google OAuth2 sign-in service.
///
/// Uses conditional imports to select the correct implementation at compile time:
/// - On native (macOS, Linux, Windows): uses a local loopback HTTP server to receive the OAuth redirect.
/// - On web: uses the implicit grant flow with a popup window and postMessage.
///
/// Both implementations expose the same static `signIn()` method returning a `Future<String>` access token.
library;

export 'google_auth_service_stub.dart'
    if (dart.library.io) 'google_auth_service_io.dart'
    if (dart.library.html) 'google_auth_service_web.dart';
