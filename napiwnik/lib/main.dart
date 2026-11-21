import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home.dart';
import 'screens/settings.dart';
import 'screens/stats.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl');
  try {
    await store.load();
  } catch (e) {
    // Zamiast białego ekranu pokazujemy błąd i pozwalamy spróbować ponownie.
    runApp(StartupError(error: e));
    return;
  }
  runApp(const NapiwnikApp());
}

class StartupError extends StatefulWidget {
  final Object error;
  const StartupError({super.key, required this.error});

  @override
  State<StartupError> createState() => _StartupErrorState();
}

class _StartupErrorState extends State<StartupError> {
  late Object _error = widget.error;
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await store.load();
      runApp(const NapiwnikApp());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nie udało się wczytać danych',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('Spróbuj ponownie. Jeśli problem wraca, zrób zdjęcie tego ekranu i zgłoś błąd.'),
                const SizedBox(height: 12),
                Text('$_error', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _retry,
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NapiwnikApp extends StatelessWidget {
  const NapiwnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Napiwnik',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: store.themeMode,
        locale: const Locale('pl'),
        supportedLocales: const [Locale('pl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Po powrocie do aplikacji ekrany przeliczają „dzisiaj” i bieżący miesiąc
  /// (aplikacja mogła leżeć w tle przez północ lub zmianę miesiąca).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refreshClock();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: const [
        HomeScreen(),
        StatsScreen(),
        SettingsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Dziennik'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Statystyki'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Ustawienia'),
        ],
      ),
    );
  }
}
