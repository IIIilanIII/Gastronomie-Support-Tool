import 'package:test/test.dart';
import 'package:frontend/models/menu_item_model.dart';

void main() {
  String menuItemAsJson =
      '{"id":1,"name":"Bier","description":"BIIIIER","price":187.0,"version":1,"archived":false}';
  String menuItemListAsJson =
      '[{"id":1,"name":"Bier","description":"BIIIIER","price":187.0,"version":1,"archived":false}]';

  MenuItemModel menuItem = MenuItemModel(
    id: 1,
    name: 'Bier',
    description: 'BIIIIER',
    price: 187.0,
    version: 1,
    archived: false,
  );

  test('Convert MenuItem from json', () {
    MenuItemModel menuItemFromSampleJson = menuItemFromJson(menuItemAsJson);
    expect(menuItem == menuItemFromSampleJson, true);

    List<MenuItemModel> menuItemListFromSampleJSON = menuItemListFromJson(
      menuItemListAsJson,
    );

    //deep Equality benötigt das Collection Package,
    //das ich jetzt nicht nur für einen Test als Dependency hinzufügen möchte
    expect(menuItemListFromSampleJSON.contains(menuItem), true);
    expect(menuItemListFromSampleJSON.length == 1, true);
  });
}
