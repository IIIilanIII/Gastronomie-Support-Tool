import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/form/order_form.dart';

import 'order_test_utils.dart';

void main() {
  group('OrderForm widget', () {
    group('tables FutureBuilder', () {
      testWidgets('shows loader while tables load', (tester) async {
        final appState = newAppState(StubBackendMinimal());
        final tablesCompleter = Completer<List<TableModel>>();

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () => tablesCompleter.future,
        );

        await openOrderFormDialog(
          tester,
          appState: appState,
          form: form,
          settle: false,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        tablesCompleter.complete([TableModel(id: 1)]);
        await tester.pumpAndSettle();

        expect(
          find.byType(DropdownButtonFormField<TableModel>),
          findsOneWidget,
        );
      });

      testWidgets('shows error text when tables fail', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () => Future.error('boom'),
        );

        await openOrderFormDialog(tester, appState: appState, form: form);
        expect(
          find.textContaining('Fehler beim Laden der Tische'),
          findsOneWidget,
        );
      });

      testWidgets('shows empty tables message', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () async => <TableModel>[],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);
        expect(find.text('Keine verfügbaren Tische'), findsOneWidget);
      });
    });

    group('add item dialog', () {
      testWidgets('fetchMenuItems throws -> snackbar + empty dialog', (
        tester,
      ) async {
        final appState = newAppState(StubBackendMinimal());

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.failure(Exception('kaputt')),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.byKey(const Key('order_add_sub_items')));
        await tester.pumpAndSettle();

        expect(snackBarTextContaining('Fehler beim Laden'), findsOneWidget);
        expect(
          find.byKey(const Key('order_add_sub_items_dialog')),
          findsOneWidget,
        );
        expect(find.text('Keine verfügbaren Artikel'), findsOneWidget);
      });

      testWidgets('archived menu items are filtered out', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        final pizza = mi(2, 'Pizza', 8.94, archived: false);
        final old = mi(99, 'Alt', 1.0, archived: true);

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success([pizza, old]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.byKey(const Key('order_add_sub_items')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('order_add_sub_items_dropdown')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Pizza — 8.94€'), findsWidgets);
        expect(find.textContaining('Alt —'), findsNothing);
      });

      testWidgets('invalid quantity -> shows field error and stays open', (
        tester,
      ) async {
        final appState = newAppState(StubBackendMinimal());
        final pizza = mi(2, 'Pizza', 8.94);

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success([pizza]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.byKey(const Key('order_add_sub_items')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('order_add_sub_items_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pizza — 8.94€').last);
        await tester.pumpAndSettle();

        final dlg = find.byKey(const Key('order_add_sub_items_dialog'));

        final qtyField = find.descendant(
          of: dlg,
          matching: find.byType(TextField),
        );

        await tester.enterText(qtyField, '0');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Hinzufügen'));
        await tester.pump(); // setState() für errorText

        expect(dlg, findsOneWidget);

        expect(
          find.descendant(
            of: dlg,
            matching: find.textContaining(
              'Bitte eine Menge von 1 bis 20 eingeben',
            ),
          ),
          findsOneWidget,
        );
      });

      testWidgets('adding same item twice increases quantity (no duplicates)', (
        tester,
      ) async {
        final appState = newAppState(StubBackendMinimal());
        final pizza = mi(2, 'Pizza', 8.94);

        final order = OrderModel(
          id: 1,
          items: <OrderItemModel>[],
          table: null,
          archived: false,
        );

        final form = makeOrderForm(
          order: order,
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success([pizza]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        Future<void> addQty(String qty) async {
          await tester.tap(find.byKey(const Key('order_add_sub_items')));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('order_add_sub_items_dropdown')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pizza — 8.94€').last);
          await tester.pumpAndSettle();

          final dlg = find.byKey(const Key('order_add_sub_items_dialog'));
          final qtyField = find.descendant(
            of: dlg,
            matching: find.byType(TextField),
          );
          await tester.enterText(qtyField, qty);
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton, 'Hinzufügen'));
          await tester.pumpAndSettle();
        }

        await addQty('2');
        expect(find.text('Artikel (2)'), findsOneWidget);

        await addQty('3');
        expect(find.text('Artikel (5)'), findsOneWidget);

        expect(find.textContaining('Pizza (id: 2) — 8.94€'), findsOneWidget);
      });
    });

    group('items stepper', () {
      testWidgets('minus bis 0 entfernt Item automatisch', (tester) async {
        final appState = newAppState(StubBackendMinimal());
        final pizza = mi(2, 'Pizza', 8.94);

        final form = makeOrderForm(
          order: OrderModel(
            id: 1,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success([pizza]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.byKey(const Key('order_add_sub_items')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('order_add_sub_items_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pizza — 8.94€').last);
        await tester.pumpAndSettle();

        final dlg = find.byKey(const Key('order_add_sub_items_dialog'));
        final qtyField = find.descendant(
          of: dlg,
          matching: find.byType(TextField),
        );
        await tester.enterText(qtyField, '2');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Hinzufügen'));
        await tester.pumpAndSettle();

        expect(find.text('Artikel (2)'), findsOneWidget);

        await tester.tap(iconButtonWithTooltip('Mehr').first);
        await tester.pumpAndSettle();
        expect(find.text('Artikel (3)'), findsOneWidget);

        await tester.tap(iconButtonWithTooltip('Weniger').first);
        await tester.pumpAndSettle();
        expect(find.text('Artikel (2)'), findsOneWidget);

        await tester.tap(iconButtonWithTooltip('Weniger').first);
        await tester.pumpAndSettle();
        expect(find.text('Artikel (1)'), findsOneWidget);

        await tester.tap(iconButtonWithTooltip('Weniger').first);
        await tester.pumpAndSettle();
        expect(find.text('Artikel (0)'), findsOneWidget);
        expect(find.textContaining('Pizza (id: 2) — 8.94€'), findsNothing);
      });
    });

    group('submit', () {
      testWidgets('skips backend call when nothing changed', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        var calls = 0;
        var saved = false;

        final table = TableModel(id: 3);
        final order = OrderModel(
          id: 7,
          items: <OrderItemModel>[
            OrderItemModel(id: 10, item: mi(5, 'Latte', 4.2), quantity: 1),
          ],
          table: table,
          archived: false,
        );

        final form = makeOrderForm(
          order: order,
          title: 'Bestellung bearbeiten',
          saveButtonText: 'Speichern',
          successPrefix: 'Bestellung aktualisiert:',
          errorPrefix: 'Fehler beim Aktualisieren:',
          onSaved: () => saved = true,
          action: (o, _) async {
            calls += 1;
            return true;
          },
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () async => [table],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.text('Speichern'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(calls, 0);
        expect(saved, isFalse);
        expect(
          snackBarTextContaining('Keine Änderungen vorgenommen.'),
          findsOneWidget,
        );
        expect(find.byType(OrderForm), findsNothing);
      });

      testWidgets('success calls onSaved and pops dialog', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        bool saved = false;
        OrderModel? captured;

        final form = makeOrderForm(
          order: OrderModel(
            id: 42,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          successPrefix: 'Bestellung erstellt:',
          errorPrefix: 'Fehler beim Erstellen:',
          onSaved: () => saved = true,
          action: (o, _) async {
            captured = o;
            return true;
          },
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () async => [TableModel(id: 1), TableModel(id: 2)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(tableDropdown());
        await tester.pumpAndSettle();
        await tester.tap(find.text('2').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));
        await tester.pumpAndSettle();

        expect(saved, isTrue);
        expect(captured?.table?.id, 2);
        expect(find.byType(OrderForm), findsNothing);
      });

      testWidgets('timeout sets offline and shows message', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        final form = makeOrderForm(
          order: OrderModel(
            id: 42,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) => Completer<bool>().future,
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.text('Erstellen'));
        await tester.pump(); // start

        await tester.pump(const Duration(seconds: 11));
        await tester.pumpAndSettle();

        expect(appState.cStatus, ConnectionStatus.offline);
        expect(find.textContaining('Request timed out'), findsOneWidget);
        expect(find.byType(OrderForm), findsNothing);
      });

      testWidgets('exception sets offline and shows error', (tester) async {
        final appState = newAppState(StubBackendMinimal());

        final form = makeOrderForm(
          order: OrderModel(
            id: 42,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          action: (_, __) async => throw Exception('boom'),
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(find.text('Erstellen'));
        await tester.pumpAndSettle();

        expect(appState.cStatus, ConnectionStatus.offline);
        expect(find.textContaining('Fehler: Exception: boom'), findsOneWidget);
        expect(find.byType(OrderForm), findsNothing);
      });

      testWidgets('submit ohne Artikel speichert Bestellung trotzdem', (
        tester,
      ) async {
        final appState = newAppState(StubBackendMinimal());

        var saved = false;

        final form = makeOrderForm(
          order: OrderModel(
            id: 9,
            items: <OrderItemModel>[],
            table: null,
            archived: false,
          ),
          successPrefix: 'Bestellung erstellt:',
          onSaved: () => saved = true,
          action: (_, __) async => true,
          fetchMenuItems: () async => FetchResult.success(<MenuItemModel>[]),
          fetchTables: () async => [TableModel(id: 1)],
        );

        await openOrderFormDialog(tester, appState: appState, form: form);

        await tester.tap(tableDropdown());
        await tester.pumpAndSettle();
        await tester.tap(find.text('1').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Erstellen'));
        await tester.pumpAndSettle();

        expect(saved, isTrue);
        expect(snackBarTextContaining('Bestellung erstellt:'), findsOneWidget);
        expect(find.byType(OrderForm), findsNothing);
      });
    });
  });
}
