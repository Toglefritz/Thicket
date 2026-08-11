import 'package:flutter/material.dart';

import 'home_controller.dart';

/// Route widget for the game screen.
///
/// Entry point to the Berry Collector game. The game is embedded as a full-screen Flame widget.
class HomeRoute extends StatefulWidget {
  /// Creates the home route widget.
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
