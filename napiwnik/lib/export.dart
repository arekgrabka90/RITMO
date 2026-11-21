import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'store.dart';

String _num(int grosze) => (grosze / 100).toStringAsFixed(2).replaceAll('.', ',');
String _esc(String s) => '"${s.replaceAll('"', '""')}"';

Future<void> exportCsv() async {
  final dir = await getTemporaryDirectory();
  final f = File(p.join(dir.path, 'napiwki.csv'));
  final b = StringBuffer('\uFEFF')
    ..writeln('data;miejsce;gotowka;karta;odliczenie;netto;godziny;na_godzine;notatka');
  final rows = [...store.tips]..sort((a, b) => a.date.compareTo(b.date));
  for (final t in rows) {
    final ph = t.perHour;
    b.writeln([
      DateFormat('yyyy-MM-dd').format(t.date),
      _esc(store.workplaceName(t.workplaceId)),
      _num(t.cash),
      _num(t.card),
      _num(t.tipOut),
      _num(t.net),
      t.hours == null ? '' : t.hours.toString().replaceAll('.', ','),
      ph == null ? '' : _num(ph.round()),
      _esc(t.note),
    ].join(';'));
  }
  await f.writeAsString(b.toString());
  await Share.shareXFiles([XFile(f.path)], text: 'Napiwnik: eksport CSV');
}

Future<void> shareBackup() async {
  final dir = await getTemporaryDirectory();
  final name = 'napiwnik-kopia-${DateFormat('yyyyMMdd').format(DateTime.now())}.json';
  final f = File(p.join(dir.path, name));
  await f.writeAsString(store.backupJson());
  await Share.shareXFiles([XFile(f.path)], text: 'Napiwnik: kopia zapasowa');
}
