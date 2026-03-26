import 'dart:convert';
import 'dart:io';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_item_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('BackendProxy.createMenuItem', () {
    final backend = BackendProxy();

    test('returns true on 204 No Content', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final item = MenuItemModel(
        id: 0,
        name: 'Test',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );
      final ok = await backend.createMenuItem(client, item);
      expect(ok, isTrue);
    });

    test('returns false on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final item = MenuItemModel(
        id: 0,
        name: 'Test',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );
      final ok = await backend.createMenuItem(client, item);
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final item = MenuItemModel(
        id: 0,
        name: 'Test',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );
      final ok = await backend.createMenuItem(client, item);
      expect(ok, isFalse);
    });

    test('throws exception on 403 HTTP-Response', () async {
      final client = MockClient((request) async {
        return http.Response('forbidden', 403);
      });

      final item = MenuItemModel(
        id: 0,
        name: 'Test',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );

      await expectLater(
        backend.createMenuItem(client, item),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group('BackendProxy.checkConnectionStatus', () {
    final backend = BackendProxy();

    test('returns online when GET succeeds', () async {
      late Uri capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response('', 200);
      });

      final status = await backend.checkConnectionStatus(client);
      expect(status, ConnectionStatus.online);
      expect(capturedUri.toString(), 'http://localhost:8080');
    });

    test('returns offline when request throws', () async {
      final client = MockClient((request) async {
        throw Exception('no network');
      });

      final status = await backend.checkConnectionStatus(client);
      expect(status, ConnectionStatus.offline);
    });
  });

  group('BackendProxy.fetchMenuItems', () {
    final backend = BackendProxy();

    test('returns parsed list on 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/menuItems');
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'Cola',
              'description': '',
              'price': 0.0,
              'version': 1,
              'archived': false,
            },
            {
              'id': 2,
              'name': 'Fanta',
              'description': '',
              'price': 0.0,
              'version': 1,
              'archived': false,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final FetchResult<List<MenuItemModel>> result = await backend
          .fetchMenuItems(client);

      expect(result.isSuccess, isTrue);
      final items = result.data ?? <MenuItemModel>[];
      expect(items, hasLength(2));
      expect(items.first.name, 'Cola');
      expect(items.last.id, 2);
    });

    test('returns failure when backend responds with non-list JSON', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final FetchResult<List<MenuItemModel>> result = await backend
          .fetchMenuItems(client);

      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
    });

    test('returns failure on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final FetchResult<List<MenuItemModel>> result = await backend
          .fetchMenuItems(client);

      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
    });

    test('returns failure on malformed response body', () async {
      final client = MockClient((request) async {
        return http.Response('{', 200);
      });

      final FetchResult<List<MenuItemModel>> result = await backend
          .fetchMenuItems(client);

      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
    });
  });

  group('BackendProxy.deleteMenuItem', () {
    final backend = BackendProxy();
    test('returns true on 204 No Content', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final item = MenuItemModel(
        id: 187,
        name: '',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );
      final resp = await backend.deleteMenuItem(client, item);
      expect(resp, isTrue);
    });

    test('returns false on Server Error', () async {
      final client = MockClient((request) async {
        return http.Response('', 500);
      });

      final item = MenuItemModel(
        id: 187,
        name: '',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );
      final resp = await backend.deleteMenuItem(client, item);
      expect(resp, isFalse);
    });

    test('returns false on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final item = MenuItemModel(
        id: 187,
        name: '',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );
      final resp = await backend.deleteMenuItem(client, item);
      expect(resp, isFalse);
    });

    test('throws HTTPEceptions on 403 HTTP-Statuscodes', () async {
      final client = MockClient((request) async {
        return http.Response('error', 403);
      });
      final item = MenuItemModel(
        id: 0,
        name: 'Test',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );

      await expectLater(
        backend.deleteMenuItem(client, item),
        throwsA(isA<HttpException>()),
      );
    });

    test('throws HTTPEceptions on 422 HTTP-Statuscodes', () async {
      final client = MockClient((request) async {
        return http.Response('error', 422);
      });
      final item = MenuItemModel(
        id: 0,
        name: 'Test',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      );

      await expectLater(
        backend.deleteMenuItem(client, item),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group('BackendProxy.updateMenuItem', () {
    final backend = BackendProxy();
    final sampleItem = MenuItemModel(
      id: 1,
      name: 'Test',
      archived: false,
      description: "",
      price: 18.4,
      version: 1,
    );

    test('returns true on 204 No Content', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final resp = await backend.updateMenuItem(client, sampleItem);
      expect(resp, isTrue);
    });

    test('returns false on Server Error', () async {
      final client = MockClient((request) async {
        return http.Response('', 500);
      });

      final resp = await backend.updateMenuItem(client, sampleItem);
      expect(resp, isFalse);
    });

    test('returns false on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final resp = await backend.updateMenuItem(client, sampleItem);
      expect(resp, isFalse);
    });

    test('throws on 403 HTTP-Statuscode repsonse', () async {
      final client = MockClient((request) async {
        return http.Response('error', 403);
      });
      await expectLater(
        backend.updateMenuItem(client, sampleItem),
        throwsA(isA<HttpException>()),
      );
    });

    test('throws on 404 HTTP-Statuscode repsonse', () async {
      final client = MockClient((request) async {
        return http.Response('error', 404);
      });
      await expectLater(
        backend.updateMenuItem(client, sampleItem),
        throwsA(isA<HttpException>()),
      );
    });

    test('throws on 422 HTTP-Statuscode repsonse', () async {
      final client = MockClient((request) async {
        return http.Response('error', 422);
      });
      await expectLater(
        backend.updateMenuItem(client, sampleItem),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group('BackendProxy.fetchOrders', () {
    final backend = BackendProxy();

    test('returns parsed list on 200 response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://localhost:8080/barOrders');

        return http.Response(
          jsonEncode([
            {
              "id": 1,
              "items": [
                {
                  "quantity": 1,
                  "menuItem": {
                    "id": 10,
                    "name": "Bier",
                    "description": "BIIIIER",
                    "price": 5.0,
                    "version": 1,
                    "archived": false,
                  },
                },
              ],
              "barTable": {"id": 7},
            },
            {
              "id": 2,
              "items": [],
              "barTable": {"id": 3},
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ordersResult = await backend.fetchOrders(client);
      final orders = ordersResult.data;
      expect(orders, hasLength(2));
      expect(orders, isNotNull);
      expect(orders!.first.id, 1);
      expect(orders.first.table!.id, 7);
      expect(orders.first.items, hasLength(1));
      expect(orders.first.items.first.item.name, 'Bier');
      expect(orders.first.items.first.quantity, 1);
      expect(orders.last.id, 2);
      expect(orders.last.items, isEmpty);
    });

    test('returns failure on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final ordersResult = await backend.fetchOrders(client);
      expect(ordersResult.isSuccess, false);
    });

    test('returns failure Fetchresult on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final ordersResult = await backend.fetchOrders(client);
      expect(ordersResult.isSuccess, false);
    });

    test('returns failure on malformed response body', () async {
      final client = MockClient((request) async {
        return http.Response('{', 200);
      });

      final ordersResult = await backend.fetchOrders(client);
      expect(ordersResult.isSuccess, false);
    });
  });

  group('BackendProxy.createOrder', () {
    final backend = BackendProxy();

    final sampleOrder = OrderModel(
      id: 42,
      items: [
        OrderItemModel(
          item: MenuItemModel(
            id: 2,
            name: 'Pizza',
            description: 'Salami',
            price: 8.94,
            version: 1,
            archived: false,
          ),
          quantity: 2,
        ),
      ],
      table: TableModel(id: 7),
      archived: false,
    );

    test('returns true on 204 No Content', () async {
      late Uri capturedUri;
      late String capturedBody;
      late String? capturedContentType;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        capturedUri = request.url;
        capturedBody = request.body;
        capturedContentType = request.headers['content-type'];
        return http.Response('', 204);
      });

      final ok = await backend.createOrder(client, sampleOrder);

      expect(ok, isTrue);
      expect(capturedUri.toString(), 'http://localhost:8080/barOrder');
      expect(capturedContentType, 'application/json');

      final decoded = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(decoded['id'], 42);
      expect(decoded['barTable']['id'], 7);
      expect(decoded['items'], isA<List>());
      expect((decoded['items'] as List).length, 1);
    });

    test('returns false on non-204 success (e.g. 201 Created)', () async {
      final client = MockClient((request) async {
        return http.Response('', 201);
      });

      final ok = await backend.createOrder(client, sampleOrder);
      expect(ok, isFalse);
    });

    test('returns false on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final ok = await backend.createOrder(client, sampleOrder);
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final ok = await backend.createOrder(client, sampleOrder);
      expect(ok, isFalse);
    });
  });

  group('BackendProxy.updateOrder', () {
    final backend = BackendProxy();

    OrderModel buildOrder({int? id = 5}) => OrderModel(
      id: id,
      items: [
        OrderItemModel(
          item: MenuItemModel(
            id: 1,
            name: 'Burger',
            description: 'Cheese',
            price: 9.5,
            version: 1,
            archived: false,
          ),
          quantity: 1,
        ),
      ],
      table: TableModel(id: 1),
      archived: false,
    );

    test('returns true on 204 No Content and sends payload', () async {
      late Uri capturedUri;
      late String capturedBody;
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        capturedUri = request.url;
        capturedBody = request.body;
        return http.Response('', 204);
      });

      final order = buildOrder();
      final ok = await backend.updateOrder(client, order);

      expect(ok, isTrue);
      expect(capturedUri.toString(), 'http://localhost:8080/barOrder');
      final decoded = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(decoded['items'], isA<List>());
    });

    test('returns false when id is null without calling backend', () async {
      final client = MockClient((request) async {
        fail('Should not hit backend when id is null');
      });

      final order = buildOrder(id: null);
      final ok = await backend.updateOrder(client, order);

      expect(ok, isFalse);
    });

    test('returns false on non-204 response', () async {
      final client = MockClient((request) async {
        return http.Response('', 200);
      });

      final order = buildOrder();
      final ok = await backend.updateOrder(client, order);

      expect(ok, isFalse);
    });
  });

  group('BackendProxy.deleteOrder', () {
    final backend = BackendProxy();

    OrderModel buildOrder({int? id = 8}) => OrderModel(
      id: id,
      items: const [],
      table: TableModel(id: 2),
      archived: false,
    );

    test('returns true on 204 No Content', () async {
      late Uri capturedUri;
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        capturedUri = request.url;
        return http.Response('', 204);
      });

      final ok = await backend.deleteOrder(client, buildOrder());

      expect(ok, isTrue);
      expect(capturedUri.toString(), 'http://localhost:8080/barOrder/8');
    });

    test('returns false when id is null without calling backend', () async {
      final client = MockClient((request) async {
        fail('Should not hit backend when id is null');
      });

      final ok = await backend.deleteOrder(client, buildOrder(id: null));

      expect(ok, isFalse);
    });

    test('returns false on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final ok = await backend.deleteOrder(client, buildOrder());

      expect(ok, isFalse);
    });
  });

  group('BackendProxy.fetchTables', () {
    final backend = BackendProxy();

    test('returns parsed list on 200 response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://localhost:8080/barTables');

        return http.Response(
          jsonEncode([
            {'id': 1},
            {'id': 2},
            {'id': 99},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final tables = await backend.fetchTables(client);

      expect(tables, hasLength(3));
      expect(tables.first, TableModel(id: 1));
      expect(tables[1].id, 2);
      expect(tables.last.id, 99);
    });

    test('returns empty list on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final tables = await backend.fetchTables(client);
      expect(tables, isEmpty);
    });

    test('returns empty list on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final tables = await backend.fetchTables(client);
      expect(tables, isEmpty);
    });

    test('returns empty list on malformed response body', () async {
      final client = MockClient((request) async {
        return http.Response('{', 200);
      });

      final tables = await backend.fetchTables(client);
      expect(tables, isEmpty);
    });

    test('returns empty list when JSON is not a list', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'id': 1}), 200);
      });

      final tables = await backend.fetchTables(client);
      expect(tables, isEmpty);
    });
  });

  group('BackendProxy.closeOrder', () {
    final backend = BackendProxy();

    final sampleOrder = OrderModel(
      id: 42,
      items: [],
      table: TableModel(id: 7),
      archived: false,
    );

    test('returns true on 204 No Content', () async {
      late Uri capturedUri;

      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        capturedUri = request.url;
        return http.Response('', 204);
      });

      final ok = await backend.closeOrder(client, sampleOrder);

      expect(ok, isTrue);
      expect(
        capturedUri.toString(),
        'http://localhost:8080/barOrder/42/archive',
      );
    });

    test('returns false on non-204 (e.g. 200 OK)', () async {
      final client = MockClient((request) async {
        return http.Response('', 200);
      });

      final ok = await backend.closeOrder(client, sampleOrder);
      expect(ok, isFalse);
    });

    test('returns false on server error', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final ok = await backend.closeOrder(client, sampleOrder);
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      final client = MockClient((request) async {
        throw Exception('network');
      });

      final ok = await backend.closeOrder(client, sampleOrder);
      expect(ok, isFalse);
    });
  });
}
