import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../berry_collector_game.dart';

/// Displays the current score and time remaining at the top of the screen.
///
/// Positioned as a fixed overlay that does not move with the game camera.
class HudComponent extends PositionComponent with HasGameReference<BerryCollectorGame> {
  /// Text renderer for the HUD display.
  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final String scoreText = 'Score: ${game.score}';
    final String timeText = 'Time: ${game.timeRemaining.ceil()}s';

    _textPaint.render(canvas, scoreText, Vector2(16, 16));
    _textPaint.render(canvas, timeText, Vector2(game.size.x - 120, 16));
  }
}
