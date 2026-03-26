import 'package:flutter/material.dart';
import 'package:frontend/models/order_item_model.dart';

/// Repräsentiert eine Artikelzeile mit Name, Menge und optionalem Archiv-Hinweis.
/// Alle Interaktionen laufen über Callbacks, damit das umschließende Formular
/// den Zustand steuern kann.
class OrderItemRow extends StatelessWidget {
  final OrderItemModel orderItem;
  final bool isArchived;

  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onDelete;

  // Reagiert auf Klicks bei archivierten Artikeln.
  final VoidCallback onArchivedTap;

  const OrderItemRow({
    super.key,
    required this.orderItem,
    required this.isArchived,
    required this.onInc,
    required this.onDec,
    required this.onDelete,
    required this.onArchivedTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;

    final canDec = !isArchived && orderItem.quantity > 0;
    final canInc = !isArchived;

    return Row(
      children: [
        // Linke Spalte: Text samt optionalem Chip
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${orderItem.item.name} (id: ${orderItem.item.id}) — '
                  '${orderItem.item.price.toStringAsFixed(2)}€',
                  softWrap: true,
                  style: isArchived ? TextStyle(color: disabledColor) : null,
                ),
              ),
              if (isArchived) ...[
                const SizedBox(width: 8),
                const Chip(
                  label: Text('Archiviert'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),

        // Rechte Spalte: Mengensteuerung und Löschen
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isArchived ? 'Archiviert' : 'Weniger',
              icon: const Icon(Icons.remove),
              onPressed: isArchived ? onArchivedTap : (canDec ? onDec : null),
            ),
            SizedBox(
              width: 28,
              child: Center(
                child: Text(
                  '${orderItem.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              tooltip: isArchived ? 'Archiviert' : 'Mehr',
              icon: const Icon(Icons.add),
              onPressed: isArchived ? onArchivedTap : (canInc ? onInc : null),
            ),
          ],
        ),

        IconButton(
          tooltip: 'Entfernen',
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }
}
