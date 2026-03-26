import 'package:flutter/material.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:http/http.dart' as http;

/// Tabs der Anwendung, die durch die Navigation gewechselt werden.
enum AppTab {
  // Optionaler Tab für Tischverwaltung
  menu(icon: Icons.restaurant_menu, label: 'Menü'),
  order(icon: Icons.receipt_long, label: 'Bestellungen');

  final IconData icon;
  final String label;

  const AppTab({required this.icon, required this.label});
}

/// Beschreibt den aktuellen Online-/Offline-Status des Clients.
enum ConnectionStatus {
  online(message: 'Online', color: Colors.lightGreen),
  offline(message: 'Offline', color: Colors.red);

  final String message;
  final Color color;

  const ConnectionStatus({required this.message, required this.color});
}

/// Zentraler Zustand der App mit Backend-Proxy [backend], Client [client] und Refresh-Tokens.
/// Prüft bei innitialisierung den OnlineStatus zum [backend].
class AppState extends ChangeNotifier {
  AppTab _tab = AppTab.order;
  ConnectionStatus _connectionStatus = ConnectionStatus.offline;
  late BackendProxy _backend;
  late http.Client _client;
  int _menuListRefreshToken = 0;
  int _orderListRefreshToken = 0;

  AppTab get tab => _tab;
  ConnectionStatus get cStatus => _connectionStatus;
  BackendProxy get backend => _backend;
  http.Client get client => _client;
  int get menuListRefreshToken => _menuListRefreshToken;
  int get orderListRefreshToken => _orderListRefreshToken;

  AppState(BackendProxy backend, http.Client client) {
    _backend = backend;
    _client = client;
    _initConnectionStatus();
  }

  void setTab(AppTab t) {
    if (_tab == t) return;
    _tab = t;
    notifyListeners();
  }

  void bumpMenuListRefreshToken() {
    _menuListRefreshToken++;
    notifyListeners();
  }

  void bumpOrderListRefreshToken() {
    _orderListRefreshToken++;
    notifyListeners();
  }

  void setConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    notifyListeners();
  }

  Future<void> _initConnectionStatus() async {
    final status = await _backend.checkConnectionStatus(_client);
    setConnectionStatus(status);
  }
}

// Inherited-Wrapper, damit Widgets auf den [AppState] zugreifen können.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(
      scope != null,
      'AppStateScope nicht gefunden. Baum korrekt aufgebaut?',
    );
    return scope!.notifier!;
  }
}
