import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/menu_item_model.dart'; // Notwendig für das Menümodell
import 'package:frontend/widgets/button/delete_menu_item_button.dart';
import 'package:mockito/mockito.dart';

/// Mockito-Mock für den VoidCallback (onCreated)
class MockOnCreated extends Mock {
  void call();
}

/// Testbare Subklasse, bei der wir den Dialog-Aufruf „faken“ können.
class _TestableDeleteMenuItemButton extends DeleteMenuItemButton {
  final Future<bool> Function(
    BuildContext context, {
    required MenuItemModel menuItem,
  })
  onShowDialog;

  const _TestableDeleteMenuItemButton({
    required super.menuItem,
    required super.onCreated,
    required this.onShowDialog,
  });

  @override
  Future<bool> showDeleteMenuItemDialog(
    BuildContext context, {
    required MenuItemModel menuItem,
  }) {
    // Kein echter Dialog, sondern der injizierte Callback.
    return onShowDialog(context, menuItem: menuItem);
  }
}

void main() {
  final menuItem = MenuItemModel(
    id: 123,
    name: 'Pizza',
    price: 10.0,
    version: 1,
    archived: false,
    description: '',
  ); // Testdaten für das Menüelement

  group('DeleteMenuItemButton', () {
    testWidgets('builds without error and has delete button', (
      WidgetTester tester,
    ) async {
      final onCreated = MockOnCreated();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteMenuItemButton(
              menuItem: menuItem, // Menüelement an das Widget übergeben
              onCreated: onCreated.call,
            ),
          ),
        ),
      );

      await tester.pump();

      // Kein Build-Fehler
      expect(tester.takeException(), isNull);

      // Widget und Icon vorhanden
      expect(find.byType(DeleteMenuItemButton), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Optional: Größe des Buttons prüfen
      final sizedBoxFinder = find
          .ancestor(
            of: find.byType(IconButton),
            matching: find.byType(SizedBox),
          )
          .first;
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.height, 40);
      expect(sizedBox.width, 40);
    });

    testWidgets('calls showDeleteMenuItemDialog with correct menuItem', (
      WidgetTester tester,
    ) async {
      final onCreated = MockOnCreated();

      MenuItemModel? capturedMenuItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestableDeleteMenuItemButton(
              menuItem: menuItem, // Menüelement an das Widget übergeben
              onCreated: onCreated.call,
              onShowDialog:
                  (
                    BuildContext context, {
                    required MenuItemModel menuItem,
                  }) async {
                    capturedMenuItem = menuItem;
                    return false; // Dialog-Ergebnis: "abgebrochen"
                  },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(capturedMenuItem, menuItem);

      // onCreated darf hier NICHT aufgerufen worden sein
      verifyNever(onCreated());

      expect(tester.takeException(), isNull);
    });

    testWidgets('calls onCreated after "deleting" item', (
      WidgetTester tester,
    ) async {
      final onCreated = MockOnCreated();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestableDeleteMenuItemButton(
              menuItem: menuItem, // Menüelement an das Widget übergeben
              onCreated: onCreated.call,
              onShowDialog:
                  (
                    BuildContext context, {
                    required MenuItemModel menuItem,
                  }) async {
                    return true; // Dialog bestätigt Löschung
                  },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Erwartung: Callback genau einmal aufgerufen
      verify(onCreated()).called(1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not call onCreated with deletion cancelled', (
      WidgetTester tester,
    ) async {
      final onCreated = MockOnCreated();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestableDeleteMenuItemButton(
              menuItem: menuItem, // Menüelement an das Widget übergeben
              onCreated: onCreated.call,
              onShowDialog:
                  (
                    BuildContext context, {
                    required MenuItemModel menuItem,
                  }) async {
                    return false; // Dialog abgebrochen
                  },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // onCreated darf nicht aufgerufen werden
      verifyNever(onCreated());
      expect(tester.takeException(), isNull);
    });
  });
}
