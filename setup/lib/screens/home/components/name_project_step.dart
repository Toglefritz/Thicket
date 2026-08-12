part of '../home_view.dart';

/// The project configuration step with fields for project name and directory path.
///
/// Collects the project name and the directory where `.thicket/project.json` will be written.
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
            context.l10n.nameProjectDescription,
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
            textInputAction: TextInputAction.next,
          ),
        ),
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
