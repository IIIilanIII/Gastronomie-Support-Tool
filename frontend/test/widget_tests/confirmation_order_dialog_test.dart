import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/dialog/confirmation_order_dialog.dart';
import 'package:http/http.dart' as http;

class _StubBackend extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async =>
      FetchResult.success(<OrderModel>[]);
}

OrderModel _order() => OrderModel(
  id: 42,
  items: <OrderItemModel>[],
  table: TableModel(id: 7),
  archived: false,
);

Future<void> _pumpAndOpen(
  WidgetTester tester, {
  required AppState appState,
  required Future<bool> Function(OrderModel) action,
  String confirmActionLabel = 'archivieren',
  String successStateLabel = 'archiviert',
  String? successMessage,
}) async {
  await tester.pumpWidget(
    AppStateScope(
      notifier: appState,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ConfirmationOrderDialog(
                      order: _order(),
                      confirmActionLabel: confirmActionLabel,
                      successStateLabel: successStateLabel,
                      action: action,
                      successMessage: successMessage,
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  group('ConfirmationOrderDialog', () {
    testWidgets('renders dialog content', (tester) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(tester, appState: appState, action: (_) async => true);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Bestellung archivieren'), findsOneWidget);
      expect(
        find.textContaining(
          'Möchtest du Bestellung 42 an Tisch 7 wirklich archivieren?',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Abbrechen'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Archivieren'), findsOneWidget);
    });

    testWidgets('Abbrechen closes dialog', (tester) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(tester, appState: appState, action: (_) async => true);

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('success -> sets online, shows success snackbar, closes', (
      tester,
    ) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(tester, appState: appState, action: (_) async => true);

      await tester.tap(find.widgetWithText(TextButton, 'Archivieren'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(appState.cStatus, ConnectionStatus.online);
      expect(find.textContaining('Bestellung archiviert: 42'), findsOneWidget);
    });

    testWidgets('success -> uses custom success message when provided', (
      tester,
    ) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(
        tester,
        appState: appState,
        action: (_) async => true,
        confirmActionLabel: 'löschen',
        successStateLabel: 'gelöscht',
        successMessage: 'Erfolgreich',
      );

      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Erfolgreich'), findsOneWidget);
    });

    testWidgets('false -> shows error snackbar, closes', (tester) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(
        tester,
        appState: appState,
        action: (_) async => false,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Archivieren'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.textContaining('Fehler beim archivieren von 42'),
        findsOneWidget,
      );
    });

    testWidgets('timeout -> sets offline, shows timeout snackbar, closes', (
      tester,
    ) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(
        tester,
        appState: appState,
        action: (_) async => throw TimeoutException('t'),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Archivieren'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(appState.cStatus, ConnectionStatus.offline);
      expect(find.textContaining('Request times out'), findsOneWidget);
    });

    testWidgets('exception -> sets offline, shows exception snackbar, closes', (
      tester,
    ) async {
      final appState = AppState(_StubBackend(), http.Client());

      await _pumpAndOpen(
        tester,
        appState: appState,
        action: (_) async => throw Exception('boom'),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Archivieren'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(appState.cStatus, ConnectionStatus.offline);
      expect(find.textContaining('Exception: boom'), findsOneWidget);
    });
  });

  group('refreshToken', () {
    testWidgets('dialog does not bump orderListRefreshToken', (tester) async {
      final appState = AppState(_StubBackend(), http.Client());
      final before = appState.orderListRefreshToken;

      await _pumpAndOpen(tester, appState: appState, action: (_) async => true);

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(appState.orderListRefreshToken, before);
    });
  });
}
