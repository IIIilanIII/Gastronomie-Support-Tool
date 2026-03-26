import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/main.dart' as app;
import 'package:frontend/models/menu_item_model.dart';

import '../helpers/finders.dart' as finders;
import '../helpers/waits.dart';

/// Öffnet die Bestellansicht und stellt sicher, dass sie geladen ist.
/// Optional kann ein [appState] mitgegeben werden, um die App aufzubauen.
Future<void> openOrderView({
  required WidgetTester tester,
  AppState? appState,
}) async {
  if (appState != null) {
    await tester.pumpWidget(app.buildApp(state: appState));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  await tester.tap(finders.navOrders());
  await tester.pump();

  // Entweder der Button ist sichtbar oder die Liste liefert eine leere Meldung.
  try {
    await pumpUntilFound(tester, finders.addOrderButton());
  } on TestFailure {
    await pumpUntilFound(tester, find.text('Keine Bestellungen vorhanden.'));
  }

  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> createOrderFlow({
  required WidgetTester tester,
  required MenuItemModel menuItem,
  int quantity = 1,
}) async {
  await tester.tap(finders.addOrderButton());
  await tester.pumpAndSettle();

  await pumpUntilFound(tester, finders.orderAddItemButton());
  await tester.tap(finders.orderAddItemButton());
  await tester.pumpAndSettle();

  final dropdown = finders.orderItemDropdown();
  await pumpUntilFound(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final optionText = '${menuItem.name} — ${menuItem.price.toStringAsFixed(2)}€';
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();

  if (quantity != 1) {
    final qtyField = find.descendant(
      of: finders.orderAddItemDialog(),
      matching: find.byType(TextField),
    );
    await tester.enterText(qtyField, quantity.toString());
    await tester.pump();
  }

  await tester.tap(find.text('Hinzufügen'));
  await tester.pumpAndSettle();

  await tester.tap(finders.itemFormSaveButton('Erstellen'));
  await tester.pump();
  await pumpUntilGone(tester, finders.itemFormSaveButton('Erstellen'));
}

Future<void> increaseOrderQuantityFlow({
  required WidgetTester tester,
  required int orderId,
  required int tableId,
}) async {
  final header = finders.orderHeader(orderId, tableId);
  await pumpUntilFound(tester, header);
  await tester.tap(header);
  await tester.pumpAndSettle();

  await pumpUntilFound(tester, find.text('Bestellung bearbeiten'));
  await tester.tap(find.byTooltip('Mehr'));
  await tester.pump();

  await tester.tap(finders.itemFormSaveButton('Speichern'));
  await tester.pump();
  await pumpUntilGone(tester, find.text('Bestellung bearbeiten'));
}

Future<void> archiveOrderFlow({
  required WidgetTester tester,
  required int orderId,
  required int tableId,
}) async {
  final tile = finders.orderTile(orderId, tableId);
  await pumpUntilFound(tester, tile);

  final archiveButton = find.descendant(
    of: tile,
    matching: finders.orderArchiveButton(),
  );
  await tester.tap(archiveButton);
  await tester.pumpAndSettle();

  await pumpUntilFound(tester, find.text('Bestellung archivieren'));
  await tester.tap(find.text('Archivieren'));
  await tester.pumpAndSettle();
  await pumpUntilGone(tester, find.text('Bestellung archivieren'));
}

Future<void> deleteOrderFlow({
  required WidgetTester tester,
  required int orderId,
  required int tableId,
  required TestGesture mouse,
  bool cancelDeletion = false,
}) async {
  final tile = finders.orderTile(orderId, tableId);
  await pumpUntilFound(tester, tile);

  await mouse.moveTo(tester.getCenter(tile));
  await tester.pump();

  final deleteButton = find.descendant(
    of: tile,
    matching: finders.orderDeleteButton(),
  );
  await pumpUntilFound(tester, deleteButton);
  await tester.tap(deleteButton);
  await tester.pumpAndSettle();

  await pumpUntilFound(tester, find.text('Bestellung löschen'));

  if (cancelDeletion) {
    await tester.tap(finders.itemCancelButton());
    await tester.pumpAndSettle();
    await mouse.moveTo(Offset.zero);
    return;
  }

  await tester.tap(find.text('Löschen'));
  await tester.pumpAndSettle();
}
