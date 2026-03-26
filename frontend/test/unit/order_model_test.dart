import 'package:frontend/models/order_item_model.dart';
import 'package:test/test.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/models/menu_item_model.dart';

void main() {
  final orderAsJson =
      '{"id":42,"archived":false,"items":['
      '{"quantity":2,"menuItem":{"id":1,"name":"Bier","description":"BIIIIER","price":187.0,"version":1,"archived":false}},'
      '{"quantity":1,"menuItem":{"id":2,"name":"Pizza","description":"Salami","price":8.94,"version":2,"archived":false}}'
      '],"barTable":{"id":7}}';

  final orderListAsJson =
      '[{"id":42,"archived":false,"items":['
      '{"quantity":2,"menuItem":{"id":1,"name":"Bier","description":"BIIIIER","price":187.0,"version":1,"archived":false}},'
      '{"quantity":1,"menuItem":{"id":2,"name":"Pizza","description":"Salami","price":8.94,"version":2,"archived":false}}'
      '],"barTable":{"id":7}}]';

  final order = OrderModel(
    id: 42,
    items: [
      OrderItemModel(
        quantity: 2,
        item: MenuItemModel(
          id: 1,
          name: 'Bier',
          description: 'BIIIIER',
          price: 187.0,
          version: 1,
          archived: false,
        ),
      ),
      OrderItemModel(
        quantity: 1,
        item: MenuItemModel(
          id: 2,
          name: 'Pizza',
          description: 'Salami',
          price: 8.94,
          version: 2,
          archived: false,
        ),
      ),
    ],
    table: TableModel(id: 7),
    archived: false,
  );

  test('Convert Order from json', () {
    final orderFromSampleJson = orderFromJson(orderAsJson);
    expect(orderFromSampleJson == order, true);

    final ordersFromSampleJson = orderListFromJson(orderListAsJson);
    expect(ordersFromSampleJson.contains(order), true);
    expect(ordersFromSampleJson.length == 1, true);
  });

  test('Convert Order to json (roundtrip)', () {
    final jsonStr = orderToJson(order);
    final roundTrip = orderFromJson(jsonStr);

    expect(roundTrip == order, true);
  });

  test('Order == uses identical fast-path and hashCode is consistent', () {
    // identical fast-path
    final sameRef = order;
    expect(identical(order, sameRef), true);
    expect(order == sameRef, true);
    expect(order.hashCode == sameRef.hashCode, true);

    // Different instance, same values: identical false, == true, hashCode should match
    final copy = OrderModel(
      id: order.id,
      items: List<OrderItemModel>.from(order.items),
      table: order.table,
      archived: false,
    );

    expect(identical(order, copy), false);
    expect(order == copy, true);
    expect(order.hashCode == copy.hashCode, true);

    // Different values: == false, and hashCode should (very likely) differ
    final different = OrderModel(
      id: order.id,
      items: List<OrderItemModel>.from(order.items),
      table: TableModel(id: order.table!.id + 1),
      archived: false,
    );

    expect(order == different, false);

    // Note: hashCode collisions are possible in theory, so we don't assert "!=" strictly here.
  });
}
