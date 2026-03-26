import 'package:flutter/material.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:frontend/widgets/list/list_item/order_item.dart';
import '../../app_state.dart';

/// Lädt Bestellungen vom Backend und zeigt sie sortiert in einer Liste an.
/// Offene Bestellung zuerst und darauf folgend die archvivierten Bestellungen
class OrderList extends StatefulWidget {
  final int refreshToken;

  const OrderList({super.key, required this.refreshToken});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  Future<FetchResult<List<OrderModel>>>? _ordersFuture;
  int? _lastRefreshToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ordersFuture == null || _lastRefreshToken != widget.refreshToken) {
      _loadOrders();
    }
  }

  @override
  void didUpdateWidget(covariant OrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    final appState = AppStateScope.of(context);
    _ordersFuture = appState.backend.fetchOrders(appState.client);

    _ordersFuture!.then((result) {
      appState.setConnectionStatus(
        result.isSuccess ? ConnectionStatus.online : ConnectionStatus.offline,
      );
    });
    _lastRefreshToken = widget.refreshToken;
  }

  @override
  Widget build(BuildContext context) {
    final future = _ordersFuture;
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<FetchResult<List<OrderModel>>>(
      key: ValueKey(_lastRefreshToken),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.data ?? <OrderModel>[];

        if (orders.isEmpty) {
          return const Center(child: Text('Keine Bestellungen vorhanden.'));
        }
        orders.sort((a, b) {
          if (a.archived == b.archived) return 0;
          return a.archived ? 1 : -1; // Nicht archivierte Bestellungen zuerst
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final o = orders[index];

            return OrderItem(order: o);
          },
        );
      },
    );
  }
}
