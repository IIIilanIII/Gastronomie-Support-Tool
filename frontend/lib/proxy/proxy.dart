import 'dart:async';
import 'dart:io';

import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:http/http.dart' as http;
import '../app_state.dart';

/// Bündelt alle HTTP-Aufrufe zum Backend und liefert Domainmodelle zurück.
class BackendProxy {
  // Backend-Basisadresse laut Vorgabe des Serverteams.
  // Kein abschließender Slash, damit Uri.parse Pfade korrekt zusammenbaut.
  static const _backend = "http://localhost:8080";

  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async {
    try {
      // Ergebnis selbst ist egal, wir prüfen nur auf Exceptions
      await client.get(Uri.parse(_backend));
      return ConnectionStatus.online;
    } catch (e) {
      return ConnectionStatus.offline;
    }
  }

  /// Erzeugt ein neues Menü‑Item auf dem Backend.
  /// Erwartet MenuItemModel [item]
  /// Behandelt jede erfolgreiche 2xx-Antwort als Erfolg, damit 201 Created ebenfalls akzeptiert wird.
  /// Es wird eine HttpException geschmissen, wenn die übertragenen Daten für das Backend ungültig sind
  Future<bool> createMenuItem(http.Client client, MenuItemModel item) async {
    try {
      final resp = await client.post(
        Uri.parse('$_backend/menuItem'),
        headers: {'Content-Type': 'application/json'},
        body: menuItemToJson(item),
      );

      if (resp.statusCode == 403) {
        throw HttpException(
          'MenuItem konnte nicht angelegt werden \n Statuscode: ${resp.statusCode}',
        );
      }
      // Laut API gilt lediglich 204 (No Content) als Erfolg.
      return resp.statusCode == 204;
    } on HttpException catch (_) {
      rethrow; //diese Exception wird im UI weiter verarbeitet
    } catch (e) {
      return false;
    }
  }

  /// Sendet einen Löschrequest für [item] an das Backend
  /// Es wird eine HttpException geworfen, wenn das Backend 403 oder 422 HTTP-Statuscode zurückgibt
  /// Bei anderen Exceptions wird nur false returned.
  /// Ansonsten wird true zurückgegben, wenn der HTTP-Statuscode 204 lautet
  Future<bool> deleteMenuItem(http.Client client, MenuItemModel item) async {
    try {
      final resp = await client.delete(
        Uri.parse('$_backend/menuItem/${item.id}'),
      );
      switch (resp.statusCode) {
        case 403:
          throw HttpException(
            'MenuItem ist archiviert oder in offener Bestellung enthalten und kann daher nicht gelöscht werden',
          );
        case 422:
          throw HttpException('Ungültige MenuItem ID');
      }

      return resp.statusCode == 204;
    } on HttpException catch (_) {
      rethrow; //diese Exception wird im UI weiter verarbeitet
    } catch (e) {
      return false;
    }
  }

  /// Ruft alle Menüeinträge vom Backend ab und liefert ein [FetchResult] mit
  /// Daten oder Fehlerinformationen zurück.
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    try {
      final resp = await client
          .get(Uri.parse('$_backend/menuItems'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final items = menuItemListFromJson(resp.body);
        return FetchResult.success(items, statusCode: resp.statusCode);
      }

      // Nicht-200 ist ein "Failure"
      return FetchResult.failure(
        Exception('HTTP ${resp.statusCode}'),
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return FetchResult.failure(e);
    }
  }

  /// Sendet einen Updaterequest für [menuItem] an das Backend
  /// Es wird eine HttpException geworfen, wenn das Backend 403 (bereits archiviert), 404 (existiert nicht) 422 (ungültige ID) HTTP-Statuscode zurückgibt
  /// Bei anderen Exceptions wird nur false returned.
  /// Ansonsten wird true zurückgegben, wenn der HTTP-Statuscode 204 lautet
  Future<bool> updateMenuItem(
    http.Client client,
    MenuItemModel menuItem,
  ) async {
    try {
      final body = menuItemToJson(menuItem);
      final uri = Uri.parse('$_backend/menuItem');
      final resp = await client.put(
        uri,
        body: body,
        headers: {"Content-Type": "application/json"},
      );
      switch (resp.statusCode) {
        case 403:
          throw HttpException(
            'MenuItem ist archiviert und kann nicht aktualisiert werden',
          );
        case 404:
          throw HttpException('MenuItem exisiert nicht mehr');
        case 422:
          throw HttpException('Keine gültige MenuItemID ');
      }

      return resp.statusCode == 204;
    } on HttpException catch (_) {
      rethrow; //soll im UI behandelt werden
    } catch (e) {
      return false;
    }
  }

  /// Liefert eine Liste an Bestellungen innerhalb eines [FetchResult] zurück.
  /// Fehler werden an dieser Stelle an den Aufrufer zurückgegben.
  Future<FetchResult<List<OrderModel>>> fetchOrders(http.Client client) async {
    try {
      // Das Backend stellt die Sammlung unter /barOrders bereit.
      final resp = await client.get(Uri.parse('$_backend/barOrders'));
      if (resp.statusCode == 200) {
        // resp.body ist ein JSON-Array-String; orderListFromJson wandelt ihn in Modelle um
        final orders = orderListFromJson(resp.body);
        return FetchResult.success(orders, statusCode: resp.statusCode);
      }
      // Nicht-200 ist ein "Failure"
      return FetchResult.failure(
        Exception('HTTP ${resp.statusCode}'),
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return FetchResult.failure(e);
    }
  }

  /// Erzeugt eine neue Bestellung im Backend.
  /// Erwartet ein Ordermodell Objekt
  /// Behandelt jede erfolgreiche 2xx-Antwort als Erfolg, damit 201 Created ebenfalls akzeptiert wird.
  Future<bool> createOrder(http.Client client, OrderModel order) async {
    try {
      final resp = await client.post(
        Uri.parse('$_backend/barOrder'),
        headers: {'Content-Type': 'application/json'},
        body: orderToJson(order),
      );
      // Laut API gilt ausschließlich 204 (No Content) als Erfolg.
      return resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> closeOrder(http.Client client, OrderModel order) async {
    try {
      final resp = await client.put(
        Uri.parse('$_backend/barOrder/${order.id}/archive'),
      );
      // Laut API gilt ausschließlich 204 (No Content) als Erfolg.
      return resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOrder(http.Client client, OrderModel order) async {
    final id = order.id;
    if (id == null) return false;

    try {
      final resp = await client.put(
        Uri.parse('$_backend/barOrder'),
        headers: {'Content-Type': 'application/json'},
        body: orderToJson(order),
      );
      return resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteOrder(http.Client client, OrderModel order) async {
    final id = order.id;
    if (id == null) {
      return false;
    }

    try {
      final resp = await client.delete(Uri.parse('$_backend/barOrder/$id'));
      return resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<TableModel>> fetchTables(http.Client client) async {
    try {
      final resp = await client.get(Uri.parse('$_backend/barTables'));

      if (resp.statusCode == 200) {
        return tableListFromJson(resp.body);
      }
      return <TableModel>[];
    } catch (e) {
      return <TableModel>[];
    }
  }
}
