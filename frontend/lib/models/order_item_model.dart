import 'dart:convert';

import 'menu_item_model.dart';

OrderItemModel orderItemFromJson(String str) =>
    OrderItemModel.fromJson(json.decode(str));

List<OrderItemModel> orderItemListFromJson(String str) =>
    List<OrderItemModel>.from(
      json.decode(str).map((x) => OrderItemModel.fromJson(x)),
    );

String orderItemToJson(OrderItemModel data) => json.encode(data.toJson());

/// Einzelner Positionseintrag innerhalb einer Bestellung.
class OrderItemModel {
  int? id;
  MenuItemModel item;
  int quantity;

  OrderItemModel({this.id, required this.item, required this.quantity});

  OrderItemModel.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      item = MenuItemModel.fromJson(json['menuItem']),
      quantity = json['quantity'];

  Map<String, dynamic> toJson() {
    return {"id": id, "menuItem": item, "quantity": quantity};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemModel &&
        other.id == id &&
        other.item == item &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(id, item, quantity);
}

// Hilfsfunktion zum Vergleich zweier Listen ohne Flutter-Abhängigkeiten
/// Vergleicht zwei Listen elementweise ohne Flutter-Abhängigkeiten.
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
