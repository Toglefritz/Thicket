import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/berry_collector_game.dart';
import 'home_controller.dart';

/// View widget for the home screen that embeds the Flame game.
///
/// Displays the game as a full-screen widget with an overlay for the game-over state.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance that manages the game lifecycle.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<BerryCollectorGame>(
        game: state.game,
        overlayBuilderMap: <String,
            Widget Function(BuildContext, BerryCollectorGame)>{
          'gameOver': (BuildContext context, BerryCollectorGame game) {
            return _GameOverOverlay(state: state);
          },
        },
      ),
    );
  }
}

/// Overlay displayed when the game round ends.
class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.state});

  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.white.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Time\'s up!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Score: ${state.game.score}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: FilledButton(
                  onPressed: () {
                    state.restartGame();
                    state.game.overlays.remove('gameOver');
                  },
                  child: const Text('Play Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
