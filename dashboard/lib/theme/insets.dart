import 'package:flutter/material.dart';

/// Provides standardized spacing constants used for [Padding] and layout widgets.
///
/// These values follow a consistent geometric scale to maintain visual rhythm across the application. Use these instead
/// of ad-hoc numeric literals.
class Insets {
  /// 4 logical pixels. Used for minimal separation between tightly related elements.
  static const double xxSmall = 4;

  /// 8 logical pixels. Used for compact internal padding within dense components.
  static const double xSmall = 8;

  /// 16 logical pixels. The standard spacing unit for most element separation.
  static const double small = 16;

  /// 24 logical pixels. Used for section-level separation and outer card padding.
  static const double medium = 24;

  /// 32 logical pixels. Used for major layout divisions and page-level margins.
  static const double large = 32;

  /// 64 logical pixels. Used for prominent visual breaks or hero spacing.
  static const double xLarge = 64;

  /// 96 logical pixels. Used for extreme spacing in splash or onboarding layouts.
  static const double xxLarge = 96;
}
