import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';

/// Bestätigt das Löschen eines [menuItem] und zeigt entsprechende Statusmeldungen nach der Aktion an.
class DeleteMenuItemDialog extends StatelessWidget {
  final MenuItemModel menuItem;

  const DeleteMenuItemDialog({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final parentMessenger = ScaffoldMessenger.of(context);
    final itemName = menuItem.name;
    return AlertDialog(
      title: const Text('Eintrag löschen?'),
      content: Text('Möchtest du "$itemName" wirklich löschen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            bool success = false;
            try {
              success = await appState.backend
                  .deleteMenuItem(appState.client, menuItem)
                  .timeout(const Duration(seconds: 10));
            } on TimeoutException catch (_) {
              success = false;
              showActionMessage(parentMessenger, 'Request times out');
              appState.setConnectionStatus(ConnectionStatus.offline);
            } catch (e) {
              success = false;
              showActionMessage(parentMessenger, e.toString());
              appState.setConnectionStatus(ConnectionStatus.offline);
            }
            if (!context.mounted) return;

            if (success) {
              appState.setConnectionStatus(ConnectionStatus.online);
              showActionMessage(parentMessenger, 'Item gelöscht: $itemName');
            } else {
              appState.setConnectionStatus(ConnectionStatus.offline);
              showActionMessage(
                parentMessenger,
                'Fehler beim löschen von $itemName',
              );
            }
            Navigator.of(context).pop(success);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Löschen'),
        ),
      ],
    );
  }

  /// Zeigt eine Snackbar mit dem übergebenen Text an.
  void showActionMessage(
    ScaffoldMessengerState parentMessenger,
    String message,
  ) {
    parentMessenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
