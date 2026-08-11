/// View components for the setup wizard home screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setup/extensions/build_context_extensions.dart';

import '../../services/thicket_api_service.dart';
import '../../theme/insets.dart';
import 'home_controller.dart';

part 'components/complete_step.dart';
part 'components/copyable_row.dart';
part 'components/name_project_step.dart';
part 'components/registering_step.dart';
part 'components/sign_in_step.dart';
part 'components/step_content.dart';
part 'components/summary_row.dart';

/// View widget for the setup wizard screen.
///
/// Renders the appropriate step content based on the controller's current state. The flow is linear: sign in, name
/// the project, wait for registration, see the result.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance providing state and actions.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(Insets.large),
            child: _StepContent(state: state),
          ),
        ),
      ),
    );
  }
}
