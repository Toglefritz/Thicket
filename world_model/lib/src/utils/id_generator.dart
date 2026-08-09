library;

import 'dart:math';

part 'nouns.dart';
part 'adjectives.dart';

/// Generates human-readable unique identifiers for Thicket projects.
///
/// Identifiers follow the pattern `adjective-noun-XXXX` where the suffix is a short random hexadecimal string. This
/// produces identifiers that are easy to recognize when browsing the filesystem while remaining collision-resistant.
///
/// Examples: 'mossy-lantern-a3f2', 'quiet-compass-71dc', 'amber-summit-e09b'
class IdGenerator {
  /// Creates an ID generator with an optional seed for deterministic output in tests.
  IdGenerator({Random? random}) : _random = random ?? Random.secure();

  /// Random number generator used for selecting words and generating the hex suffix.
  final Random _random;

  /// Generates a new project identifier.
  ///
  /// The result is a lowercase, hyphen-separated string safe for use as a directory name on all major filesystems.
  String generate() {
    final String adjective = _adjectives.elementAt(
      _random.nextInt(_adjectives.length),
    );
    final String noun = _nouns.elementAt(_random.nextInt(_nouns.length));
    final String suffix = _randomHex(4);

    return '$adjective-$noun-$suffix';
  }

  /// Generates a short, random unique hexadecimal identifier.
  ///
  /// This is suitable for lower-level documents where the human-readable adjective-noun format is not needed.
  String generateShort({int length = 8}) {
    return _randomHex(length);
  }

  /// Produces a random hexadecimal string of the given character count.
  ///
  /// A [charCount] of 4 produces a 4-character hex string. The word combination already provides significant entropy,
  /// so this suffix only needs to be long enough to avoid collisions among projects that happen to draw the same
  /// adjective-noun pair.
  String _randomHex(int charCount) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < charCount; i++) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }

    return buffer.toString();
  }
}
