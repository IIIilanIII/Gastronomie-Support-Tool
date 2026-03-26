import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/widgets/dialog/confirmation_order_dialog.dart';

/// Zentraler Knopf um Bestellungen zulöschen.
/// Öffnet den Dialog ConfirmationOrderDialog, welches in diesem Kontext die Bestätigung der Löschung anfrägt.
/// Nach erfolgreicher Aktion wird die angzeigte Bestellungsliste erneut geladen.
class DeleteOrderButton extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDeleted;

  const DeleteOrderButton({
    super.key,
    required this.order,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return SizedBox(
      height: 40,
      width: 40,
      child: IconButton(
        tooltip: 'Bestellung löschen',
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final deleted = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => ConfirmationOrderDialog(
              order: order,
              confirmActionLabel: 'löschen',
              successStateLabel: 'gelöscht',
              successMessage: _buildSuccessMessage(order),
              action: (o) => appState.backend.deleteOrder(appState.client, o),
            ),
          );

          if (deleted == true) {
            onDeleted();
          }
        },
      ),
    );
  }
}

// Baut die Erfolgsmeldung mit Bestell- und Tisch-ID zusammen.
String _buildSuccessMessage(OrderModel order) {
  final orderId = order.id?.toString() ?? 'unbekannt';
  final tableId = order.table?.id?.toString() ?? 'unbekannt';
  return 'Bestellung $orderId an Tisch $tableId gelöscht';
}
