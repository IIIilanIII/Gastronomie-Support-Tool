import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/dialog/edit_order_dialog.dart';
import 'package:http/http.dart' as http;

import 'order_test_utils.dart';

class RecordingEditBackend extends BackendProxy {
  RecordingEditBackend({
    required this.updateHandler,
    required this.tables,
    required this.menuItems,
    this.connectionStatus = ConnectionStatus.online,
    this.checkStatusResolver,
  });

  final Future<bool> Function(OrderModel order) updateHandler;
  final List<TableModel> tables;
  final List<MenuItemModel> menuItems;
  ConnectionStatus connectionStatus;
  Future<ConnectionStatus> Function(http.Client client)? checkStatusResolver;

  int updateCalls = 0;
  OrderModel? lastOrder;
  int fetchTablesCalls = 0;
  int fetchMenuItemsCalls = 0;
  int checkStatusCalls = 0;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async {
    checkStatusCalls++;
    if (checkStatusResolver != null) {
      return await checkStatusResolver!(client);
    }
    return connectionStatus;
  }

  @override
  Future<bool> updateOrder(http.Client client, OrderModel order) async {
    updateCalls++;
    lastOrder = order;
    return updateHandler(order);
  }

  @override
  Future<List<TableModel>> fetchTables(http.Client client) async {
    fetchTablesCalls++;
    return tables;
  }

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    fetchMenuItemsCalls++;
    return FetchResult.success(menuItems);
  }
}

OrderModel buildOrder({
  int id = 10,
  int quantity = 1,
  bool includeItems = true,
}) => OrderModel(
  id: id,
  items: includeItems
      ? [
          OrderItemModel(
            item: MenuItemModel(
              id: 5,
              name: 'Salat',
              description: 'Frisch',
              price: 4.5,
              version: 1,
              archived: false,
            ),
            quantity: quantity,
          ),
        ]
      : <OrderItemModel>[],
  table: TableModel(id: 1),
  archived: false,
);

void main() {
  final tables = [TableModel(id: 1), TableModel(id: 2), TableModel(id: 3)];
  final menuItems = [
    MenuItemModel(
      id: 1,
      name: 'Pizza',
      price: 8.5,
      version: 1,
      archived: false,
      description: '',
    ),
  ]; // Liste basiert nun auf MenuItemModel statt JSON-Map

  testWidgets('showEditOrderDialog updates order and shows success snackbar', (
    tester,
  ) async {
    final backend = RecordingEditBackend(
      updateHandler: (order) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return true;
      },
      tables: tables,
      menuItems: menuItems,
    );
    final appState = newAppState(backend);
    final order = buildOrder();

    final context = await pumpHostApp(tester, appState);

    final resultFuture = showEditOrderDialog(context, order: order);
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('order_add_sub_items')));
    await tester.pumpAndSettle();
    expect(backend.fetchMenuItemsCalls, 1);

    final addDialog = find.byKey(const Key('order_add_sub_items_dialog'));
    expect(addDialog, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: addDialog,
        matching: find.widgetWithText(TextButton, 'Abbrechen'),
      ),
    );
    await tester.pumpAndSettle();
    expect(backend.fetchTablesCalls, greaterThanOrEqualTo(1));

    await tester.tap(iconButtonWithTooltip('Mehr'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpAndSettle();

    expect(await resultFuture, isTrue);
    expect(backend.updateCalls, 1);
    expect(backend.lastOrder, same(order));
    expect(order.table?.id, 2);
    expect(order.items.first.quantity, 2);
    expect(find.textContaining('Bestellung aktualisiert:'), findsOneWidget);
    expect(backend.checkStatusCalls, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('showEditOrderDialog handles backend failure and shows error', (
    tester,
  ) async {
    final backend = RecordingEditBackend(
      updateHandler: (_) async => false,
      tables: tables,
      menuItems: menuItems,
      connectionStatus: ConnectionStatus.offline,
    );
    final appState = newAppState(backend);
    final order = buildOrder();

    final context = await pumpHostApp(tester, appState);

    final resultFuture = showEditOrderDialog(context, order: order);
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(await resultFuture, isFalse);
    expect(backend.updateCalls, 1);
    expect(appState.cStatus, ConnectionStatus.offline);
    expect(find.textContaining('Fehler beim Aktualisieren:'), findsOneWidget);
    expect(backend.checkStatusCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('showEditOrderDialog saves even without order items', (
    tester,
  ) async {
    final backend = RecordingEditBackend(
      updateHandler: (order) async => true,
      tables: tables,
      menuItems: menuItems,
    );
    final appState = newAppState(backend);
    final order = buildOrder(includeItems: false);

    final context = await pumpHostApp(tester, appState);

    final resultFuture = showEditOrderDialog(context, order: order);
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpAndSettle();

    expect(await resultFuture, isTrue);
    expect(backend.updateCalls, 1);
    expect(order.items, isEmpty);
    expect(find.textContaining('Bestellung aktualisiert:'), findsOneWidget);
  });

  testWidgets('showEditOrderDialog handles timeout and sets offline', (
    tester,
  ) async {
    final timeoutCompleter = Completer<bool>();
    final backend = RecordingEditBackend(
      updateHandler: (_) => timeoutCompleter.future,
      tables: tables,
      menuItems: menuItems,
      connectionStatus: ConnectionStatus.offline,
    );
    final appState = newAppState(backend);
    final order = buildOrder();

    final context = await pumpHostApp(tester, appState);

    final resultFuture = showEditOrderDialog(context, order: order);
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(await resultFuture, isFalse);
    expect(appState.cStatus, ConnectionStatus.offline);
    expect(find.text('Request timed out'), findsOneWidget);
    expect(backend.checkStatusCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('showEditOrderDialog catches exceptions and keeps offline', (
    tester,
  ) async {
    final backend = RecordingEditBackend(
      updateHandler: (_) async => throw Exception('kaputt'),
      tables: tables,
      menuItems: menuItems,
      connectionStatus: ConnectionStatus.offline,
    );
    final appState = newAppState(backend);
    backend.checkStatusResolver = (_) => Future<ConnectionStatus>.error('oops');
    final order = buildOrder();

    final context = await pumpHostApp(tester, appState);

    final resultFuture = showEditOrderDialog(context, order: order);
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(await resultFuture, isFalse);
    expect(appState.cStatus, ConnectionStatus.offline);
    expect(find.textContaining('Fehler: Exception: kaputt'), findsOneWidget);
    expect(backend.checkStatusCalls, greaterThanOrEqualTo(1));
  });
}
