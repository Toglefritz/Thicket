import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/thicket_api_service.dart';
import '../../theme/insets.dart';
import 'home_controller.dart';

/// View widget for the setup wizard screen.
///
/// Renders the appropriate step content based on the controller's current state. The flow is linear: sign in, name
/// the project, wait for registration, see the result.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance providing state and actions.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(Insets.large),
            child: _buildStepContent(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, AppLocalizations l10n) {
    switch (state.currentStep) {
      case SetupStep.signIn:
        return _SignInStep(state: state, l10n: l10n);
      case SetupStep.nameProject:
        return _NameProjectStep(state: state, l10n: l10n);
      case SetupStep.registering:
        return _RegisteringStep(l10n: l10n);
      case SetupStep.complete:
        return _CompleteStep(state: state, l10n: l10n);
    }
  }
}

/// The sign-in step with a Google sign-in button.
class _SignInStep extends StatelessWidget {
  const _SignInStep({required this.state, required this.l10n});

  final HomeController state;
  final AppLocalizations l10n;

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
            l10n.welcomeHeading,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.welcomeDescription,
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
                      child: Text(l10n.signInWaiting),
                    ),
                  ],
                )
              : FilledButton.icon(
                  onPressed: state.signIn,
                  icon: const Icon(Icons.login),
                  label: Text(l10n.buttonSignIn),
                ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Text(
              l10n.errorGeneric(state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

/// The project naming step with a text field and continue button.
class _NameProjectStep extends StatelessWidget {
  const _NameProjectStep({required this.state, required this.l10n});

  final HomeController state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          l10n.nameProjectHeading,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            l10n.nameProjectDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: TextField(
            controller: state.projectNameController,
            decoration: InputDecoration(
              labelText: l10n.labelProjectName,
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
            child: Text(l10n.buttonRegister),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Text(
              l10n.errorGeneric(state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

/// A simple spinner shown while registration is in progress.
class _RegisteringStep extends StatelessWidget {
  const _RegisteringStep({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const CircularProgressIndicator(),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Text(
            l10n.registeringStatus,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// The completion step showing the project ID, token, and agent URL.
class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.state, required this.l10n});

  final HomeController state;
  final AppLocalizations l10n;

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
            l10n.completeHeading,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            l10n.completeDescription,
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
                      label: l10n.labelProjectId,
                      value: result.projectId,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.small),
                      child: _SummaryRow(
                        label: l10n.labelAgentUrl,
                        value: result.agentUrl,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.small),
                      child: _CopyableRow(
                        label: l10n.labelApiToken,
                        value: result.apiToken,
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
            onPressed: () => unawaited(Navigator.of(context).maybePop()),
            child: Text(l10n.buttonDone),
          ),
        ),
      ],
    );
  }
}

/// A key-value row in the completion summary card.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// A summary row with a copy-to-clipboard button for sensitive values like API tokens.
class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            '${value.substring(0, 8)}...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: value)));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          tooltip: 'Copy',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
