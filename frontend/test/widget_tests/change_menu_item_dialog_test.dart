import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/widgets/dialog/change_menu_item_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'change_menu_item_dialog_test.mocks.dart';

final menuItem = MenuItemModel(
  id: 1,
  name: 'Pizza Margherita',
  description: 'Classic',
  price: 9.90,
  version: 1,
  archived: false,
);

@GenerateMocks([BackendProxy, http.Client])
void main() {
  Finder saveButton() => find.widgetWithText(TextButton, 'Speichern');
  Finder cancelButton() => find.widgetWithText(TextButton, 'Abbrechen');

  bool isTextButtonEnabled(WidgetTester tester, Finder finder) {
    final btn = tester.widget<TextButton>(finder);
    return btn.onPressed != null;
  }

  Future<void> pumpDialogStable(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(); // flush post-frame validity update / onChanged effects
  }

  Finder nameField() => find.byType(TextFormField).at(0);
  Finder priceField() => find.byType(TextFormField).at(1);
  Finder descField() => find.byType(TextFormField).at(2);

  TestAppState createAppState(MockBackendProxy backend, MockClient client) {
    when(
      backend.checkConnectionStatus(client),
    ).thenAnswer((_) async => ConnectionStatus.online);
    return TestAppState(backend, client);
  }

  Widget buildHost({
    required TestAppState appState,
    required MenuItemModel item,
    VoidCallback? onCreated,
  }) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => ChangeMenuItemDialog(
                        menuItem: item,
                        onCreated: onCreated ?? () {},
                      ),
                    );
                  },
                  child: Text(item.name),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  group('ChangeMenuItemDialog', () {
    testWidgets('Abbrechen schließt Dialog', (tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createAppState(backend, client);

      await tester.pumpWidget(buildHost(appState: appState, item: menuItem));
      await tester.pumpAndSettle();

      await tester.tap(find.text(menuItem.name));
      await pumpDialogStable(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(cancelButton(), findsOneWidget);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Speichern success -> online + onCreated', (tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createAppState(backend, client);

      when(backend.updateMenuItem(any, any)).thenAnswer((_) async => true);

      var createdCount = 0;

      await tester.pumpWidget(
        buildHost(
          appState: appState,
          item: menuItem,
          onCreated: () => createdCount++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(menuItem.name));
      await pumpDialogStable(tester);

      expect(isTextButtonEnabled(tester, saveButton()), isTrue);

      await tester.enterText(nameField(), 'New Name');
      await tester.pump();
      expect(isTextButtonEnabled(tester, saveButton()), isTrue);

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      verify(backend.updateMenuItem(client, any)).called(1);
      expect(appState.lastConnectionStatus, ConnectionStatus.online);
      expect(createdCount, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Timeout -> offline + Snack + kein onCreated', (tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createAppState(backend, client);

      when(backend.updateMenuItem(any, any)).thenAnswer((_) {
        return Completer<bool>().future;
      });

      var createdCount = 0;

      await tester.pumpWidget(
        buildHost(
          appState: appState,
          item: menuItem,
          onCreated: () => createdCount++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(menuItem.name));
      await pumpDialogStable(tester);

      expect(isTextButtonEnabled(tester, saveButton()), isTrue);

      await tester.enterText(
        find.text(menuItem.name),
        '${menuItem.name}--',
      ); // sonst kann kein Updaterequest geschickt werden.

      await tester.tap(saveButton());
      await tester.pump(); // start async work
      await tester.pump(const Duration(seconds: 11)); // Timeout auslösen
      await tester.pumpAndSettle();

      verify(backend.updateMenuItem(client, any)).called(1);
      expect(appState.lastConnectionStatus, ConnectionStatus.offline);
      expect(find.text('Request timed out'), findsOneWidget);
      expect(createdCount, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Exception -> offline + Snack + kein onCreated', (
      tester,
    ) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createAppState(backend, client);

      when(backend.updateMenuItem(any, any)).thenThrow(Exception('boom'));

      var createdCount = 0;

      await tester.pumpWidget(
        buildHost(
          appState: appState,
          item: menuItem,
          onCreated: () => createdCount++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(menuItem.name));
      await pumpDialogStable(tester);

      expect(isTextButtonEnabled(tester, saveButton()), isTrue);

      await tester.enterText(
        find.text(menuItem.name),
        '${menuItem.name}--',
      ); // sonst kann kein Updaterequest geschickt werden.

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      verify(backend.updateMenuItem(client, any)).called(1);
      expect(appState.lastConnectionStatus, ConnectionStatus.offline);
      expect(find.textContaining('Fehler:'), findsOneWidget);
      expect(createdCount, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    group('Validation + disabled save', () {
      testWidgets('Empty Name disables save + shows error', (tester) async {
        final backend = MockBackendProxy();
        final client = MockClient();
        final appState = createAppState(backend, client);

        await tester.pumpWidget(buildHost(appState: appState, item: menuItem));
        await tester.pumpAndSettle();

        await tester.tap(find.text(menuItem.name));
        await pumpDialogStable(tester);

        await tester.enterText(nameField(), '');
        await tester.enterText(priceField(), '10.0');
        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.text('Bitte Namen eingeben'), findsOneWidget);
        expect(isTextButtonEnabled(tester, saveButton()), isFalse);
        verifyNever(backend.updateMenuItem(any, any));
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('Empty Price disables save + shows error', (tester) async {
        final backend = MockBackendProxy();
        final client = MockClient();
        final appState = createAppState(backend, client);

        await tester.pumpWidget(buildHost(appState: appState, item: menuItem));
        await tester.pumpAndSettle();

        await tester.tap(find.text(menuItem.name));
        await pumpDialogStable(tester);

        await tester.enterText(nameField(), 'Valid Name');
        await tester.enterText(priceField(), '');
        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.text('Bitte einen Preis eintragen'), findsOneWidget);
        expect(isTextButtonEnabled(tester, saveButton()), isFalse);
        verifyNever(backend.updateMenuItem(any, any));
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('Non-number price disables save + shows error', (
        tester,
      ) async {
        final backend = MockBackendProxy();
        final client = MockClient();
        final appState = createAppState(backend, client);

        await tester.pumpWidget(buildHost(appState: appState, item: menuItem));
        await tester.pumpAndSettle();

        await tester.tap(find.text(menuItem.name));
        await pumpDialogStable(tester);

        await tester.enterText(nameField(), 'Valid Name');
        await tester.enterText(priceField(), 'not-a-number');
        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.text('Ungültiger Preis'), findsOneWidget);
        expect(isTextButtonEnabled(tester, saveButton()), isFalse);
        verifyNever(backend.updateMenuItem(any, any));
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('Too many decimals disables save + shows error', (
        tester,
      ) async {
        final backend = MockBackendProxy();
        final client = MockClient();
        final appState = createAppState(backend, client);

        await tester.pumpWidget(buildHost(appState: appState, item: menuItem));
        await tester.pumpAndSettle();

        await tester.tap(find.text(menuItem.name));
        await pumpDialogStable(tester);

        await tester.enterText(nameField(), 'Valid Name');
        await tester.enterText(priceField(), '1.234');
        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.text('Maximal 2 Nachkommastellen erlaubt'), findsOneWidget);
        expect(isTextButtonEnabled(tester, saveButton()), isFalse);
        verifyNever(backend.updateMenuItem(any, any));
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('Valid fields enables save', (tester) async {
        final backend = MockBackendProxy();
        final client = MockClient();
        final appState = createAppState(backend, client);

        await tester.pumpWidget(buildHost(appState: appState, item: menuItem));
        await tester.pumpAndSettle();

        await tester.tap(find.text(menuItem.name));
        await pumpDialogStable(tester);

        await tester.enterText(nameField(), 'Valid Name');
        await tester.enterText(priceField(), '12,30');
        await tester.enterText(descField(), 'Desc');
        await tester.pumpAndSettle();
        await tester.pump();

        expect(isTextButtonEnabled(tester, saveButton()), isTrue);
      });
    });
  });
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
