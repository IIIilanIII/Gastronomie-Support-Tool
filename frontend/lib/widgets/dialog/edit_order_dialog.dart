import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/widgets/form/order_form.dart';

/// Zeigt das Formular OrderForm um die übergebene Bestellung [order] zu berarbeiten und zeigt entsprechende Statusmeldungen nach der Aktion an.
Future<bool> showEditOrderDialog(
  BuildContext parentContext, {
  required OrderModel order,
}) async {
  final appState = AppStateScope.of(parentContext);
  final parentNavigator = Navigator.of(parentContext);
  final parentMessenger = ScaffoldMessenger.of(parentContext);
  final result = Completer<bool>();

  await showDialog<void>(
    context: parentContext,
    barrierDismissible: false,
    builder: (_) {
      return OrderForm(
        order: order,
        title: 'Bestellung bearbeiten',
        saveButtonText: 'Speichern',
        successPrefix: 'Bestellung aktualisiert:',
        errorPrefix: 'Fehler beim Aktualisieren:',
        action: (updated, messenger) async {
          showDialog<void>(
            context: parentContext,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );

          bool success = false;
          try {
            success = await appState.backend
                .updateOrder(appState.client, updated)
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
              parentNavigator.pop();
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
        onSaved: () {
          if (!result.isCompleted) result.complete(true);
        },
        fetchMenuItems: () async {
          return await appState.backend.fetchMenuItems(appState.client);
        },
        fetchTables: () => appState.backend.fetchTables(appState.client),
      );
    },
  );

  if (!result.isCompleted) result.complete(false);
  return result.future;
}
