import 'package:test/test.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';

void main() {
  final orderItemAsJson =
      '{"id":123,"quantity":2,"menuItem":{"id":1,"name":"Bier","description":"BIIIIER","price":187.0,"version":1,"archived":false}}';

  final orderItemListAsJson =
      '[{"id":123,"quantity":2,"menuItem":{"id":1,"name":"Bier","description":"BIIIIER","price":187.0,"version":1,"archived":false}},'
      '{"id":124,"quantity":1,"menuItem":{"id":2,"name":"Pizza","description":"Salami","price":8.94,"version":2,"archived":false}}]';

  final item1 = MenuItemModel(
    id: 1,
    name: 'Bier',
    description: 'BIIIIER',
    price: 187.0,
    version: 1,
    archived: false,
  );

  final item2 = MenuItemModel(
    id: 2,
    name: 'Pizza',
    description: 'Salami',
    price: 8.94,
    version: 2,
    archived: false,
  );

  final orderItem = OrderItemModel(id: 123, item: item1, quantity: 2);

  test('Convert OrderItem from json', () {
    final parsed = orderItemFromJson(orderItemAsJson);
    expect(parsed == orderItem, true);

    final listParsed = orderItemListFromJson(orderItemListAsJson);
    expect(listParsed.contains(orderItem), true);
    expect(listParsed.length == 2, true);
  });

  test('Convert OrderItem to json (roundtrip)', () {
    final jsonStr = orderItemToJson(orderItem);
    final roundTrip = orderItemFromJson(jsonStr);

    expect(roundTrip == orderItem, true);
  });

  test('OrderItem == uses identical fast-path and hashCode is consistent', () {
    // identical fast-path
    final sameRef = orderItem;
    expect(identical(orderItem, sameRef), true);
    expect(orderItem == sameRef, true);
    expect(orderItem.hashCode == sameRef.hashCode, true);

    // Different instance, same values: identical false, == true, hashCode should match
    final copy = OrderItemModel(
      id: orderItem.id,
      item: orderItem.item,
      quantity: orderItem.quantity,
    );
    expect(identical(orderItem, copy), false);
    expect(orderItem == copy, true);
    expect(orderItem.hashCode == copy.hashCode, true);

    // Different values
    final differentId = OrderItemModel(
      id: 999,
      item: orderItem.item,
      quantity: orderItem.quantity,
    );
    expect(orderItem == differentId, false);

    final differentItem = OrderItemModel(
      id: orderItem.id,
      item: item2,
      quantity: orderItem.quantity,
    );
    expect(orderItem == differentItem, false);
  });

  test('OrderItem == and hashCode consider quantity', () {
    final q2 = OrderItemModel(id: 123, item: item1, quantity: 2);
    final q3 = OrderItemModel(id: 123, item: item1, quantity: 3);

    expect(q2 == q3, false);
    expect(q2.hashCode == q3.hashCode, false);
  });
  test('OrderItem == and hashCode match for equal values', () {
    final a = OrderItemModel(id: 123, item: item1, quantity: 2);
    final b = OrderItemModel(id: 123, item: item1, quantity: 2);

    expect(a == b, true);
    expect(a.hashCode == b.hashCode, true);
  });

  test('listEquals helper works', () {
    expect(listEquals(<int>[1, 2], <int>[1, 2]), true);
    expect(listEquals(<int>[1, 2], <int>[2, 1]), false);
    expect(listEquals(<int>[1], <int>[1, 2]), false);
  });

  test(
    'OrderItemModel.fromJson throws if required fields are missing (optional)',
    () {
      expect(() => OrderItemModel.fromJson({}), throwsA(anything));
      expect(() => OrderItemModel.fromJson({'quantity': 1}), throwsA(anything));
      expect(
        () => OrderItemModel.fromJson({'menuItem': {}, 'quantity': 1}),
        throwsA(anything),
      );
    },
  );
}
