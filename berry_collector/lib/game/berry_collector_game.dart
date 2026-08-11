import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'components/berry_component.dart';
import 'components/hud_component.dart';
import 'models/berry_type.dart';

/// The main Flame game class for Berry Collector.
///
/// Manages the game loop, berry spawning, score tracking, and the countdown timer. Berries spawn at random positions
/// and the player taps them to collect points before time runs out.
class BerryCollectorGame extends FlameGame<World> with TapCallbacks {
  /// Duration of a single game round in seconds.
  static const double _gameDuration = 60.0;

  /// Interval between berry spawns in seconds.
  static const double _spawnInterval = 1.2;

  /// Maximum number of berries on screen at once.
  static const int _maxBerries = 15;

  /// Random number generator for spawn positions and berry types.
  final Random _random = Random();

  /// The current player score.
  int _score = 0;

  /// Time remaining in the current round.
  double _timeRemaining = _gameDuration;

  /// Accumulated time since the last berry spawn.
  double _timeSinceLastSpawn = 0;

  /// Whether the game round is currently active.
  bool _isPlaying = true;

  /// The current score.
  int get score => _score;

  /// Seconds remaining in the round.
  double get timeRemaining => _timeRemaining;

  /// Whether the game is still active.
  bool get isPlaying => _isPlaying;

  @override
  Color backgroundColor() => const Color(0xFF2E7D32);

  @override
  Future<void> onLoad() async {
    add(HudComponent());
    _spawnBerry();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isPlaying) return;

    _timeRemaining -= dt;
    if (_timeRemaining <= 0) {
      _timeRemaining = 0;
      _isPlaying = false;
      overlays.add('gameOver');
      return;
    }

    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= _spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawnBerry();
    }
  }

  /// Awards points for a collected berry.
  void collectBerry(BerryComponent berry) {
    if (!_isPlaying) return;
    _score += berry.berryType.points;
  }

  /// Resets the game state for a new round.
  void restart() {
    _score = 0;
    _timeRemaining = _gameDuration;
    _timeSinceLastSpawn = 0;
    _isPlaying = true;

    // Remove all existing berries.
    children
        .whereType<BerryComponent>()
        .toList()
        .forEach((BerryComponent b) => b.removeFromParent());
  }

  /// Spawns a new berry at a random position if below the maximum count.
  void _spawnBerry() {
    final int currentCount = children.whereType<BerryComponent>().length;
    if (currentCount >= _maxBerries) return;

    final double margin = 40;
    final Vector2 position = Vector2(
      margin + _random.nextDouble() * (size.x - margin * 2),
      margin + 50 + _random.nextDouble() * (size.y - margin * 2 - 50),
    );

    final BerryType type = BerryComponent.randomType(_random);
    add(BerryComponent(berryType: type, position: position));
  }
}
