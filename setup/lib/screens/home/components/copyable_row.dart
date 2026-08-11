part of '../home_view.dart';

/// A summary row with a copy-to-clipboard button for sensitive values.
///
/// Truncates the displayed value and provides a copy button to place the full value on the clipboard.
class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value});

  /// The label text displayed before the value.
  final String label;

  /// The full value to copy. Only the first 8 characters are displayed.
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
