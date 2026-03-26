import 'dart:convert';

import 'table_model.dart';
import 'order_item_model.dart';

OrderModel orderFromJson(String str) => OrderModel.fromJson(json.decode(str));

List<OrderModel> orderListFromJson(String str) =>
    List<OrderModel>.from(json.decode(str).map((x) => OrderModel.fromJson(x)));

String orderToJson(OrderModel data) => json.encode(data.toJson());

// Repräsentiert eine Bestellung mit Artikeln, Tisch und Archivstatus.
class OrderModel {
  int? id;
  List<OrderItemModel> items;
  TableModel? table;
  bool archived;

  OrderModel({
    this.id,
    required this.items,
    this.table,
    required this.archived,
  });

  OrderModel.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      items = List<OrderItemModel>.from(
        (json['items'] as List).map((x) => OrderItemModel.fromJson(x)),
      ),
      table = TableModel.fromJson(json['barTable']),
      archived = json['archived'] ?? false;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "items": List<dynamic>.from(items.map((x) => x.toJson())),
      "barTable": table,
      "archived": archived,
    };
  }

  // Fügt eine Position hinzu, wenn sie noch nicht in der Liste enthalten ist.
  addOrderItem(OrderItemModel orderItem) {
    if (!items.contains(orderItem)) {
      items.add(orderItem);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel &&
        other.id == id &&
        listEquals(other.items, items) &&
        other.table == table;
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(items), table);
}

// Vergleicht zwei Listen elementweise ohne Flutter-Abhängigkeiten.
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
