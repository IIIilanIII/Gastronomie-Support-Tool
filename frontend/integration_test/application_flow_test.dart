import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/widgets/list/list_item/order_item.dart'
    as order_widgets;
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'flows/menu_item_form_flow.dart';
import 'flows/order_flow.dart';
import 'helpers/finders.dart';
import 'helpers/strings.dart';
import 'helpers/waits.dart';

Future<void> assertBackendReachable(http.Client client) async {
  try {
    final uri = Uri.parse('http://localhost:8080');
    await client
        .get(uri)
        .timeout(
          const Duration(seconds: 3),
        ); // nur prüfen ob hinter der URI ein HTTP Server ist
  } on TimeoutException {
    throw TestFailure(
      'Backend offline – bitte Server starten (Timeout beim Health-Check).',
    );
  } catch (e) {
    throw TestFailure('Backend offline – bitte Server starten. Fehler: $e');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late final AppState appState;
  late final BackendProxy backend;
  late final http.Client client;
  late TableModel defaultTable;
  late MenuItemModel creationItem;
  late MenuItemModel updateItem;
  late MenuItemModel archiveItem;
  late MenuItemModel deleteItem;

  Future<MenuItemModel> createMenuItemFixture({
    required String baseName,
    required double price,
  }) async {
    final menuItem = MenuItemModel(
      id: null,
      name: baseName,
      description: 'Integration Test',
      price: price,
      version: 1,
      archived: false,
    );

    final success = await backend.createMenuItem(client, menuItem);
    if (!success) {
      throw TestFailure('MenuItem konnte nicht angelegt werden: $baseName');
    }

    final result = await backend.fetchMenuItems(client);
    if (!result.isSuccess || result.data == null) {
      throw TestFailure('MenuItems konnten nicht geladen werden.');
    }

    final created = result.data!.firstWhere(
      (item) => item.name == baseName,
      orElse: () => throw TestFailure('MenuItem nicht gefunden: $baseName'),
    );
    return created;
  }

  Future<OrderModel> createOrderFixture({
    required MenuItemModel menuItem,
    int quantity = 1,
  }) async {
    final draft = OrderModel(
      id: null,
      items: [OrderItemModel(id: null, item: menuItem, quantity: quantity)],
      table: defaultTable,
      archived: false,
    );

    final success = await backend.createOrder(client, draft);
    if (!success) {
      throw TestFailure('Bestellung konnte nicht angelegt werden.');
    }

    final result = await backend.fetchOrders(client);
    if (!result.isSuccess || result.data == null) {
      throw TestFailure('Bestellungen konnten nicht geladen werden.');
    }

    return result.data!.lastWhere(
      (order) =>
          order.table?.id == defaultTable.id &&
          order.items.any((item) => item.item.id == menuItem.id),
      orElse: () => throw TestFailure('Neue Bestellung nicht gefunden.'),
    );
  }

  setUpAll(() async {
    appState = AppState(BackendProxy(), http.Client());
    backend = BackendProxy();
    client = http.Client();
    await assertBackendReachable(client);
  });

  tearDownAll(() async {
    try {} finally {
      appState.dispose();
      client.close();
    }
  });

  group('MenuItem Vorgänge: ', () {
    String itemName1 = 'Pizza Margherita';
    String itemPrice1 = '12.50';
    String itemDesc1 = 'Vegetarisch, Käse und Tomaten';

    String itemName2 = 'Pizza Salami';
    String itemPrice2 = '13.59';
    String itemDesc2 = 'Käse, Tomaten und Salami';

    String itemName3 = 'Spezi';
    String itemPrice3 = '4.2';
    String itemDesc3 = '';

    String itemName4 = 'Wasser';
    String itemPrice4 = '10';
    String itemDesc4 = 'Still';
    testWidgets("Erstellung", (WidgetTester tester) async {
      await openMenuItemView(tester: tester, appState: appState);

      expect(itemListEntry(itemName1), findsNothing);
      expect(itemListEntry(itemPrice1), findsNothing);
      expect(itemListEntry(itemDesc1), findsNothing);

      // Item 1 mit Validation erstellen
      await createMenuItemFlow(
        tester: tester,
        itemName: itemName1,
        itemPrice: itemPrice1,
        itemDesc: itemDesc1,
        testValidation: true,
      );

      expect(itemListEntry(itemName1), findsOneWidget);
      expect(itemListEntry('€$itemPrice1'), findsOneWidget);
      expect(itemListEntry(itemDesc1), findsOneWidget);

      // Item 2 ohne Validation
      await createMenuItemFlow(
        tester: tester,
        itemName: itemName2,
        itemPrice: itemPrice2,
        itemDesc: itemDesc2,
      );

      // Item 3 ohne Validation
      await createMenuItemFlow(
        tester: tester,
        itemName: itemName3,
        itemPrice: itemPrice3,
        itemDesc: itemDesc3,
      );

      // Item 4 ohne Validation und Erstellungsabbruch
      await createMenuItemFlow(
        tester: tester,
        itemName: itemName4,
        itemPrice: itemPrice4,
        itemDesc: itemDesc4,
        cancelCreation: true,
      );

      // Alle Items in der Liste
      expect(itemListEntry(itemName1), findsOneWidget);
      expect(itemListEntry('€$itemPrice1'), findsOneWidget);
      expect(itemListEntry(itemDesc1), findsOneWidget);
      expect(itemListEntry(itemName2), findsOneWidget);
      expect(itemListEntry('€$itemPrice2'), findsOneWidget);
      expect(itemListEntry(itemDesc2), findsOneWidget);
      expect(itemListEntry(itemName3), findsOneWidget);
      expect(itemListEntry('€$itemPrice3'), findsNothing);
      expect(
        itemListEntry('€${itemPrice3}0'),
        findsOneWidget,
      ); //UI zeigt immer zwei Nachkommastellen an ggf. mit 0ern wenn nur eine angegeben wurde
      expect(itemListEntry(itemDesc3), findsOneWidget);
      expect(itemListEntry(itemName4), findsNothing);
      expect(itemListEntry(itemPrice4), findsNothing);
      expect(itemListEntry(itemDesc4), findsNothing);

      // Kurze Pause
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('Löschen', (WidgetTester tester) async {
      MenuItemModel item5 = MenuItemModel(
        id: null,
        name: 'Cola',
        price: 3.40,
        archived: false,
        description: 'Zero Sugar',
        version: 1,
      );
      expect(await backend.createMenuItem(client, item5), isTrue);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();

      await openMenuItemView(tester: tester, appState: appState);

      await deleteMenuItemFlow(
        tester: tester,
        itemName: item5.name,
        mouse: mouse,
        cancelDeletion: true,
      );

      await deleteMenuItemFlow(
        tester: tester,
        itemName: item5.name,
        mouse: mouse,
      );

      await deleteMenuItemFlow(
        tester: tester,
        itemName: itemName1,
        mouse: mouse,
      );
    });
    testWidgets('Bearbeiten', (WidgetTester tester) async {
      String newItemPrice2 = '20.42';
      String fakeName = 'Wird abgebrochen 12345';
      await openMenuItemView(tester: tester, appState: appState);

      expect(itemListEntry(itemName2), findsOneWidget);
      expect(itemListEntry(fakeName), findsNothing);
      await changeMenuItemFlow(
        tester: tester,
        itemName: itemName2,
        newName: fakeName,
        cancelChange: true,
      );

      //await tester.pumpAndSettle();
      expect(itemListEntry(itemName2), findsOneWidget);
      expect(itemListEntry(fakeName), findsNothing);

      expect(itemListEntry('€$itemPrice2'), findsOneWidget);
      expect(itemListEntry('€$newItemPrice2'), findsNothing);

      await changeMenuItemFlow(
        tester: tester,
        itemName: itemName2,
        newPrice: newItemPrice2,
      );

      expect(itemListEntry('€$itemPrice2'), findsNothing);
      expect(itemListEntry('€$newItemPrice2'), findsOneWidget);
    });
  });

  // ===================================================================
  // ===================  BAR ORDER INTEGRATION TESTS  ===================
  // ===================================================================

  group('Bestellung Vorgänge: ', () {
    // Setup legt die Getränke-Fiktion an, auf die die Order-Tests zugreifen.
    setUpAll(() async {
      final tables = await backend.fetchTables(client);
      if (tables.isEmpty) {
        throw TestFailure('Keine Tische im Backend vorhanden.');
      }
      defaultTable = tables.first;

      creationItem = await createMenuItemFixture(
        baseName: 'Latte Macchiato',
        price: 3.8,
      );
      updateItem = await createMenuItemFixture(
        baseName: 'Cappuccino',
        price: 3.2,
      );
      archiveItem = await createMenuItemFixture(
        baseName: 'Espresso',
        price: 2.6,
      );
      deleteItem = await createMenuItemFixture(
        baseName: 'Orangensaft',
        price: 4.5,
      );
    });

    testWidgets('Erstellung', (WidgetTester tester) async {
      // Erwartet, dass ein neuer Eintrag sichtbar wird, sobald die Bestellung erstellt ist.
      await openOrderView(tester: tester, appState: appState);

      final totalFinder = orderTotalText(creationItem.price);
      expect(totalFinder, findsNothing);

      await createOrderFlow(tester: tester, menuItem: creationItem);

      await pumpUntilFound(tester, totalFinder);
      final tile = find.ancestor(
        of: totalFinder,
        matching: find.byType(order_widgets.OrderItem),
      );
      await pumpUntilFound(tester, tile);
      final orderWidget = tester.widget<order_widgets.OrderItem>(tile);
      final orderId = orderWidget.order.id;
      expect(orderId, isNotNull);
      expect(orderId, isNotNull);
    });

    testWidgets('Bearbeiten', (WidgetTester tester) async {
      // Erhöht die Bestellmenge und prüft die angepasste Gesamtsumme.
      final order = await createOrderFixture(menuItem: updateItem);
      final orderId = order.id!;

      await openOrderView(tester: tester, appState: appState);

      await increaseOrderQuantityFlow(
        tester: tester,
        orderId: orderId,
        tableId: defaultTable.id,
      );

      final tile = orderTile(orderId, defaultTable.id);
      await pumpUntilFound(tester, tile);

      await pumpUntilFound(
        tester,
        find.descendant(of: tile, matching: orderArticlesLabel(2)),
      );

      await pumpUntilFound(tester, orderTotalText(updateItem.price * 2));
      expect(orderTotalText(updateItem.price), findsNothing);
    });

    testWidgets('Archivieren', (WidgetTester tester) async {
      // Archiviert die Bestellung und prüft, dass der Button verschwindet.
      final order = await createOrderFixture(menuItem: archiveItem);
      final orderId = order.id!;

      await openOrderView(tester: tester, appState: appState);

      await archiveOrderFlow(
        tester: tester,
        orderId: orderId,
        tableId: defaultTable.id,
      );

      final tile = orderTile(orderId, defaultTable.id);
      await pumpUntilFound(tester, tile);

      await pumpUntilFound(
        tester,
        find.descendant(of: tile, matching: orderArchivedIcon()),
      );
      expect(
        find.descendant(of: tile, matching: orderArchiveButton()),
        findsNothing,
      );
    });

    testWidgets('Löschen', (WidgetTester tester) async {
      // Löscht die Bestellung vollständig aus der Liste.
      final order = await createOrderFixture(menuItem: deleteItem);
      final orderId = order.id!;

      await openOrderView(tester: tester, appState: appState);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(() async {
        await mouse.removePointer();
      });

      await deleteOrderFlow(
        tester: tester,
        orderId: orderId,
        tableId: defaultTable.id,
        mouse: mouse,
      );

      await pumpUntilGone(tester, orderTile(orderId, defaultTable.id));
      // Bestellung verbleibt im Backend bis zum nächsten Neustart
    });
  });
}
