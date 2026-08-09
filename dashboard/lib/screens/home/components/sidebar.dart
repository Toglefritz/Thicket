part of '../home_view.dart';

/// The left-hand navigation sidebar.
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});

  /// The parent controller that provides access to project state, connection status, and navigation actions.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xFF090D16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Sidebar Header / Logo
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Insets.medium,
                horizontal: Insets.small,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color(0x4DFFB300),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: Insets.small),
                    child: Text(
                      context.l10n.consoleTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Connection & Config Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.small),
              child: Container(
                padding: const EdgeInsets.all(Insets.small),
                decoration: BoxDecoration(
                  color: const Color(0xFF151D2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF25354A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.labelProjectPath,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.xxSmall),
                      child: TextField(
                        controller: TextEditingController(
                          text: state.projectPath,
                        ),
                        onSubmitted: state.setProjectPath,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Icon(
                            state.isProjectPathValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            color: state.isProjectPathValid ? const Color(0xFF10B981) : Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.small),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            context.l10n.labelAgentRuntime,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: state.isAgentOnline ? const Color(0x1A10B981) : const Color(0x1AFF5252),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: state.isAgentOnline ? const Color(0xFF10B981) : const Color(0xFFFF5252),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              state.isAgentOnline ? context.l10n.statusOnline : context.l10n.statusOffline,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: state.isAgentOnline ? const Color(0xFF10B981) : const Color(0xFFFF5252),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: Insets.small),
              child: Divider(color: Color(0xFF25354A), height: 1),
            ),

            // Sidebar Menu Navigation Items
            _SidebarNavItem(
              state: state,
              id: 'webhooks',
              label: context.l10n.menuWebhookSimulator,
              icon: Icons.electrical_services_rounded,
            ),
            _SidebarNavItem(
              state: state,
              id: 'world_model',
              label: context.l10n.menuWorldModelExplorer,
              icon: Icons.dns_rounded,
            ),
            _SidebarNavItem(
              state: state,
              id: 'logs',
              label: context.l10n.menuAuditLogStream,
              icon: Icons.history_edu_rounded,
            ),

            const Spacer(),

            // Web indicator notice if running inside web browser
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.all(Insets.small),
                child: Container(
                  padding: const EdgeInsets.all(Insets.small),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFB300),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x33FFB300)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 16,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: Insets.xxSmall),
                          child: Text(
                            context.l10n.webSimulationNotice,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
