part of '../home_view.dart';

/// Widget that decodes and renders formatted JSON reasoning.
class _FormattedResponseView extends StatelessWidget {
  const _FormattedResponseView({required this.response});

  /// The raw JSON string returned by the agent webhook endpoint.
  final String response;

  @override
  Widget build(BuildContext context) {
    try {
      final Map<String, dynamic> data = jsonDecode(response) as Map<String, dynamic>;
      final String? summary = data['summary'] as String?;
      if (summary != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: Insets.xxSmall),
                  child: Text(
                    context.l10n.webhookSuccessTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.small),
              child: Text(
                summary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Insets.medium),
              child: Divider(color: Color(0xFF25354A)),
            ),
            Text(
              context.l10n.labelRawPayloadResponse,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                fontSize: 10,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.xxSmall),
              child: Text(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.blueGrey,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      }
    } catch (_) {}

    return Text(
      response,
      style: const TextStyle(
        fontFamily: 'monospace',
        color: Colors.redAccent,
        fontSize: 12,
      ),
    );
  }
}
