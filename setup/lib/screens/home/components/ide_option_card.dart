part of '../home_view.dart';

/// A selectable card representing a single IDE option.
///
/// Displays the IDE name and the relative path where the MCP config will be written. Tapping the card triggers the
/// installation for that IDE.
class _IdeOptionCard extends StatelessWidget {
  const _IdeOptionCard({
    required this.ide,
    required this.onSelected,
  });

  /// The IDE this card represents.
  final IdeType ide;

  /// Callback invoked when the user taps this card.
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Insets.xSmall),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(Insets.small),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.code,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: Insets.small),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          ide.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          ide.configRelativePath,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
