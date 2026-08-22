/// Console Output Utilities
///
/// Provides ANSI escape code helpers and formatted print functions for rendering a polished CLI experience. All output
/// goes through these helpers so the visual style remains consistent across the entire wizard flow.
///
/// Colors are applied unconditionally; pipe detection or `--no-color` flags could be added later if needed.
library;

import 'dart:io';

// ───────────────────────────────────────────────────────────────────────────── ANSI escape sequences
// ─────────────────────────────────────────────────────────────────────────────

/// Resets all active ANSI formatting back to the terminal default.
const String reset = '\x1B[0m';

/// Enables bold (increased intensity) text.
const String bold = '\x1B[1m';

/// Enables dim (decreased intensity) text, often rendered as a lighter shade.
const String dim = '\x1B[2m';

/// Sets the foreground color to green, used for success indicators.
const String green = '\x1B[32m';

/// Sets the foreground color to cyan, used for step headers and emphasis.
const String cyan = '\x1B[36m';

/// Sets the foreground color to yellow, used for warnings.
const String yellow = '\x1B[33m';

/// Sets the foreground color to red, used for error messages.
const String red = '\x1B[31m';

/// Sets the foreground color to magenta, used for input prompts.
const String magenta = '\x1B[35m';

/// Sets the foreground color to white, used for primary body text.
const String white = '\x1B[37m';

// ───────────────────────────────────────────────────────────────────────────── Formatted output functions
// ─────────────────────────────────────────────────────────────────────────────

/// Prints the Thicket ASCII art banner and tagline.
///
/// Rendered in bold green with a dim tagline and divider below. Called once at the start of the CLI session.
void printBanner() {
  stdout.writeln();
  stdout.writeln('$green$bold'
      '  _____ _     _      _        _   '
      '$reset');
  stdout.writeln('$green$bold'
      ' |_   _| |__ (_) ___| | _____| |_ '
      '$reset');
  stdout.writeln('$green$bold'
      r"   | | | '_ \| |/ __| |/ / _ \ __|"
      '$reset');
  stdout.writeln('$green$bold'
      '   | | | | | | | (__|   <  __/ |_ '
      '$reset');
  stdout.writeln('$green$bold'
      r'   |_| |_| |_|_|\___|_|\_\___|\__|'
      '$reset');
  stdout.writeln();
  stdout.writeln('$dim  Persistent world models for AI agents$reset');
  stdout.writeln('$dim  ──────────────────────────────────────$reset');
  stdout.writeln();
}

/// Prints a numbered step header indicating progress through the wizard.
///
/// Displays as `[step/total] description` in cyan bold for the numbers and white for the description.
void printStep(int step, int total, String description) {
  stdout.writeln('$cyan$bold[$step/$total]$reset $white$description$reset');
}

/// Prints a success message prefixed with a green `[+]` indicator.
///
/// Used to confirm that an operation completed without error.
void printSuccess(String message) {
  stdout.writeln('  $green[+]$reset $message');
}

/// Prints an informational message in dim text.
///
/// Used for status updates and supplementary details that are not errors or successes.
void printInfo(String message) {
  stdout.writeln('  $dim$message$reset');
}

/// Prints an error message prefixed with a red `[x]` indicator.
///
/// Used when an operation has failed and the user needs to take corrective action.
void printError(String message) {
  stdout.writeln('  $red[x]$reset $message');
}

/// Prints a warning message prefixed with a yellow `[!]` indicator.
///
/// Used for non-fatal conditions that the user should be aware of.
void printWarning(String message) {
  stdout.writeln('  $yellow[!]$reset $message');
}

/// Prints a horizontal divider line in dim text.
///
/// Used to visually separate major sections of the wizard output.
void printDivider() {
  stdout.writeln('$dim  ──────────────────────────────────────$reset');
}

// ───────────────────────────────────────────────────────────────────────────── Input prompts
// ─────────────────────────────────────────────────────────────────────────────

/// Prompts the user for a single line of text input.
///
/// Displays a magenta `>` prompt followed by [label]. If [defaultValue] is provided, it is shown in dim brackets and
/// returned when the user presses Enter without typing anything.
///
/// Returns the user's input string, or [defaultValue] if the input was empty and a default was provided, or an empty
/// string if no default was provided and the user entered nothing.
String prompt(String label, {String? defaultValue}) {
  if (defaultValue != null) {
    stdout.write('  $magenta>$reset $label $dim[$defaultValue]$reset: ');
  } else {
    stdout.write('  $magenta>$reset $label: ');
  }
  final String? input = stdin.readLineSync()?.trim();
  if (input == null || input.isEmpty) {
    return defaultValue ?? '';
  }
  return input;
}

/// Prompts the user to choose from a numbered list of options.
///
/// Displays [label] followed by a numbered list of [options]. The user enters the number corresponding to their choice.
///
/// Returns the 1-based index of the selected option, or `0` if the input was invalid (not a number, or out of range).
int promptChoice(String label, List<String> options) {
  stdout.writeln('  $magenta>$reset $label');
  for (int i = 0; i < options.length; i++) {
    stdout.writeln('    $cyan${i + 1}.$reset ${options[i]}');
  }
  stdout.write('  $magenta>$reset Choice: ');
  final String? input = stdin.readLineSync()?.trim();
  final int? choice = int.tryParse(input ?? '');
  if (choice == null || choice < 1 || choice > options.length) {
    return 0;
  }
  return choice;
}
