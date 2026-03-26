import 'package:flutter/material.dart';
import 'package:frontend/widgets/dialog/add_order_dialog.dart';

/// Zentraler Knopf um Bestellungen anzulegen.
/// Öffnet den showAddOrderDialog, welches in diesem Kontext das Formular OrderForm öffnet.
class AddOrderButton extends StatelessWidget {
  // Wird aufgerufen, wenn der Dialog erfolgreich abgeschlossen wurde.
  final VoidCallback? onCreated;

  // Optionaler Dialogstarter, der ein Future mit dem Ergebnis der Aktion
  // zurückliefert. Fällt auf den Standarddialog zurück, wenn nicht gesetzt.
  final Future<bool> Function(BuildContext context)? dialogLauncher;

  const AddOrderButton({super.key, this.onCreated, this.dialogLauncher});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final launcher = dialogLauncher ?? showAddOrderDialog;
        final success = await launcher(context);
        if (success && onCreated != null) onCreated!();
      },
      icon: const Icon(Icons.add),
      label: const Text('Bestellung hinzufügen'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
