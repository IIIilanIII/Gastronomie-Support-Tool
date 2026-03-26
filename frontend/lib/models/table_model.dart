import 'dart:convert';

TableModel tableFromJson(String str) => TableModel.fromJson(json.decode(str));

List<TableModel> tableListFromJson(String str) =>
    List<TableModel>.from(json.decode(str).map((x) => TableModel.fromJson(x)));

String tableToJson(TableModel data) => json.encode(data.toJson());

/// Schlankes Modell für einen Bartisch.
class TableModel {
  int id;

  TableModel({required this.id});

  factory TableModel.fromJson(Map<String, dynamic> json) =>
      TableModel(id: json["id"]);

  Map<String, dynamic> toJson() => {"id": id};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableModel && other.id == id;
  }

  @override
  int get hashCode => Object.hash(id, 12);
}
