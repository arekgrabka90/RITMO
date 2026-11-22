import 'package:flutter/material.dart';

/// Pasek „‹  Listopad 2026  ›” wspólny dla Dziennika, Statystyk i Grafiku.
/// Przycisk z wartością null jest wyłączony.
class PeriodSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTap; // dotknięcie etykiety, np. skok do „dziś”

  const PeriodSwitcher({
    super.key,
    required this.label,
    this.onPrev,
    this.onNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Wstecz',
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Dalej',
        ),
      ],
    );
  }
}
