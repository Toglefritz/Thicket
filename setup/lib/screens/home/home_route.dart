import 'package:flutter/material.dart';

import 'home_controller.dart';

/// Route widget for the setup wizard screen.
///
/// This is the sole screen in the app. It presents a linear wizard flow that guides the user through Google sign-in
/// and GCP project provisioning.
class HomeRoute extends StatefulWidget {
  /// Creates the home route widget.
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
