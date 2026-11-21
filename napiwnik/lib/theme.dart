import 'package:flutter/material.dart';

const kTeal = Color(0xFF1F6F78);
const kBrass = Color(0xFFB8862B);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: kTeal, brightness: b).copyWith(
    secondary: kBrass,
    surface: dark ? const Color(0xFF10191C) : const Color(0xFFF1F4F1),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

const tabular = [FontFeature.tabularFigures()];

/// Blok treści z delikatnym obramowaniem (zamiast cieni).
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: s.surfaceContainerLowest,
        border: Border.all(color: s.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
