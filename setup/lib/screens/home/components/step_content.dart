part of '../home_view.dart';

/// Routes to the correct step widget based on the current wizard state.
///
/// This widget replaces a function-returning-widget pattern. It reads the current step from the controller and renders
/// the appropriate step component.
class _StepContent extends StatelessWidget {
  const _StepContent({required this.state});

  /// Controller for reading the current step.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    switch (state.currentStep) {
      case SetupStep.signIn:
        return _SignInStep(state: state);
      case SetupStep.nameProject:
        return _NameProjectStep(state: state);
      case SetupStep.registering:
        return const _RegisteringStep();
      case SetupStep.complete:
        return _CompleteStep(state: state);
    }
  }
}
