import 'package:flutter/material.dart';

import '../theme.dart';

/// Przesunięcie palcem w bok na [child] wywołuje [onPrev] (w prawo) albo [onNext] (w lewo).
/// Brak funkcji = ten kierunek jest wyłączony. Używane przy paskach okresu.
class Swipeable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const Swipeable({super.key, required this.child, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300) {
          onNext?.call();
        } else if (v > 300) {
          onPrev?.call();
        }
      },
      child: child,
    );
  }
}

/// Kafelek z dużą liczbą: podpis, wartość, opcjonalny opis i dodatek (np. pasek postępu).
/// Dotknięcie ([onTap]) otwiera szczegóły, przytrzymanie ([onLongPress]) daje opcje.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;
  final Widget? extra;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.extra,
    this.onTap,
    this.onLongPress,
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
    if (onTap == null && onLongPress == null) return panel;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      onLongPress: onLongPress,
      child: panel,
    );
  }
}
