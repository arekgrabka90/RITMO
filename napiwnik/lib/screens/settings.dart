import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../export.dart';
import '../models.dart';
import '../period.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

/// Maksymalna stawka godzinowa przyjęta w aplikacji: 1000 zł/h (w groszach).
const _maxRate = 100000;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final monthly = store.periodType == PeriodType.monthly;
        final nextPay = nextPayday(DateTime.now(), store.payDay);
        return Scaffold(
          appBar: AppBar(title: const Text('Ustawienia')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _section(context, 'Miejsca pracy'),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final w in store.workplaces)
                      Dismissible(
                        key: ValueKey('place-${w.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(context, w),
                        onDismissed: (_) => _deleteWorkplace(context, w),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        child: ListTile(
                          title: Text(w.name),
                          subtitle: Text(w.hourlyRate > 0
                              ? 'Stawka: ${fmtMoney(w.hourlyRate)}/h'
                              : 'Brak stawki godzinowej'),
                          onTap: () => _placeDialog(context, w),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Dodaj miejsce pracy'),
                      onTap: () => _placeDialog(context, null),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Dotknij miejsca, aby zmienić nazwę i stawkę. Przesuń w lewo, aby usunąć.',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
              _section(context, 'Okres rozliczeniowy'),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Rozliczenie'),
                      subtitle: Text(periodTypeName(store.periodType)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _periodTypeDialog(context),
                    ),
                    ListTile(
                      enabled: !monthly,
                      title: const Text('Początek okresu'),
                      subtitle: Text(monthly
                          ? 'Miesiąc kalendarzowy zaczyna się 1. dnia miesiąca'
                          : 'Od ${DateFormat('d MMMM y', 'pl').format(store.periodAnchor)}, bieżący okres: ${periodRangeLabel(store.currentPeriod)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: monthly ? null : () => _anchorPicker(context),
                    ),
                    ListTile(
                      title: const Text('Cel napiwków na okres'),
                      subtitle: Text(store.goal == 0
                          ? 'Brak celu'
                          : '${fmtMoney(store.goal)} · pasek postępu na Dashboardzie'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _goalDialog(context),
                    ),
                  ],
                ),
              ),
              _section(context, 'Tydzień'),
              Panel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: const Text('Pierwszy dzień tygodnia'),
                  subtitle: Text(weekdayNames[store.weekStartDay - 1]),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _weekStartDialog(context),
                ),
              ),
              _section(context, 'Wypłata'),
              Panel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: const Text('Dzień wypłaty'),
                  subtitle: Text(nextPay == null
                      ? 'Nie ustawiono'
                      : '${store.payDay}. dnia miesiąca, najbliższa: ${DateFormat('d MMMM', 'pl').format(nextPay)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _payDayDialog(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Na tydzień przed wypłatą na Dashboardzie pojawi się licznik dni.',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
              _section(context, 'Wygląd'),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Jasny')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Ciemny')),
                ],
                selected: {store.themeMode},
                onSelectionChanged: (s) => store.setThemeMode(s.first),
              ),
              _section(context, 'Dane'),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.table_chart_outlined),
                      title: const Text('Eksportuj do CSV'),
                      subtitle: const Text('Do otwarcia w Excelu lub Arkuszach'),
                      onTap: () => _run(context, exportCsv),
                    ),
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Zrób kopię zapasową'),
                      subtitle: const Text('Plik JSON: wpisy, zmiany, miejsca pracy i ustawienia'),
                      onTap: () => _run(context, shareBackup),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Przywróć z kopii'),
                      subtitle: const Text('Zastępuje wszystkie obecne dane'),
                      onTap: () => _restore(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Wszystkie dane są tylko na tym telefonie. Aplikacja nie ma kont ani chmury, więc rób kopie zapasowe.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall),
      );

  void _msg(BuildContext context, String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(BuildContext context, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (context.mounted) _msg(context, 'Nie udało się: $e');
    }
  }

  /// Lista wyboru: dotknięcie opcji zamyka okno i zwraca jej wartość.
  Future<T?> _choose<T>(
    BuildContext context,
    String title,
    T current,
    List<MapEntry<T, String>> options,
  ) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final o in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o.key),
              child: Row(children: [
                Icon(
                  o.key == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: o.key == current ? kTeal : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(o.value)),
              ]),
            ),
        ],
      ),
    );
  }

  Future<void> _periodTypeDialog(BuildContext context) async {
    final t = await _choose<PeriodType>(
      context,
      'Rozliczenie',
      store.periodType,
      [for (final t in PeriodType.values) MapEntry(t, periodTypeName(t))],
    );
    if (t != null) await store.setPeriodType(t);
  }

  Future<void> _anchorPicker(BuildContext context) async {
    final now = dateOnly(DateTime.now());
    final first = DateTime(2020);
    final last = DateTime(now.year + 1, 12, 31);
    var initial = store.periodAnchor;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pierwszy dzień okresu rozliczeniowego',
    );
    if (d != null) await store.setPeriodAnchor(d);
  }

  Future<void> _weekStartDialog(BuildContext context) async {
    final d = await _choose<int>(
      context,
      'Pierwszy dzień tygodnia',
      store.weekStartDay,
      [for (var i = 1; i <= 7; i++) MapEntry(i, weekdayNames[i - 1])],
    );
    if (d != null) await store.setWeekStartDay(d);
  }

  Future<void> _payDayDialog(BuildContext context) async {
    final c = TextEditingController(text: store.payDay == 0 ? '' : '${store.payDay}');
    String? error;
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Dzień wypłaty'),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Dzień miesiąca (1–31)',
              helperText: 'W krótszych miesiącach liczy się ostatni dzień. Puste = bez wypłaty',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
            FilledButton(
              onPressed: () {
                final t = c.text.trim();
                if (t.isEmpty) {
                  Navigator.pop(ctx, 0);
                  return;
                }
                final n = int.tryParse(t);
                if (n == null || n < 1 || n > 31) {
                  setState(() => error = 'Podaj liczbę od 1 do 31');
                  return;
                }
                Navigator.pop(ctx, n);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    if (v != null) await store.setPayDay(v);
  }

  Future<void> _placeDialog(BuildContext context, Workplace? w) async {
    final name = TextEditingController(text: w?.name ?? '');
    final rate = TextEditingController(text: w == null ? '' : fmtInput(w.hourlyRate));
    String? nameError;
    String? rateError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(w == null ? 'Nowe miejsce pracy' : 'Miejsce pracy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Nazwa', errorText: nameError),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Stawka godzinowa',
                  suffixText: 'zł/h',
                  helperText: 'Kwota, którą chcesz wliczać do zarobków. Puste = bez stawki',
                  errorText: rateError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
            FilledButton(
              onPressed: () {
                final n = name.text.trim();
                final r = parseMoney(rate.text);
                final badName = n.isEmpty;
                final badRate = r == null || r > _maxRate;
                if (badName || badRate) {
                  setState(() {
                    nameError = badName ? 'Wpisz nazwę' : null;
                    rateError = badRate ? 'Podaj kwotę, np. 32,50 (maks. 1000)' : null;
                  });
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
    final n = name.text.trim();
    final r = parseMoney(rate.text) ?? 0;
    name.dispose();
    rate.dispose();
    if (ok != true) return;
    try {
      if (w == null) {
        await store.addWorkplace(n, rate: r);
      } else {
        await store.updateWorkplace(w.id!, n, r);
      }
    } catch (_) {
      if (context.mounted) _msg(context, 'Nie udało się zapisać miejsca pracy.');
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Workplace w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Usunąć „${w.name}”?'),
        content: const Text('Wpisy i zmiany z tego miejsca zostaną, ale stracą przypisanie do miejsca.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteWorkplace(BuildContext context, Workplace w) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.deleteWorkplace(w.id!);
    } catch (_) {
      try {
        await store.load();
      } catch (_) {}
      messenger.clearSnackBars();
      messenger.showSnackBar(
          const SnackBar(content: Text('Nie udało się usunąć miejsca pracy.')));
    }
  }

  Future<void> _goalDialog(BuildContext context) async {
    final c = TextEditingController(text: fmtInput(store.goal));
    String? error;
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cel napiwków na okres'),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Kwota netto',
              suffixText: 'zł',
              helperText: 'Zostaw puste, aby wyłączyć',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
            FilledButton(
              onPressed: () {
                final r = parseMoney(c.text);
                if (r == null) {
                  setState(() => error = 'Podaj kwotę, np. 3000 albo 3000,50');
                  return;
                }
                Navigator.pop(ctx, r);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    if (v != null) await store.setGoal(v);
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Przywrócić z kopii?'),
        content: const Text('Wszystkie obecne wpisy, zmiany i miejsca pracy zostaną zastąpione danymi z pliku. Ustawienia z pliku (okres, tydzień, wypłata) też się zmienią.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Wybierz plik')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = r?.files.single.path;
      if (path == null) return;
      await store.restore(await File(path).readAsString());
      if (context.mounted) _msg(context, 'Dane przywrócone.');
    } on FormatException catch (e) {
      if (context.mounted) _msg(context, e.message);
    } catch (e) {
      if (context.mounted) _msg(context, 'Nie udało się przywrócić: $e');
    }
  }
}
