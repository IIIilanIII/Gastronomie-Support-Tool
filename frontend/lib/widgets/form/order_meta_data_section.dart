import 'package:flutter/material.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/widgets/form/order_table_field.dart';

/// Zeigt in der Bestellmaske die linke Spalte mit ID-Anzeige und Tischwahl.
class OrderMetaDataSection extends StatelessWidget {
  final OrderModel order;

  // Lädt die verfügbaren Tische.
  final Future<List<TableModel>> tablesFuture;

  // Aktuell ausgewählter Tisch, häufig `_selectedTable ?? order.table`.
  final TableModel? selectedTable;

  // Wird aufgerufen, wenn der Nutzer einen Tisch auswählt.
  final ValueChanged<TableModel?> onTableChanged;

  const OrderMetaDataSection({
    super.key,
    required this.order,
    required this.tablesFuture,
    required this.selectedTable,
    required this.onTableChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ID: ${order.id ?? 'New ID'}'),
        const SizedBox(height: 12),

        OrderTableField(
          tablesFuture: tablesFuture,
          value: selectedTable,
          onChanged: onTableChanged,
          hintText: 'Tisch wählen',
          labelText: 'Tisch:',
          autoSelectFirstIfNull: true,
        ),
      ],
    );
  }
}
