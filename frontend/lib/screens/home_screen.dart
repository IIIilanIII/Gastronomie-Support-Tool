import 'package:flutter/material.dart';
import 'package:frontend/widgets/button/add_order_button.dart';
import 'package:frontend/widgets/list/navigation_list.dart';
import 'package:frontend/widgets/list/order_list.dart';
import '../widgets/list/menu_list.dart';
import '../widgets/button/add_menu_button.dart';
import '../app_state.dart';

/// Einstiegsscreen, der zwischen Menü- und Bestellansicht umschaltet.
/// Zeigt den aktuellen OnlineStatus im AppState im UI an
/// und lädt anhand des AppState.lab Wertes dynamisch die richtige Listenansicht und ggf. eine Suchleiste.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Steuert Suche, Tabs und Sichtbarkeit der Listen.
class _HomeScreenState extends State<HomeScreen> {
  late final SearchController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Aktualisiert die lokale Suchzeichenfolge bei Texteingaben.
  void _handleSearchChanged() {
    final nextQuery = _searchController.text;
    if (nextQuery == _searchQuery) {
      return;
    }
    setState(() {
      _searchQuery = nextQuery;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);
    final label = appState.tab.label;
    final isMenuTab = appState.tab == AppTab.menu;
    final connectionStatus = appState.cStatus;
    final statusIcon = connectionStatus == ConnectionStatus.online
        ? Icons.cloud_done_outlined
        : Icons.cloud_off_outlined;
    final statusColor = connectionStatus == ConnectionStatus.online
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F6FB), Color(0xFFE5ECFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NavigationList(
                        appState: appState,
                        items: AppTab.values,
                      ), //Navigationsbereich
                      const SizedBox(height: 20),
                      //Suchleiste- und Hinzufügeknopfbereich
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child:
                            isMenuTab // Für MenuItems und Bestellungen sind unterschiedliche Aktionen notwendig, bspw. keine Suchleiste bei Bestellungen
                            ? Column(
                                key: const ValueKey('menu-actions'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    child: AddMenuButton(
                                      onCreated: () {
                                        if (mounted) setState(() {});
                                        appState.bumpMenuListRefreshToken();
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SearchBar(
                                    controller: _searchController,
                                    hintText:
                                        '$label durchsuchen (z.B. version:3, archived:true)',
                                    leading: const Icon(Icons.search),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('order-actions'),
                                children: [
                                  Align(
                                    child: AddOrderButton(
                                      onCreated: () {
                                        if (mounted) setState(() {});
                                        appState.bumpOrderListRefreshToken();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                //Listenbereich
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isMenuTab
                            ? MenuList(
                                key: const ValueKey('menu-list'),
                                refreshToken: appState.menuListRefreshToken,
                                searchQuery: _searchQuery,
                              )
                            : OrderList(
                                key: const ValueKey('order-list'),
                                refreshToken: appState.orderListRefreshToken,
                              ),
                      ),
                    ),
                  ),
                ),
                // Onlinestatus Bereich
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.18),
                          statusColor.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withOpacity(0.15),
                          ),
                          child: Icon(statusIcon, size: 18, color: statusColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          connectionStatus.message,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
