import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/list/list_item/order_item.dart';
import 'package:frontend/widgets/list/order_list.dart';
import 'package:http/http.dart' as http;

import 'order_test_utils.dart';

MenuItemModel _menuItem(int id, String name, double price) => MenuItemModel(
  id: id,
  name: name,
  description: '',
  price: price,
  version: 1,
  archived: false,
);

OrderItemModel _orderItem(
  int id,
  String name,
  double price, {
  int quantity = 1,
}) => OrderItemModel(quantity: quantity, item: _menuItem(id, name, price));

OrderModel _order({
  required int id,
  required TableModel table,
  List<OrderItemModel> items = const [],
  bool archived = false,
}) => OrderModel(id: id, items: items, table: table, archived: archived);

OrderModel _oneOrderForHoverTest({bool archived = false}) => _order(
  id: 123,
  table: TableModel(id: 9),
  archived: archived,
  items: [
    _orderItem(1, 'A', 2.0, quantity: 2),
    _orderItem(2, 'B', 3.0, quantity: 1),
  ],
);

Card _cardOfOrderItem(WidgetTester tester) => tester.widget<Card>(
  find.descendant(of: find.byType(OrderItem), matching: find.byType(Card)),
);

Color _expectedHoverColor(ThemeData theme, {required bool archived}) {
  final accentColor = archived
      ? theme.colorScheme.tertiary
      : theme.colorScheme.secondary;
  final containerColor = archived
      ? theme.colorScheme.tertiaryContainer
      : theme.colorScheme.secondaryContainer;
  final baseColor = containerColor.withOpacity(0.92);
  return Color.alphaBlend(accentColor.withOpacity(0.2), baseColor);
}

Future<TestGesture> _hoverOrderItemWidget(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: const Offset(1, 1));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.byType(OrderItem)));
  await tester.pumpAndSettle();
  return gesture;
}

class StubOrdersEmpty extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);
}

class StubOrdersWithItems extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async {
    return FetchResult.success([
      _order(
        id: 1,
        table: TableModel(id: 7),
        items: [
          _orderItem(10, 'Bier', 5.0, quantity: 2),
          _orderItem(11, 'Pizza', 8.0, quantity: 1),
        ],
      ),
      _order(
        id: 2,
        table: TableModel(id: 3),
        items: [_orderItem(12, 'Cola', 3.5, quantity: 4)],
      ),
    ]);
  }
}

class StubDelayedOrders extends BackendProxy {
  final Completer<FetchResult<List<OrderModel>>> completer =
      Completer<FetchResult<List<OrderModel>>>();

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) =>
      completer.future;
}

class StubRefreshableOrders extends BackendProxy {
  int calls = 0;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async {
    calls++;
    if (calls == 1) {
      return FetchResult.success([
        _order(
          id: 1,
          table: TableModel(id: 7),
          items: [_orderItem(10, 'Bier', 5.0, quantity: 2)],
        ),
      ]);
    }
    return FetchResult.success([
      _order(
        id: 99,
        table: TableModel(id: 1),
        items: [
          _orderItem(20, 'Wasser', 2.0, quantity: 1),
          _orderItem(21, 'Kaffee', 3.0, quantity: 2),
        ],
      ),
    ]);
  }
}

class RecordingCloseOrderBackend extends BackendProxy {
  RecordingCloseOrderBackend({required this.result});

  final bool result;
  int calls = 0;
  OrderModel? last;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);

  @override
  Future<bool> closeOrder(http.Client client, OrderModel order) async {
    calls++;
    last = order;
    return result;
  }
}

class RecordingDeleteOrderBackend extends BackendProxy {
  RecordingDeleteOrderBackend({required this.result});

  final bool result;
  int calls = 0;
  OrderModel? last;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);

  @override
  Future<bool> deleteOrder(http.Client client, OrderModel order) async {
    calls++;
    last = order;
    return result;
  }
}

class RecordingUpdateOrderBackend extends BackendProxy {
  RecordingUpdateOrderBackend({
    required this.result,
    List<MenuItemModel>? menuItems,
    List<TableModel>? tables,
  }) : _menuItems =
           menuItems ?? [_menuItem(1, 'Bier', 5.0), _menuItem(2, 'Pizza', 8.5)],
       _tables = tables ?? [TableModel(id: 1), TableModel(id: 2)];

  final bool result;
  int calls = 0;
  OrderModel? last;
  final List<MenuItemModel> _menuItems;
  final List<TableModel> _tables;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success(_menuItems);
  }

  @override
  Future<List<TableModel>> fetchTables(http.Client client) async {
    return _tables;
  }

  @override
  Future<bool> updateOrder(http.Client client, OrderModel order) async {
    calls++;
    last = order;
    return result;
  }
}

Widget _wrapWithAppState(Widget child, AppState appState) {
  return AppStateScope(
    notifier: appState,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('OrderList shows empty message when no orders', (tester) async {
    final appState = AppState(StubOrdersEmpty(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(body: OrderList(refreshToken: 0)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Keine Bestellungen vorhanden.'), findsOneWidget);
  });

  testWidgets('OrderList shows orders, quantities and total prices', (
    tester,
  ) async {
    final appState = AppState(StubOrdersWithItems(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(body: OrderList(refreshToken: 0)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Bestellung #1 · Tisch 7'), findsOneWidget);
    expect(find.text('Bestellung #2 · Tisch 3'), findsOneWidget);

    expect(find.text('Artikel: 3'), findsOneWidget);
    expect(find.text('Artikel: 4'), findsOneWidget);

    expect(find.text('Gesamt: €18.00'), findsOneWidget);
    expect(find.text('Gesamt: €14.00'), findsOneWidget);
  });

  testWidgets('OrderList shows loading indicator until data arrives', (
    tester,
  ) async {
    final stub = StubDelayedOrders();
    final appState = AppState(stub, http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(body: OrderList(refreshToken: 0)),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    stub.completer.complete(
      FetchResult.success([
        _order(
          id: 5,
          table: TableModel(id: 2),
          items: [_orderItem(1, 'Latte', 4.0, quantity: 3)],
        ),
      ]),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Bestellung #5 · Tisch 2'), findsOneWidget);
    expect(find.text('Artikel: 3'), findsOneWidget);
    expect(find.text('Gesamt: €12.00'), findsOneWidget);
  });

  testWidgets('OrderList reloads when refreshToken changes', (tester) async {
    final stub = StubRefreshableOrders();
    final appState = AppState(stub, http.Client());

    Widget buildWithToken(int token) => MaterialApp(
      home: AppStateScope(
        notifier: appState,
        child: Scaffold(body: OrderList(refreshToken: token)),
      ),
    );

    await tester.pumpWidget(buildWithToken(0));
    await tester.pumpAndSettle();

    expect(stub.calls, 1);
    expect(find.text('Bestellung #1 · Tisch 7'), findsOneWidget);
    expect(find.text('Artikel: 2'), findsOneWidget);
    expect(find.text('Gesamt: €10.00'), findsOneWidget);
    expect(find.text('Bestellung #99 · Tisch 1'), findsNothing);

    await tester.pumpWidget(buildWithToken(1));
    await tester.pumpAndSettle();

    expect(stub.calls, 2);
    expect(find.text('Bestellung #99 · Tisch 1'), findsOneWidget);
    expect(find.text('Artikel: 3'), findsOneWidget);
    expect(find.text('Gesamt: €8.00'), findsOneWidget);
  });

  testWidgets('OrderItem changes Card color on hover and back on exit', (
    tester,
  ) async {
    final order = _oneOrderForHoverTest(archived: false);
    final appState = AppState(StubOrdersEmpty(), http.Client());

    await tester.pumpWidget(
      _wrapWithAppState(OrderItem(order: order), appState),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(OrderItem));
    final theme = Theme.of(element);
    final baseColor = theme.colorScheme.secondaryContainer.withOpacity(0.92);
    final hoverColor = _expectedHoverColor(theme, archived: false);

    expect(_cardOfOrderItem(tester).color, baseColor);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(1, 1));
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byType(OrderItem)));
    await tester.pumpAndSettle();
    expect(_cardOfOrderItem(tester).color, hoverColor);

    await gesture.moveTo(
      tester.getTopLeft(find.byType(OrderItem)) - const Offset(20, 20),
    );
    await tester.pumpAndSettle();
    expect(_cardOfOrderItem(tester).color, baseColor);
  });

  testWidgets(
    'OrderItem uses green baseColor when archived and still darkens on hover',
    (tester) async {
      final order = _oneOrderForHoverTest(archived: true);
      final appState = AppState(StubOrdersEmpty(), http.Client());

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(OrderItem));
      final theme = Theme.of(element);
      final baseColor = theme.colorScheme.tertiaryContainer.withOpacity(0.92);
      final hoverColor = _expectedHoverColor(theme, archived: true);

      expect(_cardOfOrderItem(tester).color, baseColor);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(1, 1));
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(OrderItem)));
      await tester.pumpAndSettle();
      expect(_cardOfOrderItem(tester).color, hoverColor);

      await gesture.moveTo(
        tester.getTopLeft(find.byType(OrderItem)) - const Offset(20, 20),
      );
      await tester.pumpAndSettle();
      expect(_cardOfOrderItem(tester).color, baseColor);
    },
  );

  testWidgets(
    'OrderItem hover handlers are idempotent (enter twice / exit twice)',
    (tester) async {
      final order = _oneOrderForHoverTest(archived: false);
      final appState = AppState(StubOrdersEmpty(), http.Client());

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(1, 1));
      await tester.pump();

      final center = tester.getCenter(find.byType(OrderItem));
      final outside =
          tester.getTopLeft(find.byType(OrderItem)) - const Offset(20, 20);

      final element = tester.element(find.byType(OrderItem));
      final theme = Theme.of(element);
      final baseColor = theme.colorScheme.secondaryContainer.withOpacity(0.92);
      final hoverColor = _expectedHoverColor(theme, archived: false);

      await gesture.moveTo(center);
      await tester.pumpAndSettle();
      expect(_cardOfOrderItem(tester).color, hoverColor);

      await gesture.moveTo(center);
      await tester.pumpAndSettle();
      expect(_cardOfOrderItem(tester).color, hoverColor);

      await gesture.moveTo(outside);
      await tester.pumpAndSettle();
      expect(_cardOfOrderItem(tester).color, baseColor);

      await gesture.moveTo(outside);
      await tester.pumpAndSettle();
      expect(_cardOfOrderItem(tester).color, baseColor);
    },
  );

  testWidgets(
    'OrderItem: confirm archive -> closeOrder called and refreshToken bumped',
    (tester) async {
      final backend = RecordingCloseOrderBackend(result: true);
      final appState = AppState(backend, http.Client());

      final order = _order(
        id: 42,
        table: TableModel(id: 7),
        items: [_orderItem(1, 'Bier', 5.0, quantity: 2)],
      );

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Archivieren'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(backend.calls, 1);
      expect(backend.last?.id, 42);
      expect(appState.orderListRefreshToken, before + 1);
    },
  );

  testWidgets(
    'OrderItem: cancel archive -> closeOrder not called, token unchanged',
    (tester) async {
      final backend = RecordingCloseOrderBackend(result: true);
      final appState = AppState(backend, http.Client());

      final order = _order(id: 7, table: TableModel(id: 7));

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(backend.calls, 0);
      expect(appState.orderListRefreshToken, before);
    },
  );

  testWidgets(
    'OrderItem: backend returns false -> closeOrder called, token unchanged',
    (tester) async {
      final backend = RecordingCloseOrderBackend(result: false);
      final appState = AppState(backend, http.Client());

      final order = _order(id: 8, table: TableModel(id: 7));

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Archivieren'));
      await tester.pumpAndSettle();

      expect(backend.calls, 1);
      expect(appState.orderListRefreshToken, before);
    },
  );

  testWidgets('OrderItem open -> delete button only visible on hover', (
    tester,
  ) async {
    final appState = AppState(StubOrdersEmpty(), http.Client());
    final order = _order(id: 5, table: TableModel(id: 2));

    await tester.pumpWidget(
      _wrapWithAppState(OrderItem(order: order), appState),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);

    final gesture = await _hoverOrderItemWidget(tester);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await gesture.removePointer();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('OrderItem hover zeigt nur löschen', (tester) async {
    final appState = AppState(StubOrdersEmpty(), http.Client());
    final order = _oneOrderForHoverTest(archived: false);

    await tester.pumpWidget(
      _wrapWithAppState(OrderItem(order: order), appState),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete), findsNothing);

    final gesture = await _hoverOrderItemWidget(tester);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await gesture.removePointer();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('OrderItem archived -> shows checked icon and no delete button', (
    tester,
  ) async {
    final backend = RecordingCloseOrderBackend(result: true);
    final appState = AppState(backend, http.Client());

    final order = _order(id: 1, table: TableModel(id: 7), archived: true);

    await tester.pumpWidget(
      _wrapWithAppState(OrderItem(order: order), appState),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);

    final gesture = await _hoverOrderItemWidget(tester);
    expect(find.byIcon(Icons.delete), findsNothing);
    await gesture.removePointer();
  });

  testWidgets(
    'OrderItem: confirm delete -> deleteOrder called and refreshToken bumped',
    (tester) async {
      final backend = RecordingDeleteOrderBackend(result: true);
      final appState = AppState(backend, http.Client());

      final order = _order(
        id: 42,
        table: TableModel(id: 7),
        items: [_orderItem(1, 'Bier', 5.0, quantity: 2)],
      );

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;

      final hover = await _hoverOrderItemWidget(tester);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(backend.calls, 1);
      expect(backend.last?.id, 42);
      expect(appState.orderListRefreshToken, before + 1);
      expect(find.text('Bestellung 42 an Tisch 7 gelöscht'), findsOneWidget);
      await hover.removePointer();
    },
  );

  testWidgets(
    'OrderItem: cancel delete -> deleteOrder not called, token unchanged',
    (tester) async {
      final backend = RecordingDeleteOrderBackend(result: true);
      final appState = AppState(backend, http.Client());
      final order = _order(id: 7, table: TableModel(id: 7));

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;

      final hover = await _hoverOrderItemWidget(tester);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(backend.calls, 0);
      expect(appState.orderListRefreshToken, before);
      await hover.removePointer();
    },
  );

  testWidgets(
    'OrderItem: delete returns false -> deleteOrder called, token unchanged',
    (tester) async {
      final backend = RecordingDeleteOrderBackend(result: false);
      final appState = AppState(backend, http.Client());
      final order = _order(id: 8, table: TableModel(id: 7));

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;

      final hover = await _hoverOrderItemWidget(tester);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(backend.calls, 1);
      expect(appState.orderListRefreshToken, before);
      await hover.removePointer();
    },
  );

  testWidgets('OrderItem: edit success updates order and refresh token', (
    tester,
  ) async {
    final backend = RecordingUpdateOrderBackend(result: true);
    final appState = AppState(backend, http.Client());
    final order = _order(
      id: 5,
      table: TableModel(id: 1),
      items: [
        _orderItem(10, 'Bier', 5.0, quantity: 3),
        _orderItem(11, 'Pizza', 8.0, quantity: 1),
      ],
    );

    await tester.pumpWidget(
      _wrapWithAppState(OrderItem(order: order), appState),
    );
    await tester.pumpAndSettle();

    final before = appState.orderListRefreshToken;
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(iconButtonWithTooltip('Weniger').first);
    await tester.pumpAndSettle();
    await tester.tap(iconButtonWithTooltip('Weniger').first);
    await tester.pumpAndSettle();
    await tester.tap(iconButtonWithTooltip('Weniger').first);
    await tester.pumpAndSettle();

    expect(find.text('Artikel (1)'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Speichern'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.calls, 1);
    expect(backend.last?.table?.id, 2);
    expect(backend.last?.items.length, 1);
    expect(backend.last?.items.first.item.id, 11);
    expect(appState.orderListRefreshToken, before + 1);
    expect(order.table?.id, 2);
    expect(order.items.length, 1);

    expect(find.textContaining('Bestellung aktualisiert:'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('OrderItem: edit Abbrechen -> keine Änderungen', (tester) async {
    final backend = RecordingUpdateOrderBackend(result: true);
    final appState = AppState(backend, http.Client());
    final order = _order(
      id: 6,
      table: TableModel(id: 1),
      items: [_orderItem(10, 'Bier', 5.0, quantity: 2)],
    );

    await tester.pumpWidget(
      _wrapWithAppState(OrderItem(order: order), appState),
    );
    await tester.pumpAndSettle();

    final beforeToken = appState.orderListRefreshToken;
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    await tester.tap(tableDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
    await tester.pumpAndSettle();

    expect(backend.calls, 0);
    expect(appState.orderListRefreshToken, beforeToken);
    expect(order.table?.id, 1);
  });

  testWidgets(
    'OrderItem: edit backend false -> token unverändert, Auswahl bleibt erhalten',
    (tester) async {
      final backend = RecordingUpdateOrderBackend(result: false);
      final appState = AppState(backend, http.Client());
      final order = _order(
        id: 7,
        table: TableModel(id: 1),
        items: [_orderItem(10, 'Bier', 5.0, quantity: 2)],
      );

      await tester.pumpWidget(
        _wrapWithAppState(OrderItem(order: order), appState),
      );
      await tester.pumpAndSettle();

      final before = appState.orderListRefreshToken;
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.tap(tableDropdown());
      await tester.pumpAndSettle();
      await tester.tap(find.text('2').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Speichern'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(backend.calls, 1);
      expect(appState.orderListRefreshToken, before);
      expect(order.table?.id, 2);
    },
  );
}
