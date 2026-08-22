import '../models/ide_type.dart';

/// No-op implementation of [HookInstallerService] for web.
///
/// Agent hook installation requires writing files and running chmod, which are not possible on web. The controller
/// skips the IDE selection step entirely on web, so this method should not be called.
class HookInstallerService {
  const HookInstallerService._();

  /// No-op on web.
  static void install({
    required IdeType ide,
    required String projectPath,
  }) {}
}
