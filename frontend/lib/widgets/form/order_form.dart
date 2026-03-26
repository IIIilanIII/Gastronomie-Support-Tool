import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/dialog/add_order_item_dialog.dart';
import 'package:frontend/widgets/form/order_items_section.dart';
import 'package:frontend/widgets/form/order_meta_data_section.dart';

// Erwartete Signatur für einen Backend-Aufruf, der eine Bestellung speichert.
typedef OrderAction =
    Future<bool> Function(OrderModel order, ScaffoldMessengerState messenger);

typedef FetchMenuItems = Future<FetchResult<List<MenuItemModel>>> Function();
typedef FetchTables = Future<List<TableModel>> Function();

/// Formular um [order] zu bearbeiten.
/// Nach erfolgreicher [action] wird die Funktion [onSaved] ausgeführt.
/// Nutzt [title], [saveButtonText], [successPrefix], [errorPrefix]
/// um die Beschriftungen und die Statusmeldung anzupassen.
/// Die Funktiopnen [fetchMenuItems] und [fetchTables] sind notwendig, um das Formular zu beginn mit möglichen MenuItems und Tischen vorzubereiten.
class OrderForm extends StatefulWidget {
  final OrderAction action;
  final VoidCallback onSaved;
  final OrderModel order;
  final String title;
  final String saveButtonText;
  final String successPrefix;
  final String errorPrefix;
  final FetchMenuItems fetchMenuItems;
  final FetchTables fetchTables;

  const OrderForm({
    super.key,
    required this.order,
    required this.action,
    required this.title,
    required this.onSaved,
    required this.saveButtonText,
    required this.successPrefix,
    required this.errorPrefix,
    required this.fetchMenuItems,
    required this.fetchTables,
  });

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  TableModel? _selectedTable;
  late String _initialSnapshot;

  @override
  void initState() {
    super.initState();
    _initialSnapshot = _snapshotOrder(widget.order);
  }

  @override
  void didUpdateWidget(covariant OrderForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.order, widget.order)) {
      _initialSnapshot = _snapshotOrder(widget.order);
    }
  }

  void _showActionMessage(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showAddItemDialog() async {
    List<MenuItemModel> availableItems = [];
    final result = await widget.fetchMenuItems();
    final allItems = result.data ?? <MenuItemModel>[];

    if (!result.isSuccess && mounted) {
      _showActionMessage(
        ScaffoldMessenger.of(context),
        'Fehler beim Laden: ${result.error}',
      );
    }

    availableItems = allItems.where((i) => !i.archived).toList();

    if (!mounted) return false;

    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AddOrderItemDialog(
        availableItems: availableItems,
        order: widget.order,
      ),
    );

    return added ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final parentMessenger = ScaffoldMessenger.of(context);
    final appState = AppStateScope.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: OrderMetaDataSection(
                    order: widget.order,
                    tablesFuture: widget.fetchTables(),
                    selectedTable: _selectedTable ?? widget.order.table,
                    onTableChanged: (t) {
                      if (t == null) return;
                      setState(() => _selectedTable = t);
                    },
                  ),
                ),

                const SizedBox(width: 24),

                Expanded(
                  flex: 2,
                  child: OrderItemsSection(
                    order: widget.order,
                    messenger: parentMessenger,
                    onChanged: () => setState(() {}),
                    onAddPressed: () async {
                      final added = await _showAddItemDialog();
                      if (added) setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;

            final navigator = Navigator.of(context);
            bool success = false;

            final candidateTable = _selectedTable ?? widget.order.table;
            final hasChanges =
                _snapshotOrder(widget.order, tableOverride: candidateTable) !=
                _initialSnapshot;
            if (!hasChanges) {
              _showActionMessage(
                parentMessenger,
                'Keine Änderungen vorgenommen.',
              );
              navigator.pop();
              return;
            }

            if (_selectedTable != null) {
              widget.order.table = _selectedTable;
            }

            try {
              success = await widget
                  .action(widget.order, parentMessenger)
                  .timeout(const Duration(seconds: 10));
            } on TimeoutException {
              success = false;
              _showActionMessage(parentMessenger, 'Request timed out');
              appState.setConnectionStatus(ConnectionStatus.offline);
            } catch (e) {
              success = false;
              _showActionMessage(parentMessenger, 'Fehler: $e');
              appState.setConnectionStatus(ConnectionStatus.offline);
            }

            _showActionMessage(
              parentMessenger,
              success
                  ? '${widget.successPrefix} ${widget.order.id ?? widget.order.table!.id}'
                  : '${widget.errorPrefix} ${widget.order.id ?? widget.order.table!.id}',
            );

            if (success) {
              widget.onSaved();
              appState.setConnectionStatus(ConnectionStatus.online);
            } else {
              appState.setConnectionStatus(ConnectionStatus.offline);
            }
            navigator.pop();
          },
          child: Text(widget.saveButtonText),
        ),
      ],
    );
  }

  String _snapshotOrder(OrderModel order, {TableModel? tableOverride}) {
    final data = Map<String, dynamic>.from(order.toJson());
    final tableSnapshot = tableOverride ?? order.table;
    data['barTable'] = tableSnapshot?.toJson();
    return jsonEncode(data);
  }
}
