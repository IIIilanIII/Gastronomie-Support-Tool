import 'package:flutter/material.dart';

/// Ein Tab-Button innerhalb der Navigationsleiste.
/// In dieser Klasse sind die Komponenten für die Navigationsleiste zusammengefasst.
/// [label] ist der angezeigte Text, optional können [icon], [selected] und [onTap] übergeben werden, um das HeaderItem anzupassen.
class HeaderItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  final activeColor = Colors.white;
  final inactiveColor = Colors.grey;
  final textColor = Colors.black;

  const HeaderItem({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? activeColor : inactiveColor;
    final border = selected ? scheme.primary : scheme.outlineVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        // Key zuweisen, damit Tests das Element gezielt finden können
        key: Key(label),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border.withValues()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
