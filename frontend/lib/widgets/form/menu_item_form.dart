import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';

// Beschreibt eine Aktion, die einen Menüeintrag speichert und bei Erfolg
// `true` zurückgibt.
typedef MenuItemAction =
    Future<bool> Function(
      MenuItemModel menuItem,
      ScaffoldMessengerState messenger,
    );

/// Formular zum Erstellen oder Bearbeiten eines MenuItems [menuItem]. Aktualisiert den
/// Online-Status anhand des Action[action]-Ergebnisses und nutzt die [title], [saveButtonText], [successPrefix], [errorPrefix]
/// um die Beschriftungen und die Statusmeldung anzupassen.
/// Nach erfolgreicher Aktion wird [onCreated] aufgerufen um eine Aktualisierung der Liste zu erzwingen.
/// Die Felder MenuItemName und Preis werden zusätzlich validiert.
/// Der Name darf nicht leer sein und Leerzeichen vor und nach dem Text werden entfernt.
/// Für den Preis sind Text, negative Zahlen, mehr als 2 Nachkommastellen nicht zulässig.
/// Der Validator gibt den Speichernknopf erst frei, wenn nichts beanstandent wird.
class MenuItemForm extends StatefulWidget {
  final MenuItemAction action;
  final VoidCallback onCreated;
  final MenuItemModel menuItem;
  final String title;
  final String saveButtonText;
  final String successPrefix;
  final String errorPrefix;

  const MenuItemForm({
    super.key,
    required this.menuItem,
    required this.action,
    required this.title,
    required this.onCreated,
    required this.saveButtonText,
    required this.successPrefix,
    required this.errorPrefix,
  });

  @override
  State<MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<MenuItemForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late String _initialSnapshot;

  bool _isSubmitting = false;
  bool _isValid = false;

  InputDecoration _buildFieldDecoration(String label) {
    // Reserviert Platz für Fehlermeldungen, damit Felder nicht springen.
    return InputDecoration(labelText: label, helperText: ' ', errorMaxLines: 2);
  }

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.menuItem.name);
    _priceCtrl = TextEditingController(
      text: widget.menuItem.price.toStringAsFixed(2),
    );
    _descCtrl = TextEditingController(text: widget.menuItem.description);

    _initialSnapshot = _snapshotMenuItem();

    void listener() {
      // Optional: nur grundlegende Bedingungen prüfen statt validate() ständig aufzurufen.
      // Hier nutzen wir validate() live (siehe Form.onChanged unten),
      // daher ist setState() an dieser Stelle meist überflüssig.
    }

    _nameCtrl.addListener(listener);
    _priceCtrl.addListener(listener);
    _descCtrl.addListener(listener);

    // initialer Validitätscheck nach erstem Layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (mounted) setState(() => _isValid = ok);
    });
  }

  @override
  void didUpdateWidget(covariant MenuItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.menuItem, widget.menuItem)) {
      _initialSnapshot = _snapshotMenuItem();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showActionMessage(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) {
      setState(() => _isValid = false);
      return;
    }

    final parentMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameCtrl.text;
    final description = _descCtrl.text;
    final priceText = _priceCtrl.text.trim().replaceAll(',', '.');
    final parsedPrice = double.parse(priceText);
    final normalizedPrice = double.parse(parsedPrice.toStringAsFixed(2));

    final currentSnapshot = _snapshotMenuItem(
      name: name,
      description: description,
      price: normalizedPrice,
    );

    if (currentSnapshot == _initialSnapshot) {
      _showActionMessage(parentMessenger, 'Keine Änderungen vorgenommen.');
      navigator.pop();
      return;
    }

    setState(() => _isSubmitting = true);

    final appState = AppStateScope.of(context);

    bool success = false;
    bool reportedLocked = false;

    widget.menuItem.name = name.trim();
    widget.menuItem.description = description.trim();
    widget.menuItem.price = normalizedPrice;

    try {
      success = await widget
          .action(widget.menuItem, parentMessenger)
          .timeout(const Duration(seconds: 10));
    } on HttpException catch (e) {
      reportedLocked = true;
      _showActionMessage(parentMessenger, e.message);
    } on TimeoutException {
      success = false;
      _showActionMessage(parentMessenger, 'Request timed out');
      appState.setConnectionStatus(ConnectionStatus.offline);
    } catch (e) {
      success = false;
      _showActionMessage(parentMessenger, 'Fehler: $e');
      appState.setConnectionStatus(ConnectionStatus.offline);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (success) {
      appState.setConnectionStatus(ConnectionStatus.online);
      _showActionMessage(
        parentMessenger,
        '${widget.successPrefix} ${widget.menuItem.name}',
      );
      widget.onCreated();
    } else if (reportedLocked) {
      appState.setConnectionStatus(
        ConnectionStatus.online,
      ); // Menuitem wurde nicht wegen Verbindungsproblemen nicht aktualisiert
      widget.onCreated();
    } else {
      appState.setConnectionStatus(ConnectionStatus.offline);
      _showActionMessage(
        parentMessenger,
        '${widget.errorPrefix} ${widget.menuItem.name}',
      );
    }

    navigator.pop();
  }

  String _snapshotMenuItem({String? name, String? description, double? price}) {
    final data = Map<String, dynamic>.from(widget.menuItem.toJson());
    if (name != null) data['name'] = name.trim();
    if (description != null) data['description'] = description.trim();
    if (price != null) data['price'] = price;
    return jsonEncode(data);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _isValid && !_isSubmitting;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () {
          final ok = _formKey.currentState?.validate() ?? false;
          if (ok != _isValid) setState(() => _isValid = ok);
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text("ID: ${widget.menuItem.id}"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: _buildFieldDecoration('Name'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Bitte Namen eingeben'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                decoration: _buildFieldDecoration('Preis'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Bitte einen Preis eintragen';
                  }
                  final norm = v.trim().replaceAll(',', '.');
                  final parsed = double.tryParse(norm);
                  if (parsed == null || parsed < 0.0) return 'Ungültiger Preis';
                  final parts = norm.split('.');
                  final decimals = parts.length > 1 ? parts[1].length : 0;
                  if (decimals > 2) return 'Maximal 2 Nachkommastellen erlaubt';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: _buildFieldDecoration('Beschreibung'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Version: ${widget.menuItem.version}"),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Archived: ${widget.menuItem.archived}"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: canSubmit
              ? _submit
              : null, // Deaktiviert, solange das Formular ungültig ist oder sendet
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.saveButtonText),
        ),
      ],
    );
  }
}
