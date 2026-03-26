import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/widgets/form/order_items_section.dart';

import 'order_test_utils.dart';

OrderModel makeOrder({int quantity = 1, bool archived = false}) {
  return OrderModel(
    id: 1,
    table: TableModel(id: 4),
    archived: false,
    items: [
      OrderItemModel(
        item: MenuItemModel(
          id: 9,
          name: 'Apfelschorle',
          description: '0,4l',
          price: 3.5,
          version: 1,
          archived: archived,
        ),
        quantity: quantity,
      ),
    ],
  );
}

Future<void> pumpSection(
  WidgetTester tester,
  OrderModel order,
  VoidCallback? onChanged,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return OrderItemsSection(
              order: order,
              onAddPressed: () {},
              onChanged: () {
                onChanged?.call();
                setState(() {});
              },
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('increments quantity and calls onChanged', (tester) async {
    final order = makeOrder();
    var changeCalls = 0;

    await pumpSection(tester, order, () => changeCalls += 1);

    expect(find.text('Artikel (1)'), findsOneWidget);

    await tester.tap(iconButtonWithTooltip('Mehr'));
    await tester.pump();

    expect(order.items.first.quantity, 2);
    expect(find.text('Artikel (2)'), findsOneWidget);
    expect(changeCalls, 1);
  });

  testWidgets('decrement removes item when quantity is one', (tester) async {
    final order = makeOrder(quantity: 1);
    var changeCalls = 0;

    await pumpSection(tester, order, () => changeCalls += 1);

    expect(order.items, hasLength(1));
    expect(order.items.first.quantity, 1);

    final minusFinder = iconButtonWithTooltip('Weniger');
    final minus = tester.widget<IconButton>(minusFinder);
    expect(minus.onPressed, isNotNull);

    await tester.tap(minusFinder);
    await tester.pump();

    expect(order.items, isEmpty);
    expect(find.text('Artikel (0)'), findsOneWidget);
    expect(changeCalls, 1);
  });

  testWidgets('delete button removes item', (tester) async {
    final order = makeOrder(quantity: 3);
    var changeCalls = 0;

    await pumpSection(tester, order, () => changeCalls += 1);

    await tester.tap(iconButtonWithTooltip('Entfernen'));
    await tester.pump();

    expect(order.items, isEmpty);
    expect(find.text('Artikel (0)'), findsOneWidget);
    expect(changeCalls, 1);
  });

  testWidgets('archived items show hint instead of incrementing', (
    tester,
  ) async {
    final order = makeOrder(archived: true);

    await pumpSection(tester, order, null);

    expect(order.items.first.quantity, 1);

    await tester.tap(iconButtonWithTooltip('Archiviert').last);
    await tester.pump();

    expect(order.items.first.quantity, 1);
    expect(
      find.text(
        'Dieser Artikel ist archiviert und kann nicht mehr verändert werden.',
      ),
      findsOneWidget,
    );
  });
}
