import 'package:flutter/material.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/widgets/form/order_item_row.dart';

/// Zeigt in der Bestellmaske die Artikelspalte mit Header, Zeilen und
/// Hinzufügen-Schaltfläche. Änderungen laufen über Callbacks, damit das Parent
/// Widget die Zustandsverwaltung behält.
class OrderItemsSection extends StatelessWidget {
  final OrderModel order;

  // Öffnet den Dialog zum Hinzufügen neuer Artikel.
  final VoidCallback onAddPressed;

  // Signalisiert dem Parent, dass sich die Artikelliste geändert hat.
  final VoidCallback onChanged;

  // Optionaler Messenger für lokale Snackbars.
  final ScaffoldMessengerState? messenger;

  const OrderItemsSection({
    super.key,
    required this.order,
    required this.onAddPressed,
    required this.onChanged,
    this.messenger,
  });

  int get _totalQty => order.items.fold<int>(0, (sum, oi) => sum + oi.quantity);

  void _showArchivedHint(BuildContext context) {
    final m = messenger ?? ScaffoldMessenger.of(context);
    m.showSnackBar(
      const SnackBar(
        content: Text(
          'Dieser Artikel ist archiviert und kann nicht mehr verändert werden.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Artikel ($_totalQty)'),
        const SizedBox(height: 8),

        Column(
          children: order.items.asMap().entries.map((e) {
            final idx = e.key;
            final oi = e.value;
            final isArchived = oi.item.archived;

            return OrderItemRow(
              orderItem: oi,
              isArchived: isArchived,
              onArchivedTap: () => _showArchivedHint(context),
              onInc: () {
                oi.quantity++;
                onChanged();
              },
              onDec: () {
                if (oi.quantity <= 1) {
                  order.items.removeAt(idx);
                } else {
                  oi.quantity--;
                }
                onChanged();
              },
              onDelete: () {
                order.items.removeAt(idx);
                onChanged();
              },
            );
          }).toList(),
        ),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('order_add_sub_items'),
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: const Text('Artikel hinzufügen'),
          ),
        ),
      ],
    );
  }
}
