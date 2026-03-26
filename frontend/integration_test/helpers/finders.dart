import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/widgets/button/add_menu_button.dart';
import 'package:frontend/widgets/button/add_order_button.dart';
import 'package:frontend/widgets/button/delete_order_button.dart';
import 'package:frontend/widgets/list/list_item/header_item.dart';
import 'package:frontend/widgets/list/list_item/menu_item.dart';
import 'package:frontend/widgets/list/list_item/order_item.dart';

//Datei um verschwiedene UI Element finder zu deklarieren

Finder navMenu() {
  return find.ancestor(
    of: find.text('Menü'),
    matching: find.byType(HeaderItem),
  );
}

Finder navOrders() {
  return find.ancestor(
    of: find.text('Bestellungen'),
    matching: find.byType(HeaderItem),
  );
}

Finder addItemButton() => find.byType(AddMenuButton);

Finder addOrderButton() => find.byType(AddOrderButton);

Finder itemNameField() {
  return find.ancestor(
    of: find.text('Name'),
    matching: find.byType(TextFormField),
  );
}

Finder orderTableDropdown() => find.byType(DropdownButtonFormField<TableModel>);

Finder orderAddItemButton() => find.byKey(const Key('order_add_sub_items'));

Finder orderAddItemDialog() => find.byKey(const Key('order_add_sub_items_dialog'));

Finder orderItemDropdown() => find.byKey(const Key('order_add_sub_items_dropdown'));

Finder itemPriceField() {
  return find.ancestor(
    of: find.text('Preis'),
    matching: find.byType(TextFormField),
  );
}

Finder itemDescField() {
  return find.ancestor(
    of: find.text('Beschreibung'),
    matching: find.byType(TextFormField),
  );
}

Finder itemFormSaveButton(String text) {
  return find.ancestor(of: find.text(text), matching: find.byType(TextButton));
}

Finder itemCancelButton() {
  return find.ancestor(
    of: find.text('Abbrechen'),
    matching: find.byType(TextButton),
  );
}

Finder deleteButton() {
  return find.ancestor(
    of: find.text('Löschen'),
    matching: find.byType(TextButton),
  );
}

Finder itemListEntry(String search) {
  return find.ancestor(of: find.text(search), matching: find.byType(MenuItem));
}

Finder orderListEntryForTable(int tableId) {
  return find.ancestor(
    of: find.textContaining('Tisch $tableId'),
    matching: find.byType(OrderItem),
  );
}

Finder orderHeader(int orderId, int tableId) {
  return find.text('Bestellung #$orderId · Tisch $tableId');
}

Finder orderTile(int orderId, int tableId) {
  return find.ancestor(
    of: orderHeader(orderId, tableId),
    matching: find.byType(OrderItem),
  );
}

Finder orderTotalText(double total) {
  return find.text('Gesamt: €${total.toStringAsFixed(2)}');
}

Finder orderArchiveButton() => find.byTooltip('Bestellung archivieren');

Finder orderDeleteButton() => find.byType(DeleteOrderButton);

Finder orderArticlesLabel(int quantity) {
  return find.text('Artikel: $quantity');
}

Finder orderArchivedIcon() => find.byIcon(Icons.check_box);
