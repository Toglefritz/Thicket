part of '../home_view.dart';

/// World Model Explorer tab widget.
class _WorldModelExplorerWidget extends StatefulWidget {
  const _WorldModelExplorerWidget({required this.state});

  /// The parent controller that provides collection/entity state and actions.
  final HomeController state;

  @override
  State<_WorldModelExplorerWidget> createState() => _WorldModelExplorerWidgetState();
}

/// State for [_WorldModelExplorerWidget] that renders the collection browser, entity list, and detail panel, and
/// provides dialogs for adding new entities.
class _WorldModelExplorerWidgetState extends State<_WorldModelExplorerWidget> {
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
                  context.l10n.menuWorldModelExplorer,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  context.l10n.worldModelExplorerSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () => widget.state.loadWorldModel(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF151D2A),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF25354A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(context.l10n.buttonRefreshDb),
                ),
                const Padding(padding: EdgeInsets.only(left: Insets.small)),
                ElevatedButton.icon(
                  onPressed: widget.state.collections.isEmpty ? null : () => _showAddEntityDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.l10n.buttonAddEntity),
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
          child: widget.state.collections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.folder_open,
                        size: 48,
                        color: Colors.blueGrey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.small),
                        child: Text(
                          context.l10n.noCollectionsNotice,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xxSmall),
                        child: Text(
                          context.l10n.projectPathNotice(
                            widget.state.projectPath,
                          ),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Left Column - Collections & Entities list
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            context.l10n.labelCollection,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: Insets.xxSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.xxSmall,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151D2A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF25354A),
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: widget.state.selectedCollection,
                                dropdownColor: const Color(0xFF151D2A),
                                isExpanded: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                underline: Container(),
                                items: widget.state.collections
                                    .map(
                                      (String c) => DropdownMenuItem<String>(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (String? val) {
                                  if (val != null) {
                                    widget.state.selectCollection(val);
                                  }
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: Insets.small),
                            child: Text(
                              context.l10n.labelEntities,
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
                              padding: const EdgeInsets.only(
                                top: Insets.xxSmall,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF151D2A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF25354A),
                                  ),
                                ),
                                child: widget.state.entities.isEmpty
                                    ? Center(
                                        child: Text(
                                          context.l10n.noEntitiesNotice,
                                          style: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: widget.state.entities.length,
                                        itemBuilder: (BuildContext ctx, int idx) {
                                          final WorldModelEntity entity = widget.state.entities[idx];
                                          final bool isSelected = widget.state.selectedEntity?.id == entity.id;

                                          return ListTile(
                                            selected: isSelected,
                                            selectedTileColor: Colors.amber.withValues(alpha: 0.1),
                                            title: Text(
                                              entity.id,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.blueGrey[200],
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 13,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            subtitle: Text(
                                              context.l10n.entityUpdatedAtTime(
                                                entity.updatedAt.toLocal().toString().substring(11, 19),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 18,
                                              color: Colors.blueGrey,
                                            ),
                                            onTap: () => widget.state.selectEntity(entity),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer
                    const Padding(
                      padding: EdgeInsets.only(left: Insets.medium),
                    ),

                    // Right Column - Selected Entity Detail View
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF151D2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF25354A)),
                        ),
                        child: widget.state.selectedEntity == null
                            ? Center(
                                child: Text(
                                  context.l10n.selectEntityNotice,
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              )
                            : _EntityDetailCard(
                                state: widget.state,
                                entity: widget.state.selectedEntity!,
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Opens a dialog for creating a new entity in the currently selected collection.
  ///
  /// The user provides an ID and JSON properties. The dialog validates both fields before calling through to the
  /// controller to persist the entity.
  void _showAddEntityDialog(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final TextEditingController idController = TextEditingController();
    final TextEditingController dataController = TextEditingController(
      text: '{\n  "summary": ""\n}',
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
                      localizations.titleAddEntity,
                      style: const TextStyle(color: Colors.white),
                    ),
                    content: SizedBox(
                      width: 500,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            localizations.labelEntityId,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: Insets.xxSmall,
                              bottom: Insets.small,
                            ),
                            child: TextField(
                              controller: idController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                hintText: localizations.hintEntityId,
                                hintStyle: const TextStyle(
                                  color: Colors.blueGrey,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
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
                          final String rawId = idController.text.trim();
                          if (rawId.isEmpty) {
                            setDialogState(() {
                              localError = localizations.errorIdCannotBeEmpty;
                            });
                            return;
                          }
                          try {
                            final Map<String, dynamic> rawData =
                                jsonDecode(
                                      dataController.text,
                                    )
                                    as Map<String, dynamic>;
                            await widget.state.saveNewEntity(
                              widget.state.selectedCollection!,
                              rawId,
                              rawData,
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
                        child: Text(localizations.buttonSave),
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
