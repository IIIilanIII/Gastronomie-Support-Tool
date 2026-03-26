// generiert mit https://app.quicktype.io/

// Zum Parsen eines JSON-Strings:
//
//     final menuItem = menuItemFromJson(jsonString);

import 'dart:convert';

MenuItemModel menuItemFromJson(String str) =>
    MenuItemModel.fromJson(json.decode(str));

List<MenuItemModel> menuItemListFromJson(String str) =>
    List<MenuItemModel>.from(
      json.decode(str).map((x) => MenuItemModel.fromJson(x)),
    );

String menuItemToJson(MenuItemModel data) => json.encode(data.toJson());

/// Datenmodell für einen Menüeintrag inklusive Version und Archivstatus.
class MenuItemModel {
  int? id;
  String name;
  String description;
  double price;
  int version;
  bool archived;

  MenuItemModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.version,
    required this.archived,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
    id: json["id"],
    name: json["name"],
    description: json["description"] ?? "",
    price: json["price"],
    version: json["version"],
    archived: json["archived"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "price": price,
    "version": version,
    "archived": archived,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItemModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.version == version &&
        other.archived == archived;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, price, version, archived);
}
