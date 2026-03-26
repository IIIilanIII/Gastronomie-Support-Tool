import 'package:flutter/material.dart';
import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/utils/fetch_result.dart';
import '../../app_state.dart';
import 'package:frontend/widgets/list/list_item/menu_item.dart';

/// Parst Optionen aus der freien Suchzeichenfolge.
/// Aus der Suchleiste werden [version] und [archived] verwendet um die MenuItems zu filtern.
class _MenuSearchFilters {
  const _MenuSearchFilters({this.version, this.archived, this.text = ''});

  final int? version;
  final bool? archived;
  final String text;

  static _MenuSearchFilters parse(String raw) {
    final query = raw.trim();
    if (query.isEmpty) {
      return const _MenuSearchFilters();
    }

    final versionPattern = RegExp(
      r'(?:^|\s)(?:version|v)\s*[:=]\s*(\d+)',
      caseSensitive: false,
    );
    final archivedPattern = RegExp(
      r'(?:^|\s)(?:archived|archive)\s*[:=]?\s*(true|false)?',
      caseSensitive: false,
    );

    int? versionNumber;
    bool? archived;
    var remaining = query;

    final vMatch = versionPattern.firstMatch(query);
    if (vMatch != null) {
      final matchedText = vMatch.group(0) ?? '';
      remaining = remaining.replaceFirst(matchedText, '').trim();
      versionNumber = int.tryParse(vMatch.group(1) ?? '');
    }

    final aMatch = archivedPattern.firstMatch(query);
    if (aMatch != null) {
      final matchedText = aMatch.group(0) ?? '';
      remaining = remaining.replaceFirst(matchedText, '').trim();
      final val = aMatch.group(1);
      if (val == null || val.isEmpty) {
        archived = true;
      } else {
        archived = val.toLowerCase() == 'true';
      }
    }

    if (versionNumber == null && RegExp(r'^\d+$').hasMatch(query)) {
      return _MenuSearchFilters(
        version: int.tryParse(query),
        archived: archived,
        text: '',
      );
    }

    return _MenuSearchFilters(
      version: versionNumber,
      archived: archived,
      text: remaining,
    );
  }
}

/// Lädt Menüpunkte vom Backend, zeigt sie in einer Liste und aktualisiert den
/// Verbindungsstatus anhand des letzten Abrufs. Zwischengespeicherte Daten
/// werden Clientseitig gefiltert [searchQuery], um Suchbegriffe effizient anzuwenden.
/// [refreshToken] wird von den untergeordneten Widgets incrementiert, wenn die Liste aus dem Backend erneut geladen werden soll.
class MenuList extends StatefulWidget {
  final int refreshToken;
  final String searchQuery;

  const MenuList({
    super.key,
    required this.refreshToken,
    required this.searchQuery,
  });

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  Future<FetchResult<List<MenuItemModel>>>? _itemsFuture;
  List<MenuItemModel>? _cachedItems;
  int? _lastRefreshToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_itemsFuture == null || _lastRefreshToken != widget.refreshToken) {
      _loadItems();
    }
  }

  @override
  void didUpdateWidget(covariant MenuList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadItems();
    }
  }

  void _loadItems() {
    final appState = AppStateScope.of(context);

    _itemsFuture = appState.backend.fetchMenuItems(appState.client);

    _itemsFuture!.then((result) {
      appState.setConnectionStatus(
        result.isSuccess ? ConnectionStatus.online : ConnectionStatus.offline,
      );

      // Optionaler Ort, um erfolgreiche Ergebnisse zwischenzuspeichern
      // if (result.isSuccess) _cachedItems = result.data;
    });

    _lastRefreshToken = widget.refreshToken;
    _cachedItems = null;
  }

  @override
  Widget build(BuildContext context) {
    final future = _itemsFuture;
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filters = _MenuSearchFilters.parse(widget.searchQuery);

    return FutureBuilder<FetchResult<List<MenuItemModel>>>(
      key: ValueKey(_lastRefreshToken),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = snapshot.data;
        if (result != null && result.isSuccess) {
          _cachedItems = result.data ?? <MenuItemModel>[];
        }
        final items = _cachedItems ?? [];
        // Kopie der Liste, die wir anschließend nach Suchparametern filtern
        var filteredItems = List<MenuItemModel>.from(items);

        if (filters.version != null) {
          filteredItems.retainWhere((item) => item.version == filters.version);
        }

        if (filters.archived != null) {
          filteredItems.retainWhere(
            (item) => item.archived == filters.archived,
          );
        } else if (filters.version == null) {
          filteredItems.retainWhere((item) => !item.archived);
        }

        if (filters.text.isNotEmpty) {
          final needle = filters.text.toLowerCase();
          filteredItems = filteredItems.where((item) {
            final name = item.name.toLowerCase();
            final description = item.description.toLowerCase();
            return name.contains(needle) || description.contains(needle);
          }).toList();
        }

        if (items.isEmpty) {
          return const Center(child: Text('Keine Menüpunkte vorhanden.'));
        }

        if (filteredItems.isEmpty) {
          if (filters.version != null) {
            return Center(
              child: Text(
                'Keine Menüpunkte für Version ${filters.version} gefunden.',
              ),
            );
          }
          if (filters.archived != null) {
            return Center(
              child: Text(
                filters.archived == true
                    ? 'Keine archivierten Menüpunkte gefunden.'
                    : 'Keine aktiven Menüpunkte gefunden.',
              ),
            );
          }
          if (filters.text.isNotEmpty) {
            return Center(
              child: Text('Keine Treffer für "${filters.text}" gefunden.'),
            );
          }
          return const Center(
            child: Text(
              'Keine aktiven Menüpunkte vorhanden. Suche nach "archived:true" für archivierte Einträge.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return MenuItem(menuItem: item);
          },
        );
      },
    );
  }
}
