import 'dart:async';
import 'package:flutter/material.dart';

typedef CreateEntityFn = Future<bool> Function(Map<String, dynamic> payload);

enum FieldType { text, number, textarea }

class FieldDef {
  final String key;
  final String label;
  final FieldType type;

  FieldDef({
    required this.key,
    required this.label,
    this.type = FieldType.text,
  });
}

// Allgemeiner Dialog zum Anlegen neuer Entitäten. Baut ein Formular aus
// [fields] auf, übergibt das Ergebnis an [createFn] und liefert bei Erfolg
// `true` zurück.
Future<bool> showAddEntityDialog(
  BuildContext parentContext, {
  required String title,
  required List<FieldDef> fields,
  required CreateEntityFn createFn,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  for (final f in fields) {
    controllers[f.key] = TextEditingController();
  }

  // Navigator und Messenger vorab merken, um nach await keinen deaktivierten Kontext zu nutzen
  final parentNavigator = Navigator.of(parentContext);
  final parentMessenger = ScaffoldMessenger.of(parentContext);

  bool result = false;

  await showDialog<void>(
    context: parentContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields.map((f) {
                final ctrl = controllers[f.key]!;
                if (f.type == FieldType.number) {
                  return TextFormField(
                    controller: ctrl,
                    decoration: InputDecoration(labelText: f.label),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return double.tryParse(v.replaceAll(',', '.')) == null
                          ? 'Ungültiger Wert'
                          : null;
                    },
                  );
                } else if (f.type == FieldType.textarea) {
                  return TextFormField(
                    controller: ctrl,
                    decoration: InputDecoration(labelText: f.label),
                    maxLines: 3,
                  );
                }

                return TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(labelText: f.label),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Bitte ausfüllen' : null,
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => parentNavigator.pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Formwerte in ein Payload-Objekt übertragen
                final payload = <String, dynamic>{};
                for (final f in fields) {
                  final v = controllers[f.key]!.text.trim();
                  if (v.isEmpty) continue;
                  if (f.type == FieldType.number) {
                    payload[f.key] = double.tryParse(v.replaceAll(',', '.'));
                  } else {
                    payload[f.key] = v;
                  }
                }

                // Eingabedialog zuerst schließen
                parentNavigator.pop();

                // Optional: Payload im Log ausgeben
                try {
                  // ignore: avoid_print
                  debugPrint('createEntity payload: $payload');
                } catch (_) {}

                // Ladeindikator über dem übergeordneten Kontext anzeigen
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                bool success = false;
                try {
                  success = await createFn(payload).timeout(timeout);
                } on TimeoutException catch (_) {
                  success = false;
                  parentMessenger.showSnackBar(
                    const SnackBar(content: Text('Request timed out')),
                  );
                } catch (e) {
                  success = false;
                  parentMessenger.showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }

                // Ladeindikator schließen, falls noch sichtbar
                if (parentNavigator.mounted) parentNavigator.pop();

                if (success) {
                  parentMessenger.showSnackBar(
                    const SnackBar(content: Text('Erstellt')),
                  );
                  result = true;
                } else {
                  // Allgemeine Fehlermeldung wurde bereits bei Timeout/Exception angezeigt
                  result = false;
                }
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      );
    },
  );

  // Controller freigeben
  for (final c in controllers.values) {
    c.dispose();
  }

  return result;
}
