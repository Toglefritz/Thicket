// dart format off

/// Main entry point for the berry_collector Flutter application.
///
/// This file serves as the application entry point and is responsible only for initializing and running the Flutter
/// app.

import 'package:flutter/material.dart';
import 'app.dart';

/// Application entry point that initializes and runs the Flutter app.
///
/// This function is called when the application starts and creates an instance of the main application widget. All
/// application configuration and setup is handled by the BerryCollector widget in app.dart.
void main() {
  runApp(
    const BerryCollector(),
  );
}
