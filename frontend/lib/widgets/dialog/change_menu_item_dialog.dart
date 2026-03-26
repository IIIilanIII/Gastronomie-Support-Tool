import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/widgets/form/menu_item_form.dart';

/// Kapselt das Formular MenuItemForm zum Bearbeiten bestehender [menuItem] Einträge.
/// [onCreated] wird weiter an das Formular übergeben, welches diese Funktion nach erfolgreicher backendaktion aufrufen wird
class ChangeMenuItemDialog extends StatelessWidget {
  final MenuItemModel menuItem;
  final VoidCallback onCreated;

  const ChangeMenuItemDialog({
    super.key,
    required this.menuItem,
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return MenuItemForm(
      menuItem: menuItem,
      action: (m, messenger) =>
          appState.backend.updateMenuItem(appState.client, m),
      title: 'Bearbeiten',
      onCreated: onCreated,
      saveButtonText: "Speichern",
      successPrefix: 'Item aktualisiert:',
      errorPrefix: 'Fehler beim aktualisieren von:',
    );
  }
}
