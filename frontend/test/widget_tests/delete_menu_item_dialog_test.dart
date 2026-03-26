import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart'; // Import für MenuItemModel
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/widgets/button/delete_menu_item_button.dart';
import 'package:frontend/widgets/dialog/delete_menu_item_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import './delete_menu_item_dialog_test.mocks.dart';

final menuItem = MenuItemModel(
  id: 1,
  name: 'Pizza Margherita',
  price: 10.0,
  version: 1,
  archived: false,
  description: '',
); // Konstanten durch MenuItemModel ersetzt

/// AppState-Subklasse, um den zuletzt gesetzten ConnectionStatus abzufangen.
class TestAppState extends AppState {
  ConnectionStatus? lastConnectionStatus;

  TestAppState(super.backend, super.client);

  @override
  void setConnectionStatus(ConnectionStatus status) {
    lastConnectionStatus = status;
    super.setConnectionStatus(status);
  }
}

/// Mockito-Mock für den Callback onCreated (VoidCallback)
class MockOnCreated extends Mock {
  void call();
}

/// Mockito-Mocks für Backend und HTTP-Client
@GenerateMocks([BackendProxy, http.Client])
void main() {
  /// Hilfsfunktion: AppState erzeugen und checkConnectionStatus stubben
  TestAppState createTestAppState(MockBackendProxy backend, MockClient client) {
    when(
      backend.checkConnectionStatus(client),
    ).thenAnswer((_) async => ConnectionStatus.online);
    return TestAppState(backend, client);
  }

  /// Test-App mit Button, der direkt den Dialog öffnet
  Widget buildTestAppWithOpenButton({
    required TestAppState appState,
    required void Function(bool? result) onDialogResult,
  }) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => DeleteMenuItemDialog(
                        menuItem: menuItem, // Übergibt das MenuItemModel direkt
                      ),
                    );
                    onDialogResult(result);
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Test-App mit DeleteMenuItemButton, der intern showDeleteMenuItemDialog nutzt
  Widget buildAppWithDeleteButton({
    required TestAppState appState,
    required VoidCallback onCreated,
  }) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: DeleteMenuItemButton(
              menuItem:
                  menuItem, // Übergibt MenuItemModel statt Name und ID getrennt
              onCreated: onCreated,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tests für DeleteMenuItemDialog direkt
  // ---------------------------------------------------------------------------

  testWidgets(
    'DeleteMenuItemDialog shows correct UI and cancel closes with false',
    (WidgetTester tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createTestAppState(backend, client);

      bool? dialogResult;
      await tester.pumpWidget(
        buildTestAppWithOpenButton(
          appState: appState,
          onDialogResult: (result) => dialogResult = result,
        ),
      );

      // Dialog öffnen
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // UI prüfen
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Eintrag löschen?'), findsOneWidget);
      expect(
        find.text(
          'Möchtest du "${menuItem.name}" wirklich löschen?',
        ), // Nutzt menuItem.name
        findsOneWidget,
      );
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Löschen'), findsOneWidget);

      // Abbrechen -> Dialog zu, Backend nicht aufgerufen
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(dialogResult, isFalse);
      verifyNever(backend.deleteMenuItem(any, any));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DeleteMenuItemDialog successful delete sets online status and returns true',
    (WidgetTester tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createTestAppState(backend, client);

      // Backend soll erfolgreich löschen
      when(
        backend.deleteMenuItem(client, menuItem), // Verwendet menuItem.id
      ).thenAnswer((_) async => true);

      bool? dialogResult;
      await tester.pumpWidget(
        buildTestAppWithOpenButton(
          appState: appState,
          onDialogResult: (result) => dialogResult = result,
        ),
      );

      // Dialog öffnen
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Löschen klicken
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      // Backend wurde aufgerufen
      verify(
        backend.deleteMenuItem(client, menuItem),
      ).called(1); // Prüft Aufruf mit menuItem.id

      // Dialog zu, Ergebnis true
      expect(find.byType(AlertDialog), findsNothing);
      expect(dialogResult, isTrue);

      // ConnectionStatus online
      expect(appState.lastConnectionStatus, ConnectionStatus.online);

      // Erfolgsmeldung im SnackBar
      expect(
        find.text('Item gelöscht: ${menuItem.name}'),
        findsOneWidget,
      ); // Erwartet Erfolgsmeldung mit menuItem.name
      expect(
        find.text('Fehler beim löschen von ${menuItem.name}'),
        findsNothing,
      ); // Keine Fehlermeldung mit menuItem.name

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DeleteMenuItemDialog timeout sets offline status and returns false',
    (WidgetTester tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createTestAppState(backend, client);

      // Backend wirft TimeoutException
      when(
        backend.deleteMenuItem(client, menuItem), // Verwendet menuItem.id
      ).thenAnswer((_) => Future<bool>.error(TimeoutException('timeout')));

      bool? dialogResult;
      await tester.pumpWidget(
        buildTestAppWithOpenButton(
          appState: appState,
          onDialogResult: (result) => dialogResult = result,
        ),
      );

      // Dialog öffnen
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Löschen klicken
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      // Backend wurde aufgerufen
      verify(
        backend.deleteMenuItem(client, menuItem),
      ).called(1); // Prüft Aufruf mit menuItem.id

      // Dialog zu, Ergebnis false
      expect(find.byType(AlertDialog), findsNothing);
      expect(dialogResult, isFalse);

      // ConnectionStatus offline
      expect(appState.lastConnectionStatus, ConnectionStatus.offline);

      // Mindestens eine Fehlermeldung sichtbar (Timeout),
      // aber KEINE Erfolgsmeldung.
      expect(find.text('Request times out'), findsOneWidget);
      expect(
        find.text('Item gelöscht: ${menuItem.name}'),
        findsNothing,
      ); // Keine Erfolgsmeldung mit menuItem.name

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DeleteMenuItemButton calls onCreated when dialog returns true', (
    WidgetTester tester,
  ) async {
    final backend = MockBackendProxy();
    final client = MockClient();
    final appState = createTestAppState(backend, client);
    final onCreated = MockOnCreated();

    // Backend soll erfolgreich löschen
    when(
      backend.deleteMenuItem(client, menuItem),
    ).thenAnswer((_) async => true); // Erfolgsantwort für menuItem.id

    await tester.pumpWidget(
      buildAppWithDeleteButton(appState: appState, onCreated: onCreated.call),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DeleteMenuItemButton), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Delete-Button -> Dialog
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);

    // Im Dialog "Löschen" klicken
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    // Backend wurde aufgerufen
    verify(
      backend.deleteMenuItem(client, menuItem),
    ).called(1); // Prüft Aufruf mit menuItem.id

    // Dialog zu
    expect(find.byType(AlertDialog), findsNothing);

    // ConnectionStatus online + Erfolg-SnackBar
    expect(appState.lastConnectionStatus, ConnectionStatus.online);
    expect(
      find.text('Item gelöscht: ${menuItem.name}'),
      findsOneWidget,
    ); // Erfolgsmeldung mit menuItem.name

    // onCreated wurde aufgerufen
    verify(onCreated()).called(1);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'DeleteMenuItemButton does not call onCreated when dialog is cancelled',
    (WidgetTester tester) async {
      final backend = MockBackendProxy();
      final client = MockClient();
      final appState = createTestAppState(backend, client);
      final onCreated = MockOnCreated();

      await tester.pumpWidget(
        buildAppWithDeleteButton(appState: appState, onCreated: onCreated.call),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DeleteMenuItemButton), findsOneWidget);

      // Button -> Dialog
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);

      // Abbrechen
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Dialog zu
      expect(find.byType(AlertDialog), findsNothing);

      // Backend NICHT aufgerufen
      verifyNever(backend.deleteMenuItem(any, any));

      // onCreated NICHT aufgerufen
      verifyNever(onCreated());

      // Keine SnackBars
      expect(
        find.text('Item gelöscht: ${menuItem.name}'),
        findsNothing,
      ); // Keine Erfolgsmeldung mit menuItem.name
      expect(
        find.text('Fehler beim löschen von ${menuItem.name}'),
        findsNothing,
      ); // Keine Fehlermeldung mit menuItem.name

      expect(tester.takeException(), isNull);
    },
  );
}
