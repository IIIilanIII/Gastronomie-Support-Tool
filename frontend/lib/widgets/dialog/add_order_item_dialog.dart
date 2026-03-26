import 'package:flutter/material.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';

/// Dialog zum Hinzufügen eines Artikels zu einer Bestellung [order].
/// Lädt alle aktuell unarchivierten MenuItems und lässt diese mit einer Anzahl zwischen 1 und 20 zur Bestellung hinzufügen.
/// Verfügbare MenuItems [availableItems] sind in einem Dropdownmenü verfügbar.
/// Als Eingabe sind nur positive Zahlen zwischen 1 und 20 möglich.
/// Erstellt zum Speichern ein neues OrderItemModel, welches dem OrderModel hinzugefügt wird.
/// Gibt `true` zurück, wenn ein Artikel hinzugefügt wurde, sonst `false`.
class AddOrderItemDialog extends StatefulWidget {
  final List<MenuItemModel> availableItems;
  final OrderModel order;

  const AddOrderItemDialog({
    super.key,
    required this.availableItems,
    required this.order,
  });

  @override
  State<AddOrderItemDialog> createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<AddOrderItemDialog> {
  final quantityCtrl = TextEditingController(text: '1');
  MenuItemModel? selectedItem;

  String? _qtyError;

  @override
  void dispose() {
    quantityCtrl.dispose();
    super.dispose();
  }

  int? _parseQty() {
    final q = int.tryParse(quantityCtrl.text.trim());
    if (q == null || q <= 0 || q > 20) return null;
    return q;
  }

  void _addSelected() {
    final item = selectedItem;
    if (item == null) return;

    final q = _parseQty();
    if (q == null) {
      setState(() => _qtyError = 'Bitte eine Menge von 1 bis 20 eingeben');
      return;
    }

    setState(() => _qtyError = null);

    final existing = widget.order.items.cast<OrderItemModel?>().firstWhere(
      (oi) => oi?.item == item,
      orElse: () => null,
    );

    if (existing != null) {
      existing.quantity += q;
      Navigator.of(context).pop(true);
      return;
    }

    final orderItem = OrderItemModel(item: item, quantity: q);
    widget.order.addOrderItem(orderItem);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('order_add_sub_items_dialog'),
      title: const Text('Artikel hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.availableItems.isEmpty)
            const Text('Keine verfügbaren Artikel')
          else
            DropdownButton<MenuItemModel>(
              key: const Key('order_add_sub_items_dropdown'),
              value: selectedItem,
              hint: const Text('Artikel wählen'),
              isExpanded: true,
              items: widget.availableItems
                  .map(
                    (item) => DropdownMenuItem<MenuItemModel>(
                      value: item,
                      child: Text(
                        '${item.name} — ${item.price.toStringAsFixed(2)}€',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (item) => setState(() => selectedItem = item),
            ),
          const SizedBox(height: 16),

          TextField(
            controller: quantityCtrl,
            decoration: InputDecoration(
              labelText: 'Menge',
              errorText: _qtyError,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) {
              // beim Tippen Fehler zurücksetzen, sobald valide
              if (_qtyError != null && _parseQty() != null) {
                setState(() => _qtyError = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: selectedItem == null ? null : _addSelected,
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
