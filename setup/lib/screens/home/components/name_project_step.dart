part of '../home_view.dart';

/// The project configuration step with fields for project name and directory path.
///
/// Collects the project name and (on desktop) the directory where `.thicket/project.json` will be written. On web, only
/// the project name is required since file-system writes are not possible.
class _NameProjectStep extends StatelessWidget {
  const _NameProjectStep({required this.state});

  /// Controller for accessing text controllers and triggering registration.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          context.l10n.nameProjectHeading,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            state.isRunningOnWeb
                ? 'Give your project a name. After registration you will receive configuration files to add to your project.'
                : context.l10n.nameProjectDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: TextField(
            controller: state.projectNameController,
            decoration: InputDecoration(
              labelText: context.l10n.labelProjectName,
              border: const OutlineInputBorder(),
            ),
            textInputAction: state.isRunningOnWeb ? TextInputAction.done : TextInputAction.next,
            onSubmitted: state.isRunningOnWeb ? (_) => state.registerProject() : null,
          ),
        ),
        // Only show the project path field on desktop platforms.
        if (!state.isRunningOnWeb)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: TextField(
              controller: state.projectPathController,
              decoration: InputDecoration(
                labelText: context.l10n.labelProjectPath,
                hintText: '/path/to/your/project',
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => state.registerProject(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: FilledButton(
            onPressed: state.registerProject,
            child: Text(context.l10n.buttonRegister),
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
