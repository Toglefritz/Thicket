part of '../home_view.dart';

/// A key-value row displaying a label and value side by side.
///
/// Used in the completion summary card to show the project ID and agent URL.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  /// The label text displayed before the value.
  final String label;

  /// The value text displayed after the label.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
