import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/main.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/widgets/button/add_menu_button.dart';
import 'package:frontend/widgets/button/add_order_button.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import './home_screen_test.mocks.dart';

const _backend = "http://localhost:8080";

class _StubBackendProxy extends BackendProxy {
  bool createOrderCalled = false;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<bool> createOrder(http.Client client, OrderModel order) async {
    createOrderCalled = true;
    return true;
  }

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success([
      MenuItemModel(
        id: 1,
        name: 'Test Item',
        description: 'Test',
        price: 5.0,
        version: 1,
        archived: false,
      ),
    ]);
  }

  @override
  Future<List<TableModel>> fetchTables(http.Client client) async {
    return [TableModel(id: 1)];
  }
}

@GenerateMocks([http.Client])
void main() {
  testWidgets('buildApp without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(MyHomePage), findsOneWidget);
  });

  testWidgets('Window opens with correct default screen', (
    WidgetTester tester,
  ) async {
    final client = MockClient();
    //Konsequenz der HTTP Mocks wird in eigenem Test überprüft
    when(
      client.get(Uri.parse(_backend)),
    ).thenThrow(Exception("Backend nicht erreichbar"));

    final appState = AppState(BackendProxy(), client);
    await tester.pumpWidget(
      AppStateScope(notifier: appState, child: const MyApp()),
    );

    await tester.pump();

    final String bestellungLabel = AppTab.order.label;
    final String menuItemLabel = AppTab.menu.label;

    //Standard View soll Bestellungen sein
    expect(find.text(bestellungLabel), findsOneWidget);
    expect(find.byType(AddOrderButton), findsOneWidget);
    expect(find.byType(SearchBar), findsNothing);

    //View wechsel auf MenuItems
    await tester.tap(find.byKey(Key(menuItemLabel)));
    //View Wechsel MUSS abgeschlossen sein, wartet der Test hier entsprechend
    await tester.pumpAndSettle();
    expect(find.text(menuItemLabel), findsOneWidget);
    expect(find.byType(AddMenuButton), findsOneWidget);
    final searchFinder = find.byType(SearchBar);
    expect(searchFinder, findsOneWidget);
    expect(
      tester.widget<SearchBar>(searchFinder).hintText,
      contains(menuItemLabel),
    );

    //alle Icons werden erwartet
    expect(find.byIcon(AppTab.order.icon), findsOneWidget);
    //expect(find.byIcon(AppTab.tisch.icon), findsOneWidget);
    expect(find.byIcon(AppTab.menu.icon), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets("Correct connection status in UI", (WidgetTester tester) async {
    final client = MockClient();
    when(
      client.get(Uri.parse(_backend)),
    ).thenThrow(Exception("Backend nicht erreichbar"));

    AppState appState = AppState(BackendProxy(), client);
    await tester.pumpWidget(
      AppStateScope(notifier: appState, child: const MyApp()),
    );

    await tester.pump();
    expect(find.text(ConnectionStatus.offline.message), findsOneWidget);
    expect(find.text(ConnectionStatus.online.message), findsNothing);

    when(
      client.get(Uri.parse(_backend)),
    ).thenAnswer((_) async => http.Response('Not Found', 404));

    appState = AppState(BackendProxy(), client);
    await tester.pumpWidget(
      AppStateScope(notifier: appState, child: const MyApp()),
    );
    await tester.pump();
    expect(find.text(ConnectionStatus.offline.message), findsNothing);
    expect(find.text(ConnectionStatus.online.message), findsOneWidget);
  });

  testWidgets('AddOrderButton success bumps refresh token', (
    WidgetTester tester,
  ) async {
    final backend = _StubBackendProxy();
    final client = MockClient();
    final appState = AppState(backend, client);

    await tester.pumpWidget(
      AppStateScope(notifier: appState, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    final before = appState.orderListRefreshToken;

    await tester.tap(find.byType(AddOrderButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Erstellen'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.createOrderCalled, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(appState.orderListRefreshToken, before + 1);
  });
}
