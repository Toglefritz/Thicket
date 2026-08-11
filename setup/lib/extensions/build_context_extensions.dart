import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Convenience getters on [BuildContext] for commonly accessed inherited values like the current theme and localization
/// strings.
extension BuildContextExtensions on BuildContext {
  /// The nearest [ThemeData] from the widget tree.
  ThemeData get theme => Theme.of(this);

  /// The current localization strings resolved from the nearest [AppLocalizations] ancestor.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
