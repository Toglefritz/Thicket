part of '../home_view.dart';

/// Webhook testing and simulator control widget.
class _WebhookSimulationWidget extends StatefulWidget {
  const _WebhookSimulationWidget({required this.state});

  /// The parent controller that provides webhook dispatch and event state.
  final HomeController state;

  @override
  State<_WebhookSimulationWidget> createState() => _WebhookSimulationWidgetState();
}

/// State for [_WebhookSimulationWidget] that manages template selection, payload editing, and event dispatch to the
/// agent server.
class _WebhookSimulationWidgetState extends State<_WebhookSimulationWidget> {
  /// Controller for the editable JSON payload text field.
  final TextEditingController _payloadController = TextEditingController();

  /// The currently selected event template key (e.g. 'github', 'slack', 'filesystem').
  String _selectedTemplate = 'github';

  /// Predefined webhook event templates keyed by source identifier.
  ///
  /// Each template contains the source, event type, and a sample payload that populates the JSON editor when selected.
  final Map<String, Map<String, dynamic>> _templates = <String, Map<String, dynamic>>{
    'github': <String, dynamic>{
      'source': 'github',
      'eventType': 'push',
      'payload': <String, dynamic>{
        'repository': 'thicket',
        'branch': 'main',
        'commits': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '98f7a6b5',
            'message': 'Implement type annotations on core entities and cleanup linter errors',
            'added': <String>[
              'world_model/lib/src/models/core/world_model_entity.dart',
            ],
            'modified': <String>['agent/bin/server.dart'],
            'removed': <String>[],
          },
        ],
      },
    },
    'slack': <String, dynamic>{
      'source': 'slack',
      'eventType': 'message',
      'payload': <String, dynamic>{
        'channel': '#development',
        'user': 'scotthatfield',
        'text': 'Agent, list all beliefs about docker usage and forget them',
      },
    },
    'filesystem': <String, dynamic>{
      'source': 'filesystem',
      'eventType': 'modify',
      'payload': <String, dynamic>{
        'file': 'README.md',
        'action': 'modified',
        'timestamp': '2026-08-08T22:15:00Z',
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _applyTemplate('github');
  }

  /// Applies the selected template to the JSON payload editor.
  ///
  /// Replaces the text field content with the pretty-printed payload from the chosen template and updates the dropdown
  /// selection state.
  void _applyTemplate(String key) {
    setState(() {
      _selectedTemplate = key;
      final Map<String, dynamic> template = _templates[key]!;
      _payloadController.text = const JsonEncoder.withIndent('  ').convert(
        template['payload'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.menuWebhookSimulator,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  context.l10n.webhookSimulatorSubtitle,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Left Column - Input Panel
              Expanded(
                flex: 4,
                child: Card(
                  color: const Color(0xFF151D2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF25354A)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.small),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              context.l10n.labelEventTemplate,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                letterSpacing: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: Insets.small,
                              ),
                              child: DropdownButton<String>(
                                value: _selectedTemplate,
                                dropdownColor: const Color(0xFF151D2A),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                underline: Container(),
                                items: <DropdownMenuItem<String>>[
                                  DropdownMenuItem<String>(
                                    value: 'github',
                                    child: Text(
                                      context.l10n.templateGithubPush,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'slack',
                                    child: Text(
                                      context.l10n.templateSlackQuery,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'filesystem',
                                    child: Text(
                                      context.l10n.templateFilesystemChange,
                                    ),
                                  ),
                                ],
                                onChanged: (String? val) {
                                  if (val != null) {
                                    _applyTemplate(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.xSmall),
                          child: Text(
                            context.l10n.labelJsonPayload,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: Insets.xxSmall),
                            child: TextField(
                              controller: _payloadController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF25354A),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.small),
                          child: ElevatedButton(
                            onPressed: widget.state.isSendingEvent
                                ? null
                                : () async {
                                    try {
                                      final Map<String, dynamic> payload =
                                          jsonDecode(
                                                _payloadController.text,
                                              )
                                              as Map<String, dynamic>;
                                      await widget.state.sendWebhookEvent(
                                        source: _templates[_selectedTemplate]!['source'] as String,
                                        eventType: _templates[_selectedTemplate]!['eventType'] as String,
                                        payload: payload,
                                      );
                                    } catch (e) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.l10n.errorInvalidJsonPayload(
                                              e.toString(),
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withValues(
                                alpha: 0.3,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: widget.state.isSendingEvent
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    context.l10n.buttonDispatchWebhook,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Spacer
              const Padding(padding: EdgeInsets.only(left: Insets.medium)),

              // Right Column - Response & Reasoning
              Expanded(
                flex: 5,
                child: Card(
                  color: const Color(0xFF151D2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF25354A)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.small),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          context.l10n.labelAgentReasoning,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 1,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: Insets.small),
                            child: Container(
                              padding: const EdgeInsets.all(Insets.small),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF25354A),
                                ),
                              ),
                              child: widget.state.lastWebhookResponse == null
                                  ? Center(
                                      child: Text(
                                        context.l10n.noWebhookSentNotice,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: _FormattedResponseView(
                                        response: widget.state.lastWebhookResponse!,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
