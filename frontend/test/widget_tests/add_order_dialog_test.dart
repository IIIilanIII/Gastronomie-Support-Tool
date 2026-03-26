import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/button/add_order_button.dart';
import 'package:frontend/widgets/dialog/add_order_dialog.dart';
import 'package:http/http.dart' as http;

import 'order_test_utils.dart';

class RecordingOrderBackend extends BackendProxy {
  RecordingOrderBackend({
    required this.response,
    required this.menuItemsResponse,
    required this.tablesResponse,
    this.connectionStatus = ConnectionStatus.online,
  });

  final Future<bool> Function(OrderModel order) response;
  final Future<FetchResult<List<MenuItemModel>>> Function() menuItemsResponse;
  final Future<List<TableModel>> Function() tablesResponse;

  int createOrderCalls = 0;
  OrderModel? recordedOrder;
  int fetchMenuItemsCalls = 0;
  int fetchTablesCalls = 0;
  ConnectionStatus connectionStatus;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      connectionStatus;

  @override
  Future<bool> createOrder(http.Client client, OrderModel order) async {
    createOrderCalls += 1;
    recordedOrder = order;
    return response(order);
  }

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    fetchMenuItemsCalls += 1;
    return menuItemsResponse();
  }

  @override
  Future<List<TableModel>> fetchTables(http.Client client) async {
    fetchTablesCalls += 1;
    return tablesResponse();
  }
}

class FakeBackendForHomeScreen extends BackendProxy {
  FakeBackendForHomeScreen({required this.tables, required this.menuItems});

  final List<TableModel> tables;
  final List<MenuItemModel> menuItems;

  int fetchMenuItemsCalls = 0;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);

  @override
  Future<List<TableModel>> fetchTables(http.Client client) async => tables;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    fetchMenuItemsCalls += 1;
    return FetchResult.success(menuItems);
  }
}

const snackBarDuration = Duration(seconds: 5);

void main() {
  final tables123 = [TableModel(id: 1), TableModel(id: 2), TableModel(id: 3)];

  group('showAddOrderDialog', () {
    group('success', () {
      testWidgets('default table (first) -> success, loader visible', (
        tester,
      ) async {
        final backend = RecordingOrderBackend(
          response: (o) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return true;
          },
          menuItemsResponse: () async => FetchResult.success(<MenuItemModel>[]),
          tablesResponse: () async => tables123,
        );
        final appState = newAppState(backend);

        final context = await pumpHostApp(tester, appState);

        final resultFuture = showAddOrderDialog(context);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));

        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 30));
        await tester.pumpAndSettle();

        expect(await resultFuture, isTrue);
        expect(backend.createOrderCalls, 1);
        expect(backend.recordedOrder?.table?.id, 1);

        expect(snackBarTextContaining('Bestellung erstellt'), findsOneWidget);

        await tester.pump(snackBarDuration);
        await tester.pumpAndSettle();
      });

      testWidgets('select table 2 -> success', (tester) async {
        final backend = RecordingOrderBackend(
          response: (o) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return true;
          },
          menuItemsResponse: () async => FetchResult.success(<MenuItemModel>[]),
          tablesResponse: () async => tables123,
        );
        final appState = newAppState(backend);

        final context = await pumpHostApp(tester, appState);

        final resultFuture = showAddOrderDialog(context);
        await tester.pumpAndSettle();

        await tester.tap(tableDropdown());
        await tester.pumpAndSettle();
        await tester.tap(find.text('2').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 30));
        await tester.pumpAndSettle();

        expect(await resultFuture, isTrue);
        expect(backend.recordedOrder?.table?.id, 2);
        expect(snackBarTextContaining('Bestellung erstellt'), findsOneWidget);

        await tester.pump(snackBarDuration);
        await tester.pumpAndSettle();
      });
    });

    group('failure modes', () {
      testWidgets('backend returns false -> error snackbar', (tester) async {
        final backend = RecordingOrderBackend(
          response: (_) async => false,
          menuItemsResponse: () async => FetchResult.success(<MenuItemModel>[]),
          tablesResponse: () async => tables123,
          connectionStatus: ConnectionStatus.offline,
        );
        final appState = newAppState(backend);

        final context = await pumpHostApp(tester, appState);
        final resultFuture = showAddOrderDialog(context);
        await tester.pumpAndSettle();

        await tester.tap(tableDropdown());
        await tester.pumpAndSettle();
        await tester.tap(find.text('3').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));
        await tester.pumpAndSettle();

        expect(await resultFuture, isFalse);
        expect(backend.recordedOrder?.table?.id, 3);

        expect(
          find.textContaining('Fehler beim Erstellen für Tisch:'),
          findsOneWidget,
        );
      });

      testWidgets('backend throws -> exception snackbar + offline', (
        tester,
      ) async {
        final backend = RecordingOrderBackend(
          response: (_) async => throw Exception('kaputt'),
          menuItemsResponse: () async => FetchResult.success(<MenuItemModel>[]),
          tablesResponse: () async => tables123,
          connectionStatus: ConnectionStatus.offline,
        );
        final appState = newAppState(backend);

        final context = await pumpHostApp(tester, appState);
        final resultFuture = showAddOrderDialog(context);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));
        await tester.pumpAndSettle();

        expect(await resultFuture, isFalse);
        expect(appState.cStatus, ConnectionStatus.offline);
        expect(
          find.textContaining('Fehler: Exception: kaputt'),
          findsOneWidget,
        );
      });

      testWidgets('timeout -> offline + timeout snackbar', (tester) async {
        final backend = RecordingOrderBackend(
          response: (_) => Completer<bool>().future,
          menuItemsResponse: () async => FetchResult.success(<MenuItemModel>[]),
          tablesResponse: () async => tables123,
          connectionStatus: ConnectionStatus.offline,
        );
        final appState = newAppState(backend);

        final context = await pumpHostApp(tester, appState);
        final resultFuture = showAddOrderDialog(context);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));
        await tester.pump(); // loader

        await tester.pump(const Duration(seconds: 11));
        await tester.pumpAndSettle();

        expect(await resultFuture, isFalse);
        expect(appState.cStatus, ConnectionStatus.offline);
        expect(find.text('Request timed out'), findsOneWidget);
      });
    });

    group('menu items flow', () {
      testWidgets('opens subdialog and fetches menu items', (tester) async {
        final backend = RecordingOrderBackend(
          response: (_) async => true,
          menuItemsResponse: () async => FetchResult.success([
            MenuItemModel(
              id: 1,
              name: 'Pizza',
              price: 8.94,
              description: 'Salami',
              version: 1,
              archived: false,
            ),
          ]),
          tablesResponse: () async => [TableModel(id: 1), TableModel(id: 2)],
        );
        final appState = newAppState(backend);

        final context = await pumpHostApp(tester, appState);
        final resultFuture = showAddOrderDialog(context);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('order_add_sub_items')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('order_add_sub_items_dialog')),
          findsOneWidget,
        );
        expect(backend.fetchMenuItemsCalls, 1);

        await tester.tap(find.byKey(const Key('order_add_sub_items_dropdown')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pizza — 8.94€').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hinzufügen'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Pizza (id: 1) — 8.94€'), findsOneWidget);

        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();

        expect(await resultFuture, isFalse);
      });

      testWidgets('HomeScreen: add order -> add item qty=2', (tester) async {
        final backend = FakeBackendForHomeScreen(
          tables: tables123,
          menuItems: [
            MenuItemModel(
              id: 1,
              name: 'Bier',
              price: 5.0,
              description: 'Alkoholfrei',
              version: 1,
              archived: false,
            ),
            MenuItemModel(
              id: 2,
              name: 'Pizza',
              price: 8.94,
              description: 'Salami',
              version: 2,
              archived: false,
            ),
          ],
        );
        final appState = newAppState(backend);
        appState.setTab(AppTab.order);

        await tester.pumpWidget(
          AppStateScope(
            notifier: appState,
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AddOrderButton));
        await tester.pumpAndSettle();

        await tester.tap(tableDropdown());
        await tester.pumpAndSettle();
        await tester.tap(find.text('2').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('order_add_sub_items')));
        await tester.pumpAndSettle();

        expect(backend.fetchMenuItemsCalls, 1);

        final addItemDialog = find.byKey(
          const Key('order_add_sub_items_dialog'),
        );
        expect(addItemDialog, findsOneWidget);

        await tester.tap(find.byKey(const Key('order_add_sub_items_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pizza — 8.94€').last);
        await tester.pumpAndSettle();

        final qtyField = find.descendant(
          of: addItemDialog,
          matching: find.byType(TextField),
        );
        await tester.enterText(qtyField, '2');
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: addItemDialog,
            matching: find.widgetWithText(TextButton, 'Hinzufügen'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Pizza (id: 2) — 8.94€'), findsOneWidget);
        expect(find.text('Artikel (2)'), findsOneWidget);
      });
    });
  });
}
