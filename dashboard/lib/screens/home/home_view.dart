library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thicket/thicket.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../theme/insets.dart';
import 'home_controller.dart';

part 'components/audit_logs_panel.dart';
part 'components/entity_detail_card.dart';
part 'components/formatted_response_view.dart';
part 'components/sidebar.dart';
part 'components/sidebar_nav_item.dart';
part 'components/webhook_simulation_widget_state.dart';
part 'components/world_model_explorer_widget_state.dart';

/// View widget for the home screen that renders the Thicket Agent dashboard interface.
///
/// This widget follows strict MVC patterns and composition principles, delegating all UI sub-panels to dedicated widget
/// classes and avoiding helper methods that return widgets.
class HomeView extends StatelessWidget {
  /// Creates the home view linked to the given [state] controller.
  const HomeView(this.state, {super.key});

  /// The parent controller that holds the mutable state and triggers actions.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    switch (state.activeTab) {
      case 'webhooks':
        content = _WebhookSimulationWidget(state: state);
      case 'world_model':
        content = _WorldModelExplorerWidget(state: state);
      case 'logs':
        content = _AuditLogsPanel(state: state);
      default:
        content = Center(child: Text(context.l10n.unknownViewState));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Row(
        children: <Widget>[
          // Sidebar panel
          _Sidebar(state: state),

          // Main screen viewport
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF0F172A),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.medium),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
