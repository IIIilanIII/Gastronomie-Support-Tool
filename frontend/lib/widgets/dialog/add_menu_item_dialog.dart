import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/widgets/form/menu_item_form.dart';
import '../../app_state.dart';

/// Kapselt das Formular zum Anlegen eines MenuItems für die Wiederverwendung.
/// Erstellt ein neues MenuItemModel, welches mit der aufgerufenen MenuItemForm bearbeitet werden muss.
/// [onCreated] wird nach erfolgreicher Aktion aufgerufen.
/// Zeigt Fehlermeldungen als Snackbar dem Benutzer an.
class AddMenuItemDialog extends StatelessWidget {
  final VoidCallback onCreated;

  const AddMenuItemDialog({super.key, required this.onCreated});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return MenuItemForm(
      menuItem: MenuItemModel(
        id: null,
        name: '',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      ),
      action: (menuItem, messenger) async {
        try {
          return await appState.backend.createMenuItem(
            appState.client,
            menuItem,
          );
        } on HttpException catch (e) {
          //Handle 403 StatusCode aus Backend
          messenger.showSnackBar(SnackBar(content: Text(e.message)));
          return false;
        }
      },
      title: 'Neues Menü‑Item',
      saveButtonText: 'Erstellen',
      successPrefix: 'Neues Item hinzugefügt:',
      errorPrefix: 'Fehler beim Erstellen des Items',
      onCreated: onCreated,
    );
  }
}

/// Öffnet den Dialog zum Anlegen eines Menüeintrags und stößt den Backend-Call an.
/// Liefert `true`, wenn das Backend mit Status 204 antwortet, sonst `false`.
Future<bool> showAddMenuItemDialog(BuildContext parentContext) async {
  final appState = AppStateScope.of(parentContext);
  final resultCompleter = Completer<bool>();
  bool success = false;

  await showDialog<void>(
    context: parentContext,
    barrierDismissible: false,
    builder: (dialogContext) => AddMenuItemDialog(
      onCreated: () {
        success = true;
        appState.bumpMenuListRefreshToken();
      },
    ),
  );

  resultCompleter.complete(success);
  return resultCompleter.future;
}
