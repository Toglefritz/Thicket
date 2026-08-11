import 'package:flutter/material.dart';

import '../../game/berry_collector_game.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen that manages the game lifecycle.
///
/// Owns the [BerryCollectorGame] instance and provides controls for starting and restarting rounds.
class HomeController extends State<HomeRoute> {
  /// The Flame game instance embedded in this screen.
  final BerryCollectorGame game = BerryCollectorGame();

  /// Restarts the game for a new round.
  void restartGame() {
    game.restart();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
