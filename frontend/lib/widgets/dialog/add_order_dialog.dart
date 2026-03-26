import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/widgets/form/order_form.dart';
import 'package:frontend/models/order_item_model.dart';

/// Öffnet den Dialog zum Anlegen einer Bestellung und führt den Backend-Call aus.
/// Übergibt an das Bestellungsformular Funktionen, die Tische und MenuItems laden können, um diese in der OrderForm verwenden zu können.
/// Gibt `true` zurück, wenn das Backend Erfolg meldet, sonst `false`.
Future<bool> showAddOrderDialog(BuildContext parentContext) async {
  final appState = AppStateScope.of(parentContext);
  final parentNavigator = Navigator.of(parentContext);
  final parentMessenger = ScaffoldMessenger.of(parentContext);
  final resultCompleter = Completer<bool>();

  final order = OrderModel(
    id: null,
    items: <OrderItemModel>[],
    table: null,
    archived: false,
  );

  await showDialog<void>(
    context: parentContext,
    barrierDismissible: false,
    builder: (_) {
      return OrderForm(
        order: order,
        title: 'Neue Bestellung',
        saveButtonText: 'Erstellen',
        successPrefix: 'Bestellung erstellt für Tisch:',
        errorPrefix: 'Fehler beim Erstellen für Tisch:',

        // OrderForm übernimmt Validierung und das Schließen des Dialogs selbst.
        // Hier läuft ausschließlich der Backend-Aufruf, der Erfolg oder Fehler meldet.
        action: (OrderModel o, ScaffoldMessengerState messenger) async {
          // Zeigt während des Backend-Aufrufs einen Ladeindikator über dem Formular.
          showDialog<void>(
            context: parentContext,
            barrierDismissible: false,
            builder: (c) => const Center(child: CircularProgressIndicator()),
          );

          bool success = false;
          try {
            success = await appState.backend
                .createOrder(appState.client, o)
                .timeout(const Duration(seconds: 10));
          } on TimeoutException {
            success = false;
            parentMessenger.showSnackBar(
              const SnackBar(content: Text('Request timed out')),
            );
            appState.setConnectionStatus(ConnectionStatus.offline);
          } catch (e) {
            success = false;
            parentMessenger.showSnackBar(SnackBar(content: Text('Fehler: $e')));
            appState.setConnectionStatus(ConnectionStatus.offline);
          } finally {
            if (parentNavigator.mounted) {
              parentNavigator.pop(); // Ladeindikator schließen
            }
          }

          try {
            final status = await appState.backend.checkConnectionStatus(
              appState.client,
            );
            appState.setConnectionStatus(status);
          } catch (_) {
            appState.setConnectionStatus(ConnectionStatus.offline);
          }

          return success;
        },

        // Liefert nur dann true, wenn die OrderForm einen erfolgreichen Abschluss meldet.
        onSaved: () {
          if (!resultCompleter.isCompleted) resultCompleter.complete(true);
        },

        fetchMenuItems: () async {
          return await appState.backend.fetchMenuItems(appState.client);
        },
        fetchTables: () async {
          return await appState.backend.fetchTables(appState.client);
        },
      );
    },
  );

  if (!resultCompleter.isCompleted) resultCompleter.complete(false);
  return resultCompleter.future;
}
