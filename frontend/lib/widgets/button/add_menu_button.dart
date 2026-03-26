import 'package:flutter/material.dart';
import '../dialog/add_menu_item_dialog.dart';

/// Zentraler Knopf um Menuitems anzulegen.
/// Öffnet den showAddMenuItemDialog, welches in diesem Kontext das Formular MenuItemForm öffnet.
/// Nach erfolgreicher Aktion wird die angzeigte MenuItemliste erneut geladen.
class AddMenuButton extends StatelessWidget {
  // Wird aufgerufen, sobald der Dialog erfolgreich bestätigt wurde.
  final VoidCallback? onCreated;

  // Optionaler Dialogstarter, der ein Future mit dem Ergebnis der Aktion
  // zurückliefert. Nutzt den Standarddialog, wenn nichts übergeben wird.
  final Future<bool> Function(BuildContext context)? dialogLauncher;

  const AddMenuButton({super.key, this.onCreated, this.dialogLauncher});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final launcher = dialogLauncher ?? showAddMenuItemDialog;
        final success = await launcher(context);
        if (success && onCreated != null) onCreated!();
      },
      icon: const Icon(Icons.add),
      label: const Text('Menü-Item hinzufügen'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
