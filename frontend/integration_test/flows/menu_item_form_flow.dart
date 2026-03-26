import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/main.dart' as app;
import 'package:frontend/widgets/button/delete_menu_item_button.dart';

import '../helpers/finders.dart' as finders;
import '../helpers/strings.dart';
import '../helpers/waits.dart';

/// Öffnet die MenuItem Ansicht
/// baut die App mit dem optional übergebenem [appState]
/// Drückt mithilfe des [tester] den MenuItemknopf in der Navigationsbar
openMenuItemView({
  required WidgetTester tester,
  AppState? appState, //ob die Applikation gebaut werden soll
}) async {
  if (appState != null) {
    await tester.pumpWidget(app.buildApp(state: appState));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
  // View auf MenuItem ändern
  await tester.tap(finders.navMenu());
  await tester.pump();
  await pumpUntilFound(tester, finders.addItemButton());
}

/// Stellt den Flow zum Erstellen eines MenuItems mit den Parametern
/// [itemName], [itemPrice] und [itemDesc] dar.
/// Benötigt den [tester] um das UI entsprechend zu manipulieren.
/// Falls der optionale boolean [cancelCreation] übergeben wird, wird der Erstellvorgang abgebrochen
/// Der optionale boolean [testValidation] steuert ob die Validation des Namen- und Preisfeldes geprüft werden soll.
createMenuItemFlow({
  required WidgetTester tester,
  required String itemName,
  required String itemPrice,
  required String itemDesc,
  bool cancelCreation = false,
  bool testValidation = false,
}) async {
  //Erstellungsformular öffnen
  await tester.tap(finders.addItemButton());
  await tester.pump();
  await pumpUntilFound(tester, finders.itemNameField());

  if (cancelCreation) {
    await tester.tap(finders.itemCancelButton());
    await pumpUntilGone(tester, finders.itemNameField());
    return; //Abbruch, Formular geschlossen Test abgeschlossen
  }

  //Namen eingeben
  final itemNameField = finders.itemNameField();

  expect(find.text(emptyItemNameMessage), findsOneWidget);

  //await tester.tap(itemName);
  //await tester.pumpAndSettle();
  await tester.enterText(itemNameField, itemName);
  await tester.pump();
  await pumpUntilGone(tester, find.text(emptyItemNameMessage));
  expect(find.text(emptyItemNameMessage), findsNothing);

  //Preis eingeben und Validation prüfen
  final itemPriceField = finders.itemPriceField();

  //optional Validation prüfen
  if (testValidation) {
    await tester.enterText(itemPriceField, 'Keine Zahl');
    await tester.pump();
    await pumpUntilFound(tester, find.text(invalidItemPriceMessage));

    expect(find.text(invalidItemPriceMessage), findsOneWidget);
    expect(find.text(tooManyDecimalsItemPriceMessage), findsNothing);
    expect(find.text(emptyPriceMessage), findsNothing);

    await tester.enterText(itemPriceField, '');
    await tester.pump();
    await pumpUntilFound(tester, find.text(emptyPriceMessage));

    expect(find.text(invalidItemPriceMessage), findsNothing);
    expect(find.text(tooManyDecimalsItemPriceMessage), findsNothing);
    expect(find.text(emptyPriceMessage), findsOneWidget);

    await tester.enterText(itemPriceField, '${itemPrice}187');
    await tester.pump();
    await pumpUntilFound(tester, find.text(tooManyDecimalsItemPriceMessage));

    expect(find.text(invalidItemPriceMessage), findsNothing);
    expect(find.text(tooManyDecimalsItemPriceMessage), findsOneWidget);
    expect(find.text(emptyPriceMessage), findsNothing);
  }

  await tester.enterText(itemPriceField, itemPrice);
  await tester.pump();
  await pumpUntilGone(tester, find.text(tooManyDecimalsItemPriceMessage));

  expect(find.text(invalidItemPriceMessage), findsNothing);
  expect(find.text(tooManyDecimalsItemPriceMessage), findsNothing);
  expect(find.text(emptyPriceMessage), findsNothing);

  await tester.enterText(finders.itemDescField(), itemDesc);
  await tester.pumpAndSettle();

  await tester.tap(finders.itemFormSaveButton('Erstellen'));
  await tester.pump();
  await pumpUntilGone(tester, finders.itemNameField());

  return;
}

/// Stellt den Flow zum Löschen eines MenuItems mit dem Parameter [itemName] dar.
/// Benötigt den [tester] und [mouse] um das UI entsprechend zu manipulieren.
/// Falls der optionale boolean [cancelDeletion] übergeben wird, wird der Löschvorgang abgebrochen.
deleteMenuItemFlow({
  required WidgetTester tester,
  required String itemName,
  required TestGesture mouse,
  bool cancelDeletion = false,
}) async {
  final deleteButton = find.byType(DeleteMenuItemButton);
  final itemTile = find.text(itemName);
  expect(itemTile, findsOneWidget);
  //Über Item hovern

  expect(
    deleteButton,
    findsNothing,
  ); // Kein Löschenknopf, da Mouse aktuell bei x0 y0 ist

  await mouse.moveTo(tester.getCenter(itemTile));
  await tester.pump();

  //Löschknopf sollte für dieses eine Item verfügbar sein
  expect(deleteButton, findsOneWidget);
  await tester.tap(deleteButton);
  await tester.pumpAndSettle();

  //Bestätigungsdialog
  if (cancelDeletion) {
    await tester.tap(finders.itemCancelButton());
    await mouse.moveTo(Offset.zero);
    await pumpUntilGone(tester, deleteButton);
    expect(itemTile, findsOneWidget);
    return; //Abbruchtest ist fertig an dieser Stelle
  }

  await mouse.moveTo(tester.getCenter(itemTile));
  await tester.pump();

  await tester.tap(finders.deleteButton());
  await tester.pumpAndSettle();

  expect(itemTile, findsNothing);
}

/// Stellt den Bearbeitungsvorgang des MenuItem [itemName] dar.
/// Manipuliert mit [tester] das UI und setzt, falls übergeben die neuen Parameter [newName], [newPrice] und [newDesc].
/// Mithilfe der Flag [cancelChange] kann der Abbruch des Vorganges getestet werden.
///
changeMenuItemFlow({
  required WidgetTester tester,
  required String itemName,
  String? newName,
  String? newPrice,
  String? newDesc,
  bool cancelChange = false,
}) async {
  await tester.tap(finders.itemListEntry(itemName));
  await pumpUntilFound(tester, finders.itemNameField());

  if (newName != null) {
    await tester.enterText(finders.itemNameField(), newName);
    await pumpUntilGone(
      tester,
      find.text(emptyItemNameMessage),
      timeout: const Duration(seconds: 5),
    );
  }
  if (newPrice != null) {
    await tester.enterText(finders.itemPriceField(), newPrice);
    await pumpUntilGone(
      tester,
      find.text(tooManyDecimalsItemPriceMessage),
      timeout: const Duration(seconds: 5),
    );
    await pumpUntilGone(
      tester,
      find.text(invalidItemPriceMessage),
      timeout: const Duration(seconds: 5),
    );
    await pumpUntilGone(
      tester,
      find.text(emptyPriceMessage),
      timeout: const Duration(seconds: 5),
    );
  }
  if (newDesc != null) {
    await tester.enterText(finders.itemDescField(), newDesc);
    await tester.pumpAndSettle();
  }

  if (cancelChange) {
    await tester.tap(finders.itemCancelButton());
    await pumpUntilGone(tester, finders.itemNameField());
    return;
  }

  await tester.tap(finders.itemFormSaveButton('Speichern'));
  await tester.pump();
  await pumpUntilGone(tester, finders.itemNameField());
}
