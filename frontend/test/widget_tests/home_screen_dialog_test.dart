import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_screen_dialog_test.mocks.dart';

class StubBackend extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async {
    return ConnectionStatus.online;
  }

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    // in case HomeScreen triggers menu loading
    return FetchResult.success(<MenuItemModel>[]);
  }

  @override
  Future<bool> createMenuItem(http.Client client, MenuItemModel item) async {
    return true;
  }

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);

  @override
  Future<List<TableModel>> fetchTables(http.Client client) async =>
      <TableModel>[TableModel(id: 1), TableModel(id: 2)];
}

@GenerateMocks([BackendProxy])
void main() {
  testWidgets('tapping add opens dialog and adds local item', (tester) async {
    final appState = AppState(StubBackend(), http.Client());
    appState.setTab(AppTab.menu);

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final addFinder = find.byIcon(Icons.add);
    expect(addFinder, findsOneWidget);

    await tester.tap(addFinder);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3));

    await tester.enterText(textFields.at(0), 'Test Pizza');
    await tester.enterText(textFields.at(1), '7.5');
    await tester.enterText(textFields.at(2), 'Tasty');

    await tester.tap(find.text('Erstellen'));
    await tester.pump(); // loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Neues Item hinzugefügt: Test Pizza'), findsOneWidget);
  });

  testWidgets('tapping add opens dialog and closing it afterwards', (
    tester,
  ) async {
    final backend = MockBackendProxy();

    when(
      backend.checkConnectionStatus(any),
    ).thenAnswer((_) async => ConnectionStatus.online);
    when(
      backend.fetchOrders(any),
    ).thenAnswer((_) async => FetchResult.success(<OrderModel>[]));

    // CHANGED: FetchResult wrapper
    when(
      backend.fetchMenuItems(any),
    ).thenAnswer((_) async => FetchResult.success(<MenuItemModel>[]));

    when(backend.fetchTables(any)).thenAnswer(
      (_) async => <TableModel>[TableModel(id: 1), TableModel(id: 2)],
    );

    final appState = AppState(backend, http.Client());
    appState.setTab(AppTab.order);

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    verify(backend.fetchOrders(any)).called(1);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Abbrechen').first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Erstellen').first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
