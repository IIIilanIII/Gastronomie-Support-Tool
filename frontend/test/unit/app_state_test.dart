import 'dart:async';

import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class StubBackend extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async {
    return ConnectionStatus.online;
  }
}

class StubBackendOnline extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async {
    return ConnectionStatus.online;
  }
}

class StubBackendOffline extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async {
    return ConnectionStatus.offline;
  }
}

class StubWithItems extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    return FetchResult.success([
      MenuItemModel(
        id: 1,
        name: 'A',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      ),
      MenuItemModel(
        id: 2,
        name: 'B',
        description: '',
        price: 0.0,
        version: 1,
        archived: false,
      ),
    ]);
  }
}

class StubError extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;

  @override
  Future<FetchResult<List<MenuItemModel>>> fetchMenuItems(
    http.Client client,
  ) async {
    // vorher: throw Exception('network');
    return FetchResult.failure(Exception('network'));
  }
}

/// helper to wait until condition or timeout
Future<void> waitUntil(
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final end = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Condition not met in time');
    }
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('AppState backend loading', () {});

  group('AppState constructor and tab behaviors', () {
    test('constructor triggers connection status online', () async {
      final appState = AppState(StubBackendOnline(), http.Client());
      await waitUntil(() => appState.cStatus == ConnectionStatus.online);
      expect(appState.cStatus, ConnectionStatus.online);
    });

    test('constructor triggers connection status offline', () async {
      final appState = AppState(StubBackendOffline(), http.Client());
      await waitUntil(() => appState.cStatus == ConnectionStatus.offline);
      expect(appState.cStatus, ConnectionStatus.offline);
    });

    test('setTab updates tab and ignores same value', () {
      final appState = AppState(StubBackendOnline(), http.Client());
      expect(appState.tab, isA<AppTab>());
      final initial = appState.tab;
      appState.setTab(AppTab.menu);
      expect(appState.tab, AppTab.menu);
      appState.setTab(AppTab.menu);
      expect(appState.tab, AppTab.menu);
      appState.setTab(initial);
      expect(appState.tab, initial);
    });
  });

  // AppState no longer stores menu items locally; menu list tests were moved to widget tests.
}
