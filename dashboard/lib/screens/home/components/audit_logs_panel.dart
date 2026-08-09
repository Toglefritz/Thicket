part of '../home_view.dart';

/// Audit log stream display panel.
class _AuditLogsPanel extends StatelessWidget {
  const _AuditLogsPanel({required this.state});

  /// The parent controller that provides access to the audit log entries.
  final HomeController state;

  /// Returns a color based on the type of audit log action.
  ///
  /// Maps action keywords to semantic colors: red for errors/failures, green for successes, amber for creation/remember
  /// operations, and cyan as the default for other action types.
  Color _getLogBadgeColor(String action) {
    if (action.contains('error') || action.contains('failure')) {
      return Colors.red;
    } else if (action.contains('success')) {
      return const Color(0xFF10B981);
    } else if (action.contains('create') || action.contains('remember')) {
      return Colors.amber;
    } else {
      return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.menuAuditLogStream,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  context.l10n.auditLogSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: Insets.small),
          child: Divider(color: Color(0xFF25354A)),
        ),
        Expanded(
          child: state.auditLogs.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.noLogsNotice,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: state.auditLogs.length,
                  itemBuilder: (BuildContext ctx, int idx) {
                    final Map<String, dynamic> log = state.auditLogs[idx];
                    final String timestamp = log['timestamp'] as String;
                    final String action = log['action'] as String;
                    final String message = log['message'] as String;
                    final Map<String, dynamic>? meta = log['metadata'] as Map<String, dynamic>?;

                    return Card(
                      color: const Color(0xFF151D2A),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: Insets.small),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF25354A)),
                      ),
                      child: ExpansionTile(
                        iconColor: Colors.amber,
                        collapsedIconColor: Colors.blueGrey,
                        title: Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getLogBadgeColor(
                                  action,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getLogBadgeColor(action),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                action.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getLogBadgeColor(action),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Insets.small,
                                ),
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              timestamp.substring(11, 19),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        children: <Widget>[
                          if (meta != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(Insets.small),
                              color: const Color(0xFF0F172A),
                              child: Text(
                                const JsonEncoder.withIndent(
                                  '  ',
                                ).convert(meta),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
