part of '../home_view.dart';

/// The initial sign-in step with a Google sign-in button.
///
/// Displays a welcome message explaining Thicket and provides the sign-in button that triggers the OAuth2 flow.
class _SignInStep extends StatelessWidget {
  const _SignInStep({required this.state});

  /// Controller for accessing sign-in state and triggering the flow.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.park_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Text(
            context.l10n.welcomeHeading,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            context.l10n.welcomeDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xLarge),
          child: state.isSigningIn
              ? Column(
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.medium),
                      child: Text(context.l10n.signInWaiting),
                    ),
                  ],
                )
              : FilledButton.icon(
                  onPressed: state.signIn,
                  icon: const Icon(Icons.login),
                  label: Text(context.l10n.buttonSignIn),
                ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Text(
              context.l10n.errorGeneric(state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
