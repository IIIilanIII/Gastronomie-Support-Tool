import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/list/menu_list.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' show PointerDeviceKind;
import 'package:frontend/models/menu_item_model.dart';

MenuItemModel _menuItem(
  int id,
  String name, {
  String description = '',
  double price = 0.0,
  bool pending = false,
  int version = 1,
  bool archived = false,
}) => MenuItemModel(
  id: id,
  name: name,
  description: description,
  price: price,
  version: version,
  archived: archived,
);

class StubWithItems extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success([
      _menuItem(
        1,
        'Pizza Margherita',
        description: 'Lecker',
        price: 8.5,
        pending: true,
        version: 1,
        archived: false,
      ),
    ]);
  }
}

class StubBackendEmpty extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async => FetchResult.success([]);
}

class StubDelayedItems extends BackendProxy {
  final Completer<FetchResult<List<MenuItemModel>>> completer =
      Completer<FetchResult<List<MenuItemModel>>>();

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(http.Client client) =>
      completer.future;

  void completeWithItems() {
    completer.complete(
      FetchResult.success([
        MenuItemModel(
          id: 10,
          name: 'Latte',
          version: 1,
          archived: false,
          description: '',
          price: 12.0,
        ),
      ]),
    );
  }
}

class StubWithVariants extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success([
      _menuItem(
        1,
        'Coffee',
        description: '',
        price: 3.5,
        pending: false,
        version: 1,
        archived: false,
      ),
      _menuItem(2, 'Tea', pending: true, version: 1, archived: false),
    ]);
  }
}

class StubWithArchived extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success([
      _menuItem(1, 'Aktives Gericht', version: 1, archived: false),
      _menuItem(2, 'Archiviertes Gericht', version: 2, archived: true),
    ]);
  }
}

class StubWithVersions extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success([
      _menuItem(1, 'Burger', version: 1, archived: false),
      _menuItem(2, 'Salat', version: 2, archived: false),
    ]);
  }
}

void main() {
  testWidgets('MenuList shows empty message when no items', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubBackendEmpty(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: ''),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Keine Menüpunkte vorhanden.'), findsOneWidget);
  });

  testWidgets('MenuList shows loading indicator until data arrives', (
    WidgetTester tester,
  ) async {
    final stub = StubDelayedItems();
    final appState = AppState(stub, http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: ''),
          ),
        ),
      ),
    );

    // Erste Pump-Phase zeigt noch den Ladeindikator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Backend liefert nun echte MenuItemModel-Einträge nach
    stub.completeWithItems();

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Latte'), findsOneWidget);
  });

  testWidgets('MenuList test mousehover on item', (WidgetTester tester) async {
    final appState = AppState(StubWithVariants(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: ''),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final teaText = find.text('Tea');
    final coffeeText = find.text('Coffee');
    expect(coffeeText, findsOneWidget);
    expect(teaText, findsOneWidget);

    final teaCard = find.ancestor(of: teaText, matching: find.byType(ListTile));
    expect(teaCard, findsOneWidget);

    final coffeeCard = find.ancestor(
      of: coffeeText,
      matching: find.byType(ListTile),
    );
    expect(coffeeCard, findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();

    // Maus in die Mitte der Card bewegen
    await gesture.moveTo(tester.getCenter(coffeeCard));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await gesture.moveTo(tester.getCenter(teaCard));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await gesture.removePointer();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('MenuList filters archived:true', (WidgetTester tester) async {
    final appState = AppState(StubWithArchived(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'archived:true'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Archiviertes Gericht'), findsOneWidget);
    expect(find.text('Aktives Gericht'), findsNothing);
  });

  testWidgets('MenuList filters archived:false', (WidgetTester tester) async {
    final appState = AppState(StubWithArchived(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'archived:false'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aktives Gericht'), findsOneWidget);
    expect(find.text('Archiviertes Gericht'), findsNothing);
  });

  testWidgets('MenuList filters items by version query', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubWithVersions(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'version:2'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Salat'), findsOneWidget);
    expect(find.text('Burger'), findsNothing);
  });

  testWidgets('MenuList shows hint when no version matches', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubWithVersions(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'version:3'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Keine Menüpunkte für Version 3 gefunden.'),
      findsOneWidget,
    );
  });

  testWidgets('MenuList filters by plain text (name)', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubWithVersions(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'sal'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Salat'), findsOneWidget);
    expect(find.text('Burger'), findsNothing);
  });

  testWidgets('MenuList shows no-text-match message', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubWithVariants(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'xyz'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Keine Treffer für "xyz" gefunden.'), findsOneWidget);
  });

  testWidgets('MenuList parses number-only query as version', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubWithVersions(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: '2'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Salat'), findsOneWidget);
    expect(find.text('Burger'), findsNothing);
  });

  testWidgets('MenuList treats `archived` with no value as true', (
    WidgetTester tester,
  ) async {
    final appState = AppState(StubWithArchived(), http.Client());

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: appState,
          child: const Scaffold(
            body: MenuList(refreshToken: 0, searchQuery: 'archived'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Archiviertes Gericht'), findsOneWidget);
    expect(find.text('Aktives Gericht'), findsNothing);
  });
}
