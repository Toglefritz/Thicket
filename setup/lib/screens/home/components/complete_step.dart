part of '../home_view.dart';

/// The completion step showing project registration details and MCP configuration status.
///
/// Displays the project ID, API token, agent URL, and the path to the MCP configuration file that was written for the
/// selected IDE.
class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.state});

  /// Controller for accessing the registration result and MCP config path.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final RegistrationResult? result = state.registrationResult;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.check_circle_outline,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Text(
            context.l10n.completeHeading,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            context.l10n.completeDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (result != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.large),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Insets.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SummaryRow(
                      label: context.l10n.labelProjectId,
                      value: result.projectId,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.small),
                      child: _SummaryRow(
                        label: context.l10n.labelAgentUrl,
                        value: result.agentUrl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (state.selectedIde != null && state.mcpConfigPath != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Insets.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SummaryRow(
                      label: context.l10n.labelIde,
                      value: state.selectedIde!.displayName,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.small),
                      child: _SummaryRow(
                        label: context.l10n.labelMcpConfig,
                        value: state.mcpConfigPath!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xLarge),
          child: FilledButton(
            onPressed: state.reset,
            child: Text(context.l10n.buttonDone),
          ),
        ),
      ],
    );
  }
}
