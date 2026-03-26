import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/widgets/button/delete_order_button.dart';
import 'package:frontend/widgets/dialog/confirmation_order_dialog.dart';
import 'package:frontend/widgets/dialog/edit_order_dialog.dart';

/// Einzelne Kartenzeile für eine Bestellung[order] wird beim hovern farblich hervorgehoben und zeigt damit einen Löschenknopf an.
/// Zeigt an allen unarchivierten Items einen Knopf zum archivieren an.
/// Archivierte Bestellungen werden ebenfalls farblich hervorgehoben und der Archivieren- und Löschenknopf sind deaktiviert.
class OrderItem extends StatefulWidget {
  final OrderModel order;

  const OrderItem({super.key, required this.order});

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final order = widget.order;
    final theme = Theme.of(context);
    final id = order.id;
    final itemCount = order.items.fold(
      0,
      (sum, orderItem) => sum + orderItem.quantity,
    );
    final table = order.table!.id;
    final itemPriceSum = order.items.fold(
      0.0,
      (sum, orderItem) => sum + orderItem.quantity * orderItem.item.price,
    );
    final archived = order.archived;

    const box = BoxConstraints.tightFor(width: 48, height: 48);

    final accentColor = archived
        ? theme.colorScheme.tertiary
        : theme.colorScheme.secondary;
    final containerColor = archived
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final onContainerColor = archived
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSecondaryContainer;

    final baseColor = containerColor.withOpacity(0.92);

    final cardColor = _isHovered
        ? Color.alphaBlend(accentColor.withOpacity(0.2), baseColor)
        : baseColor;

    // Aktualisiert die Liste nach einer erfolgreichen Aktion.
    void handleCreated() {
      if (mounted) setState(() {});
      appState.bumpOrderListRefreshToken();
    }

    final showDeleteButton = _isHovered && !archived;

    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withOpacity(0.3), width: 1.2),
        ),
        child: ListTile(
          title: Text(
            'Bestellung #$id · Tisch $table',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          subtitle: Text(
            'Artikel: $itemCount',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onContainerColor.withOpacity(0.82),
            ),
          ),
          onTap: archived
              ? null
              : () async {
                  final success = await showEditOrderDialog(
                    context,
                    order: order,
                  );
                  if (success) {
                    handleCreated();
                  }
                },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showDeleteButton) ...[
                DeleteOrderButton(order: order, onDeleted: handleCreated),
                const SizedBox(width: 8),
              ],
              Text(
                'Gesamt: €${itemPriceSum.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              if (archived) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: Icon(Icons.check_box)),
                ),
              ] else ...[
                const SizedBox(width: 12),
                IconButton(
                  constraints: box,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.check_box_outline_blank),
                  tooltip: 'Bestellung archivieren',
                  onPressed: () async {
                    final success = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => ConfirmationOrderDialog(
                        order: order,
                        confirmActionLabel: 'archivieren',
                        successStateLabel: 'archiviert',
                        action: (o) =>
                            appState.backend.closeOrder(appState.client, o),
                      ),
                    );

                    if (success == true) {
                      handleCreated();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
