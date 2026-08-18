part of '../home_view.dart';

/// The join project step shown when an existing `.thicket/project.json` is detected.
///
/// Displays the existing project details and offers the user a choice to join the project (obtaining a new API token)
/// or go back and create a new project instead.
class _JoinProjectStep extends StatelessWidget {
  const _JoinProjectStep({required this.state});

  /// Controller for accessing the existing project config and triggering the join flow.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? config = state.existingProjectConfig;
    final String projectName = config?['projectName'] as String? ?? 'Unknown';
    final String projectId = config?['projectId'] as String? ?? 'Unknown';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.group_add_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Text(
            context.l10n.joinProjectHeading,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            context.l10n.joinProjectDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SummaryRow(
                    label: context.l10n.labelProjectName,
                    value: projectName,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.small),
                    child: _SummaryRow(
                      label: context.l10n.labelProjectId,
                      value: projectId,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: FilledButton(
            onPressed: () => unawaited(state.joinExistingProject()),
            child: Text(context.l10n.buttonJoinProject),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: TextButton(
            onPressed: state.reset,
            child: Text(context.l10n.buttonStartOver),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: SelectableText(
              context.l10n.errorGeneric(state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
