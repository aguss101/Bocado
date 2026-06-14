import 'package:flutter/material.dart';

class MacrosRibbon extends StatelessWidget {
  final int calories;
  final String protein;
  final String carbs;
  final String fats;

  const MacrosRibbon({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _MacroItem(label: 'Calorías', value: '$calories', color: null),
            VerticalDivider(color: dividerColor, thickness: 1, width: 1),
            _MacroItem(label: 'Proteína', value: protein, color: primary),
            VerticalDivider(color: dividerColor, thickness: 1, width: 1),
            _MacroItem(label: 'Carbs', value: carbs, color: null),
            VerticalDivider(color: dividerColor, thickness: 1, width: 1),
            _MacroItem(label: 'Grasas', value: fats, color: null),
          ],
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
