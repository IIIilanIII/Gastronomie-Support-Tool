import 'package:flutter/material.dart';
import 'package:frontend/models/table_model.dart';

/// Dropdownfeld für Tische, das die Optionen asynchron lädt. Zeigt Lade- und
/// Fehlermeldungen an, bietet einen leeren Hinweistext und wählt optional den
/// ersten Tisch automatisch, falls noch keiner gesetzt wurde.
class OrderTableField extends StatelessWidget {
  final Future<List<TableModel>> tablesFuture;
  final TableModel? value;
  final ValueChanged<TableModel?> onChanged;

  final String hintText;
  final String labelText;
  final bool autoSelectFirstIfNull;

  const OrderTableField({
    super.key,
    required this.tablesFuture,
    required this.value,
    required this.onChanged,
    this.hintText = 'Tisch wählen',
    this.labelText = 'Tisch:',
    this.autoSelectFirstIfNull = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TableModel>>(
      future: tablesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Fehler beim Laden der Tische: ${snapshot.error}');
        }

        final tables = snapshot.data ?? <TableModel>[];
        if (tables.isEmpty) {
          return const Text('Keine verfügbaren Tische');
        }

        TableModel? currentValue = value;

        // Falls der aktuelle Wert nicht mehr vorhanden ist, wählen wir robust neu aus
        if (currentValue == null || !tables.contains(currentValue)) {
          if (autoSelectFirstIfNull) {
            currentValue = tables.first;

            // Auto-Auswahl erst nach dem Build melden, um setState im Build zu vermeiden
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onChanged(currentValue);
            });
          } else {
            currentValue = null;
          }
        }

        return DropdownButtonFormField<TableModel>(
          isExpanded: true,
          hint: Text(hintText),
          decoration: InputDecoration(labelText: labelText),
          initialValue: currentValue,
          items: tables
              .map(
                (t) => DropdownMenuItem<TableModel>(
                  value: t,
                  child: Text(t.id.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
