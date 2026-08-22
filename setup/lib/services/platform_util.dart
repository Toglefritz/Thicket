/// Utilities for detecting the current platform at runtime.
///
/// Flutter's `kIsWeb` constant from `package:flutter/foundation.dart` is the canonical way to check if the app is
/// running in a browser. This file re-exports it alongside a convenience getter so service code does not need to import
/// Flutter's foundation library directly.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the app is currently running in a web browser.
///
/// This is a compile-time constant on web and false on all native platforms.
const bool isWeb = kIsWeb;
