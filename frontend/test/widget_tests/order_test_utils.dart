import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_state.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/table_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/form/order_form.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> menuItemJson(
  int id,
  String name,
  double price, {
  String description = '',
  int version = 1,
  bool archived = false,
}) => {
  'id': id,
  'name': name,
  'description': description,
  'price': price,
  'version': version,
  'archived': archived,
};

MenuItemModel mi(int id, String name, double price, {bool archived = false}) =>
    MenuItemModel(
      id: id,
      name: name,
      description: '',
      price: price,
      version: 1,
      archived: archived,
    );

class StubBackendMinimal extends BackendProxy {
  @override
  Future<ConnectionStatus> checkConnectionStatus(http.Client client) async =>
      ConnectionStatus.online;
}

AppState newAppState(BackendProxy backend) {
  // vermeidet "HttpClient created" warning im Widget-Test (kein dart:io HttpClient)
  final client = MockClient((_) async => http.Response('', 200));
  final appState = AppState(backend, client);
  addTearDown(appState.dispose);
  return appState;
}

Future<BuildContext> pumpHostApp(WidgetTester tester, AppState state) async {
  late BuildContext hostContext;

  await tester.pumpWidget(
    AppStateScope(
      notifier: state,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  return hostContext;
}

Future<void> openOrderFormDialog(
  WidgetTester tester, {
  required AppState appState,
  required OrderForm form,
  bool settle = true,
}) async {
  final ctx = await pumpHostApp(tester, appState);

  showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => form,
  );

  await tester.pump(); // Dialog reinpumpen
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // NICHT settle'n, sonst timeout bei Spinner-Animation
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Finder tableDropdown() => find
    .byWidgetPredicate(
      (w) =>
          w is DropdownButton<TableModel> ||
          w is DropdownButtonFormField<TableModel>,
    )
    .first;

Finder iconButtonWithTooltip(String tooltip) =>
    find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tooltip);

Finder snackBarTextContaining(String s) => find.descendant(
  of: find.byType(SnackBar),
  matching: find.textContaining(s),
);

OrderForm makeOrderForm({
  required OrderModel order,
  required Future<List<TableModel>> Function() fetchTables,
  required Future<FetchResult<List<MenuItemModel>>> Function() fetchMenuItems,
  required Future<bool> Function(OrderModel, ScaffoldMessengerState) action,
  VoidCallback? onSaved,
  String title = 'Neue Bestellung',
  String saveButtonText = 'Erstellen',
  String successPrefix = 'OK',
  String errorPrefix = 'ERR',
}) {
  return OrderForm(
    order: order,
    title: title,
    saveButtonText: saveButtonText,
    successPrefix: successPrefix,
    errorPrefix: errorPrefix,
    onSaved: onSaved ?? () {},
    action: action,
    fetchMenuItems: fetchMenuItems,
    fetchTables: fetchTables,
  );
}
