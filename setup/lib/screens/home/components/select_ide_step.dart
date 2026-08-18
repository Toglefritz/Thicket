part of '../home_view.dart';

/// The IDE selection step where the user chooses which editor to configure with the Thicket MCP server.
///
/// Presents a list of supported IDEs as selectable cards. On selection, the controller writes the appropriate MCP
/// configuration file and advances to the completion step.
class _SelectIdeStep extends StatelessWidget {
  const _SelectIdeStep({required this.state});

  /// Controller for triggering MCP installation on IDE selection.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          context.l10n.selectIdeHeading,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            context.l10n.selectIdeDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Column(
            children: IdeType.values
                .map(
                  (IdeType ide) => _IdeOptionCard(
                    ide: ide,
                    onSelected: () => unawaited(state.installMcpServer(ide)),
                  ),
                )
                .toList(),
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
