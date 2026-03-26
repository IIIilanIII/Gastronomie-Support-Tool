import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/widgets/button/delete_menu_item_button.dart';
import 'package:frontend/widgets/dialog/add_menu_item_dialog.dart';
import 'package:frontend/widgets/list/list_item/menu_item.dart';
import 'package:http/http.dart' as http;

class RecordingBackend extends BackendProxy {
  RecordingBackend({
    this.createResponse,
    this.updateResponse,
    this.connectionStatus = ConnectionStatus.online,
  });

  final Future<bool> Function(MenuItemModel item)? createResponse;
  final Future<bool> Function(MenuItemModel item)? updateResponse;

  MenuItemModel? recordedCreateItem;
  MenuItemModel? recordedUpdateItem;

  int createCallCount = 0;
  int updateCallCount = 0;

  ConnectionStatus connectionStatus;

  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      connectionStatus;

  @override
  Future<bool> createMenuItem(http.Client client, MenuItemModel item) async {
    createCallCount += 1;
    recordedCreateItem = item;
    final fn = createResponse;
    if (fn == null) return false;
    return fn(item);
  }

  @override
  Future<bool> updateMenuItem(http.Client client, MenuItemModel item) async {
    updateCallCount += 1;
    recordedUpdateItem = item;
    final fn = updateResponse;
    if (fn == null) return false;
    return fn(item);
  }
}

class TestAppState extends AppState {
  ConnectionStatus? lastConnectionStatus;
  int bumpCount = 0;

  TestAppState(super.backend, super.client);

  @override
  void setConnectionStatus(ConnectionStatus status) {
    lastConnectionStatus = status;
    super.setConnectionStatus(status);
  }

  @override
  void bumpMenuListRefreshToken() {
    bumpCount++;
    super.bumpMenuListRefreshToken();
  }
}

Finder _nameField() => find.byType(TextFormField).at(0);
Finder _priceField() => find.byType(TextFormField).at(1);
Finder _descriptionField() => find.byType(TextFormField).at(2);

Finder _btn(String label) {
  final textBtn = find.widgetWithText(TextButton, label);
  if (textBtn.evaluate().isNotEmpty) return textBtn;
  return find.widgetWithText(ElevatedButton, label);
}

bool _isEnabled(WidgetTester tester, Finder button) {
  final w = tester.widget(button);
  if (w is TextButton) return w.onPressed != null;
  if (w is ElevatedButton) return w.onPressed != null;
  return false;
}

Future<void> _pumpStable(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(); // post-frame validity/onChanged
}

Future<BuildContext> _pumpHostApp(WidgetTester tester, AppState state) async {
  late BuildContext hostContext;

  await tester.pumpWidget(
    AppStateScope(
      notifier: state,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  return hostContext;
}

void main() {
  group('AddMenuItemDialog', () {
    testWidgets('requires a name before submitting', (tester) async {
      final backend = RecordingBackend(createResponse: (_) async => true);
      final appState = AppState(backend, http.Client());
      addTearDown(appState.dispose);

      final context = await _pumpHostApp(tester, appState);

      final resultFuture = showAddMenuItemDialog(context);
      await _pumpStable(tester);

      await tester.enterText(_nameField(), '');
      await tester.pump();
      expect(find.text('Bitte Namen eingeben'), findsOneWidget);

      expect(_isEnabled(tester, _btn('Erstellen')), isFalse);

      await tester.tap(_btn('Abbrechen'));
      await tester.pumpAndSettle();

      expect(await resultFuture, isFalse);
      expect(backend.createCallCount, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('submits payload and shows success snackbar', (tester) async {
      final backend = RecordingBackend(createResponse: (_) async => true);
      final appState = AppState(backend, http.Client());
      addTearDown(appState.dispose);

      final context = await _pumpHostApp(tester, appState);

      final resultFuture = showAddMenuItemDialog(context);
      await _pumpStable(tester);

      await tester.enterText(_nameField(), 'Cola');
      await tester.enterText(_priceField(), '5,5');
      await tester.enterText(_descriptionField(), 'Erfrischend');
      await _pumpStable(tester);

      final createBtn = _btn('Erstellen');
      expect(_isEnabled(tester, createBtn), isTrue);

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(await resultFuture, isTrue);
      expect(appState.cStatus, ConnectionStatus.online);

      expect(backend.createCallCount, 1);
      expect(backend.recordedCreateItem?.name, 'Cola');
      expect(backend.recordedCreateItem?.price, 5.5);
      expect(backend.recordedCreateItem?.description, 'Erfrischend');
      expect(backend.recordedCreateItem?.version, 1);
      expect(backend.recordedCreateItem?.archived, false);

      expect(find.text('Neues Item hinzugefügt: Cola'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows error snackbar when backend returns false', (
      tester,
    ) async {
      final backend = RecordingBackend(
        createResponse: (_) async => false,
        connectionStatus: ConnectionStatus.offline,
      );
      final appState = AppState(backend, http.Client());
      addTearDown(appState.dispose);

      final context = await _pumpHostApp(tester, appState);

      final resultFuture = showAddMenuItemDialog(context);
      await _pumpStable(tester);

      await tester.enterText(_nameField(), 'Fanta');
      await tester.enterText(_priceField(), '3.0');
      await tester.enterText(_descriptionField(), 'Orange');
      await _pumpStable(tester);

      final createBtn = _btn('Erstellen');
      expect(_isEnabled(tester, createBtn), isTrue);

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(await resultFuture, isFalse);
      expect(appState.cStatus, ConnectionStatus.offline);
      expect(
        find.text('Fehler beim Erstellen des Items Fanta'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows exception message when backend throws', (tester) async {
      final backend = RecordingBackend(
        createResponse: (_) async => throw Exception('kaputt'),
        connectionStatus: ConnectionStatus.offline,
      );
      final appState = AppState(backend, http.Client());
      addTearDown(appState.dispose);

      final context = await _pumpHostApp(tester, appState);

      final resultFuture = showAddMenuItemDialog(context);
      await _pumpStable(tester);

      await tester.enterText(_nameField(), 'Sprite');
      await tester.enterText(_priceField(), '2.5');
      await tester.enterText(_descriptionField(), 'Lemon');
      await _pumpStable(tester);

      final createBtn = _btn('Erstellen');
      expect(_isEnabled(tester, createBtn), isTrue);

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(await resultFuture, isFalse);
      expect(appState.cStatus, ConnectionStatus.offline);
      expect(find.textContaining('Fehler:'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('MenuItem (extra coverage)', () {
    testWidgets('hover toggles delete button visibility', (tester) async {
      final backend = RecordingBackend(
        createResponse: (_) async => true,
        updateResponse: (_) async => true,
      );
      final client = http.Client();
      final appState = TestAppState(backend, client);
      addTearDown(appState.dispose);
      addTearDown(client.close);

      final item = MenuItemModel(
        id: 7,
        name: 'Test Item',
        description: 'Desc',
        price: 1.23,
        version: 1,
        archived: false,
      );

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: MenuItem(menuItem: item)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeleteMenuItemButton), findsNothing);

      // pick a MouseRegion inside MenuItem that actually reacts to hover
      final regionsFinder = find.descendant(
        of: find.byType(MenuItem),
        matching: find.byType(MouseRegion),
      );
      final regions = tester.widgetList<MouseRegion>(regionsFinder).toList();
      final hoverRegions = regions
          .where((r) => r.onEnter != null && r.onExit != null)
          .toList();
      expect(hoverRegions.isNotEmpty, isTrue);

      final hoverRegionWidget = hoverRegions.first;
      final hoverRegionFinder = find.byWidget(hoverRegionWidget);
      final center = tester.getCenter(hoverRegionFinder);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(center);
      await tester.pumpAndSettle();

      expect(find.byType(DeleteMenuItemButton), findsOneWidget);

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.byType(DeleteMenuItemButton), findsNothing);
    });

    testWidgets('change dialog success triggers handleCreated -> bump token', (
      tester,
    ) async {
      final backend = RecordingBackend(
        updateResponse: (_) async => true,
        connectionStatus: ConnectionStatus.online,
      );
      final client = http.Client();
      final appState = TestAppState(backend, client);
      addTearDown(appState.dispose);
      addTearDown(client.close);

      final item = MenuItemModel(
        id: 8,
        name: 'EditMe',
        description: 'Desc',
        price: 2.50,
        version: 1,
        archived: false,
      );

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: MenuItem(menuItem: item)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(item.name));
      await _pumpStable(tester);

      final save = _btn('Speichern');
      expect(_isEnabled(tester, save), isTrue);

      await tester.enterText(_nameField(), 'EditMe2');
      await tester.pump();

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(backend.updateCallCount, 1);
      expect(appState.bumpCount, 1);
      expect(appState.lastConnectionStatus, ConnectionStatus.online);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
