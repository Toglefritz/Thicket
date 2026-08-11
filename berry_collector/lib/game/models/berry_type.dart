import 'dart:ui';

/// Defines the types of berries available in the game.
///
/// Each berry type has a distinct color, point value, and spawn probability. Rarer berries are worth more points but
/// appear less frequently.
enum BerryType {
  /// Common red berries found throughout the thicket. Low value but easy to find.
  raspberry(
    color: Color(0xFFE53935),
    points: 1,
    spawnWeight: 40,
    label: 'Raspberry',
  ),

  /// Blue berries that grow in clusters. Medium value and moderately common.
  blueberry(
    color: Color(0xFF1E88E5),
    points: 2,
    spawnWeight: 30,
    label: 'Blueberry',
  ),

  /// Dark purple blackberries hidden deeper in the thicket. Higher value and less common.
  blackberry(
    color: Color(0xFF4A148C),
    points: 3,
    spawnWeight: 20,
    label: 'Blackberry',
  ),

  /// Rare golden berries that shimmer among the leaves. High value and seldom seen.
  goldenberry(
    color: Color(0xFFFFD600),
    points: 5,
    spawnWeight: 10,
    label: 'Golden Berry',
  );

  const BerryType({
    required this.color,
    required this.points,
    required this.spawnWeight,
    required this.label,
  });

  /// The display color for this berry type.
  final Color color;

  /// Points awarded when this berry is collected.
  final int points;

  /// Relative spawn probability. Higher values mean more frequent spawns.
  final int spawnWeight;

  /// Human-readable name for this berry type.
  final String label;

  /// The combined weight of all berry types, used for weighted random selection.
  static int get totalWeight =>
      BerryType.values.fold(0, (int sum, BerryType type) => sum + type.spawnWeight);
}
