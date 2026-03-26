import 'package:flutter/material.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/widgets/dialog/change_menu_item_dialog.dart';
import 'package:frontend/widgets/button/delete_menu_item_button.dart';
import 'package:frontend/app_state.dart';

/// Stellt einen Eintrag [menuItem] in der Menüliste dar. Beim Hover erscheint die
/// Löschaktion, ein Tap auf den Eintrag öffnet den Bearbeitungsdialog.
/// Wenn [menuItem] archiviert ist, wird dieses farblich hervorgehoben.
class MenuItem extends StatefulWidget {
  final MenuItemModel menuItem;

  const MenuItem({super.key, required this.menuItem});

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final menuItem = widget.menuItem;
    final theme = Theme.of(context);

    // Aktualisiert die Menüliste nach einem Dialogabschluss.
    void handleCreated() {
      if (mounted) setState(() {});
      appState.bumpMenuListRefreshToken();
    }

    final baseColor = menuItem.archived
        ? theme.colorScheme.tertiaryContainer.withOpacity(0.9)
        : theme.colorScheme.primaryContainer.withOpacity(0.9);
    final hoverColor = Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.18),
      baseColor,
    );

    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: Card(
        color: _isHovered ? hoverColor : baseColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: ListTile(
          onTap: () async {
            await showDialog<bool>(
              context: context,
              builder: (context) => ChangeMenuItemDialog(
                menuItem: menuItem,
                onCreated: handleCreated,
              ),
            );
          },
          title: Text(
            menuItem.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            menuItem.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isHovered && !menuItem.archived)
                DeleteMenuItemButton(
                  menuItem: menuItem,
                  onCreated: handleCreated,
                ),

              Text(
                '€${menuItem.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
