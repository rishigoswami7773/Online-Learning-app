import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/admin_menu_controller.dart';
import '../../utils/theme_helper.dart';

/// Advanced Admin Navigation Widget with menu management
class AdminNavigationPanel extends StatefulWidget {
  final VoidCallback onLogout;
  final String? currentRoute;
  final bool isExtended;

  const AdminNavigationPanel({
    super.key,
    required this.onLogout,
    this.currentRoute,
    this.isExtended = true,
  });

  @override
  State<AdminNavigationPanel> createState() => _AdminNavigationPanelState();
}

class _AdminNavigationPanelState extends State<AdminNavigationPanel> {
  late int _selectedIndex;
  final AdminMenuController _menuController = AdminMenuController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = _menuController.getMenuIndexByRoute(
      widget.currentRoute ?? '',
    );
    if (_selectedIndex < 0) _selectedIndex = 0;
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    GoRouter.of(context).go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isExtended ? 260 : 80,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(right: BorderSide(color: context.borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (widget.isExtended) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'v1.0',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Menu Items
            Expanded(
              child: ListView.builder(
                itemCount: AdminMenuController.adminMenuItems.length,
                itemBuilder: (context, index) {
                  final item = AdminMenuController.adminMenuItems[index];
                  final isSelected = _selectedIndex == index;

                  return Tooltip(
                    message: item.tooltip ?? item.label,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? context.brandSoftColor.withValues(alpha: 0.8)
                            : Colors.transparent,
                      ),
                      child: ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.transparent,
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : context.textSecondary,
                          size: 22,
                        ),
                        title: widget.isExtended
                            ? Text(
                                item.label,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : context.textPrimary,
                                ),
                              )
                            : null,
                        onTap: () => _navigateTo(item.route, index),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: widget.isExtended ? 12 : 0,
                          vertical: 4,
                        ),
                        minLeadingWidth: 24,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Divider
            const Divider(height: 1, thickness: 1),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.isDark
                      ? Colors.red.withValues(alpha: 0.12)
                      : Colors.red.shade50,
                  border: Border.all(
                    color: context.isDark
                        ? Colors.red.withValues(alpha: 0.25)
                        : Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                          if (widget.isExtended) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
