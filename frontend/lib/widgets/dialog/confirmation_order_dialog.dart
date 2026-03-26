import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_model.dart';

/// Wiederverwendbarer Bestätigungsdialog für veränderdende (speichern, löschen, archivieren) Bestellaktionen.
/// Die Aktion wird als Funktion übergeben [action] um [order]-änderungen entsprechend an das Backend zu übermitteln.
/// [confirmActionLabel] wird als Text für den Bestätigungsknopf erwartet, [successStateLabel] als Teil der Erfolgsmeldung und alternativ kann die komplette Meldung mit [successMessage] überschrieben werden
///
class ConfirmationOrderDialog extends StatelessWidget {
  final OrderModel order;
  final String confirmActionLabel;
  final String successStateLabel;
  final Future<bool> Function(OrderModel order) action;
  final String? successMessage;

  const ConfirmationOrderDialog({
    super.key,
    required this.order,
    required this.confirmActionLabel,
    required this.successStateLabel,
    required this.action,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final parentMessenger = ScaffoldMessenger.of(context);
    return AlertDialog(
      title: Text('Bestellung $confirmActionLabel'),
      content: Text(
        'Möchtest du Bestellung ${order.id} an Tisch ${order.table!.id} wirklich $confirmActionLabel?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            bool success = false;
            try {
              success = await action(order);
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
              final message =
                  successMessage ??
                  'Bestellung $successStateLabel: ${order.id}';
              showActionMessage(parentMessenger, message);
            } else {
              showActionMessage(
                parentMessenger,
                'Fehler beim $confirmActionLabel von ${order.id}',
              );
            }
            Navigator.of(context).pop(success);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(
            //bspw.: archivieren -> Archivieren
            confirmActionLabel.substring(0, 1).toUpperCase() +
                confirmActionLabel.substring(1),
          ),
        ),
      ],
    );
  }

  /// Blendet eine Snackbar ein, um den Benutzer zu informieren.
  void showActionMessage(
    ScaffoldMessengerState parentMessenger,
    String message,
  ) {
    parentMessenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
