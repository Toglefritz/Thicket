/// Stub implementation that throws at runtime.
///
/// This file is only reached if conditional imports fail to resolve to a platform-specific implementation, which should
/// never happen in practice.
class GoogleAuthService {
  /// Throws [UnsupportedError] because this stub should never be reached.
  static Future<String> signIn() {
    throw UnsupportedError(
      'GoogleAuthService is not configured for this platform.',
    );
  }
}
