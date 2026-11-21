import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../export.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
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
                    ListTile(
                      title: Text(w.name),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Zmień nazwę',
                          onPressed: () => _nameDialog(context, w),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Usuń',
                          onPressed: () => _confirmDelete(context, w),
                        ),
                      ]),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Dodaj miejsce pracy'),
                    onTap: () => _nameDialog(context, null),
                  ),
                ],
              ),
            ),
            _section(context, 'Cel miesięczny'),
            Panel(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(store.goal == 0 ? 'Brak celu' : fmtMoney(store.goal)),
                subtitle: const Text('Pasek postępu na ekranie głównym'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _goalDialog(context),
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
                    subtitle: const Text('Plik JSON, zapisz go poza telefonem'),
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
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

  Future<void> _nameDialog(BuildContext context, Workplace? w) async {
    final c = TextEditingController(text: w?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(w == null ? 'Nowe miejsce pracy' : 'Zmień nazwę'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nazwa'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Zapisz')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (w == null) {
      await store.addWorkplace(name);
    } else {
      await store.renameWorkplace(w.id!, name);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Workplace w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Usunąć „${w.name}”?'),
        content: const Text('Wpisy z tego miejsca zostaną, ale stracą przypisanie do miejsca.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (ok == true) await store.deleteWorkplace(w.id!);
  }

  Future<void> _goalDialog(BuildContext context) async {
    final c = TextEditingController(text: fmtInput(store.goal));
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cel miesięczny'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Kwota netto', suffixText: 'zł', helperText: 'Zostaw puste, aby wyłączyć'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, parseMoney(c.text)), child: const Text('Zapisz')),
        ],
      ),
    );
    if (v != null) await store.setGoal(v);
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Przywrócić z kopii?'),
        content: const Text('Wszystkie obecne wpisy i miejsca pracy zostaną zastąpione danymi z pliku.'),
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
