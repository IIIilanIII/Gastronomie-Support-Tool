import 'package:flutter/material.dart';
import 'package:frontend/widgets/list/list_item/header_item.dart';
import 'package:frontend/app_state.dart';

/// Horizontale Tab-Navigation mit Icons und Beschriftungen.
/// Für jeden Eintrag in [items] wird ein HeaderItem generiert.
/// Der aktive Tab in AppState wird beim klicken eines HeaderItems gesetzt.
class NavigationList extends StatelessWidget {
  final AppState appState;
  final List<AppTab> items;
  const NavigationList({
    super.key,
    required this.appState,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.35,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey,
          ),
          height: 50,
          alignment: Alignment.center,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(items.length, (i) {
                final label = items[i].label;
                final icon = items[i].icon;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i == items.length - 1 ? 0 : 12,
                  ),
                  child: HeaderItem(
                    label: label,
                    icon: icon,
                    selected: appState.tab.index == i,
                    onTap: () {
                      appState.setTab(AppTab.values[i]);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
