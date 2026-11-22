import 'package:flutter/material.dart';

import '../theme.dart';

/// Kafelek z dużą liczbą: podpis, wartość, opcjonalny opis i dodatek (np. pasek postępu).
/// Z [onTap] dotknięcie otwiera szczegóły.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;
  final Widget? extra;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.extra,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final panel = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: s.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                fontFeatures: tabular,
                color: valueColor,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: TextStyle(fontSize: 13, color: s.onSurfaceVariant)),
          ],
          if (extra != null) extra!,
        ],
      ),
    );
    if (onTap == null) return panel;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: panel,
    );
  }
}
