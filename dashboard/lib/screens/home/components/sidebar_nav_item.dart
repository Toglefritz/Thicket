part of '../home_view.dart';

/// Navigation menu item widget inside the sidebar.
class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.state,
    required this.id,
    required this.label,
    required this.icon,
  });

  /// The parent controller that provides access to shared state and actions.
  final HomeController state;

  /// Unique identifier for this navigation tab, used to determine active state.
  final String id;

  /// Display text rendered next to the icon in the sidebar.
  final String label;

  /// Icon displayed to the left of the label in the navigation item.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = state.activeTab == id;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xxSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => state.setActiveTab(id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: Insets.small,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0x1AFFB300) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0x4DFFB300) : Colors.transparent,
                width: 0.5,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: isSelected ? Colors.amber : Colors.blueGrey,
                  size: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: Insets.small),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blueGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
