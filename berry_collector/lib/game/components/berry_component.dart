import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../berry_collector_game.dart';
import '../models/berry_type.dart';

/// A single berry rendered in the game world that can be tapped to collect it.
///
/// Berries spawn at random positions within the game bounds, display as colored circles with a size proportional to
/// their value, and are removed from the game when tapped.
class BerryComponent extends CircleComponent with TapCallbacks, HasGameReference<BerryCollectorGame> {
  /// Creates a berry of the given type at the specified position.
  BerryComponent({
    required this.berryType,
    required Vector2 position,
  }) : super(
          radius: 12.0 + (berryType.points * 2.0),
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = berryType.color,
        );

  /// The type of berry this component represents.
  final BerryType berryType;

  /// Handles tap events by awarding points and removing the berry from the game.
  @override
  void onTapDown(TapDownEvent event) {
    game.collectBerry(this);
    removeFromParent();
  }

  /// Selects a random berry type using weighted probability.
  ///
  /// Berry types with higher [BerryType.spawnWeight] values appear more frequently.
  static BerryType randomType(Random random) {
    int roll = random.nextInt(BerryType.totalWeight);
    for (final BerryType type in BerryType.values) {
      roll -= type.spawnWeight;
      if (roll < 0) {
        return type;
      }
    }
    return BerryType.raspberry;
  }
}
