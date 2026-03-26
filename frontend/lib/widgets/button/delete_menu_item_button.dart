import 'package:flutter/material.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/widgets/dialog/delete_menu_item_dialog.dart';

/// Zentraler Knopf um MenuItems zulöschen.
/// Öffnet den showDeleteMenuItemDialog, welches in diesem Kontext den Dialog DeleteMenuItemDialog öffnet.
/// Nach erfolgreicher Aktion wird die angzeigte MenuItemliste erneut geladen.
class DeleteMenuItemButton extends StatelessWidget {
  final VoidCallback? onCreated;

  final MenuItemModel menuItem;

  const DeleteMenuItemButton({
    super.key,
    required this.menuItem,
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: IconButton(
        onPressed: () async {
          final success = await showDeleteMenuItemDialog(
            context,
            menuItem: menuItem,
          );
          if (success) onCreated!();
        },
        icon: const Icon(Icons.delete),
      ),
    );
  }

  Future<bool> showDeleteMenuItemDialog(
    BuildContext context, {
    required MenuItemModel menuItem,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteMenuItemDialog(menuItem: menuItem),
    );
    return result ?? false;
  }
}
