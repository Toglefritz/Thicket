part of '../home_view.dart';

/// Detail card of the selected entity showing raw JSON payload, creation/update timestamps.
class _EntityDetailCard extends StatelessWidget {
  const _EntityDetailCard({
    required this.state,
    required this.entity,
  });

  /// The parent controller used for entity mutation operations (update, delete).
  final HomeController state;

  /// The entity whose details are displayed in this card.
  final WorldModelEntity entity;

  /// Presents a confirmation dialog before permanently deleting an entity.
  ///
  /// If the user confirms, the entity is removed from the active collection through the controller and the dialog is
  /// dismissed.
  void _confirmDeleteEntity(BuildContext context, String id) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151D2A),
            title: Text(
              context.l10n.titleDeleteEntity,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              context.l10n.confirmDeleteEntity(id),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  context.l10n.buttonCancel,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await state.deleteEntity(state.selectedCollection!, id);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.l10n.buttonDelete),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String prettyJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(entity.toJson());

    return Padding(
      padding: const EdgeInsets.all(Insets.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.article_outlined,
                    color: Colors.amber,
                    size: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: Insets.xxSmall),
                    child: Text(
                      entity.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => _showEditEntityDialog(context, entity),
                    icon: const Icon(Icons.edit, color: Colors.amber, size: 18),
                    tooltip: context.l10n.tooltipEditProperties,
                  ),
                  IconButton(
                    onPressed: () => _confirmDeleteEntity(context, entity.id),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    tooltip: context.l10n.tooltipDeleteEntity,
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.xxSmall),
            child: Divider(color: Color(0xFF25354A)),
          ),

          // Core details
          Text(
            context.l10n.entityCreatedAt(
              entity.createdAt.toLocal().toString().substring(0, 19),
            ),
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: Insets.xxSmall,
              bottom: Insets.small,
            ),
            child: Text(
              context.l10n.entityModifiedAt(
                entity.updatedAt.toLocal().toString().substring(0, 19),
              ),
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ),

          Text(
            context.l10n.labelRawData,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
              letterSpacing: 1,
            ),
          ),

          // Code Box
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Insets.xxSmall),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Insets.small),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF25354A)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    prettyJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a dialog that allows the user to edit the JSON properties of an existing entity.
  ///
  /// The dialog pre-fills the current entity data and validates that the submitted text is parseable JSON before
  /// persisting the update.
  void _showEditEntityDialog(BuildContext context, WorldModelEntity entity) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final TextEditingController dataController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(entity.data),
    );
    String? localError;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder:
                (
                  BuildContext dCtx,
                  void Function(void Function()) setDialogState,
                ) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF151D2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF25354A)),
                    ),
                    title: Text(
                      localizations.titleEditEntity(entity.id),
                      style: const TextStyle(color: Colors.white),
                    ),
                    content: SizedBox(
                      width: 500,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            localizations.labelProperties,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: Insets.xxSmall,
                              ),
                              child: TextField(
                                controller: dataController,
                                maxLines: null,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                decoration: const InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFF0F172A),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                          if (localError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Insets.xxSmall,
                              ),
                              child: Text(
                                localError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          localizations.buttonCancel,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final Map<String, dynamic> rawData =
                                jsonDecode(
                                      dataController.text,
                                    )
                                    as Map<String, dynamic>;
                            final WorldModelEntity updated = WorldModelEntity(
                              id: entity.id,
                              createdAt: entity.createdAt,
                              updatedAt: entity.updatedAt,
                              data: rawData,
                            );
                            await state.updateEntity(
                              state.selectedCollection!,
                              updated,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          } catch (e) {
                            setDialogState(() {
                              localError = localizations.errorInvalidJson(
                                e.toString(),
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(localizations.buttonUpdate),
                      ),
                    ],
                  );
                },
          );
        },
      ),
    );
  }
}
