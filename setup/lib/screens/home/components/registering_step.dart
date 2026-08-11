part of '../home_view.dart';

/// A loading indicator shown while the project registration request is in progress.
class _RegisteringStep extends StatelessWidget {
  const _RegisteringStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const CircularProgressIndicator(),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Text(
            context.l10n.registeringStatus,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
