part of '../home_view.dart';

/// The completion step showing project registration details and MCP configuration status.
///
/// On desktop, displays the project ID, API token, agent URL, and the path to the MCP configuration file that was
/// written for the selected IDE.
///
/// On web, displays the configuration JSON that the user should copy into their project directory, since file-system
/// writes are not available from the browser.
class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.state});

  /// Controller for accessing the registration result and MCP config path.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    if (state.isRunningOnWeb) {
      return _buildWebCompletion(context);
    }
    return _buildDesktopCompletion(context);
  }

  Widget _buildDesktopCompletion(BuildContext context) {
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

  Widget _buildWebCompletion(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
              'Copy the files below into your project to complete setup.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          // project.json
          Padding(
            padding: const EdgeInsets.only(top: Insets.large),
            child: _CopyableConfigCard(
              title: '.thicket/project.json',
              content: state.projectConfigJson,
              onCopy: () => state.copyToClipboard(context, state.projectConfigJson),
            ),
          ),
          // credentials.json
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: _CopyableConfigCard(
              title: '.thicket/credentials.json',
              content: state.credentialsJson,
              onCopy: () => state.copyToClipboard(context, state.credentialsJson),
            ),
          ),
          // Reminder about gitignore
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(Insets.medium),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: Insets.small),
                    Expanded(
                      child: Text(
                        'Remember to add .thicket/credentials.json to your .gitignore.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
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
      ),
    );
  }
}

/// A card displaying a configuration file with a copy button.
///
/// Used on the web completion step to show JSON that the user should save to their project.
class _CopyableConfigCard extends StatelessWidget {
  const _CopyableConfigCard({
    required this.title,
    required this.content,
    required this.onCopy,
  });

  /// The file path shown as the card title.
  final String title;

  /// The JSON content to display.
  final String content;

  /// Callback when the copy button is pressed.
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy to clipboard',
                  onPressed: onCopy,
                ),
              ],
            ),
            const SizedBox(height: Insets.small),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Insets.medium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
