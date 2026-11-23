import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'store.dart';
import 'util.dart';

String _num(int grosze) => (grosze / 100).toStringAsFixed(2).replaceAll('.', ',');

Future<void> exportCsv() async {
  final dir = await getTemporaryDirectory();
  final f = File(p.join(dir.path, 'napiwki.csv'));
  final b = StringBuffer('\uFEFF')
    ..writeln('data;miejsce;gotowka;karta;odliczenie;netto;godziny;na_godzine;utarg;notatka');
  final rows = [...store.tips]..sort((a, b) => a.date.compareTo(b.date));
  for (final t in rows) {
    final ph = t.perHour;
    b.writeln([
      DateFormat('yyyy-MM-dd').format(t.date),
      csvCell(store.workplaceName(t.workplaceId)),
      _num(t.cash),
      _num(t.card),
      _num(t.tipOut),
      _num(t.net),
      t.hours == null ? '' : fmtHours(t.hours!),
      ph == null ? '' : _num(ph.round()),
      t.sales == null ? '' : _num(t.sales!),
      csvCell(t.note),
    ].join(';'));
  }
  await f.writeAsString(b.toString());
  await Share.shareXFiles([XFile(f.path)], text: 'Napiwnik: eksport CSV');
}

/// Udostępnia kopię zapasową. Gdy użytkownik nie anulował udostępniania, zapamiętuje datę kopii
/// (przypomnienie na Dashboardzie pojawia się dopiero po dłuższym czasie).
Future<void> shareBackup() async {
  final dir = await getTemporaryDirectory();
  final name = 'napiwnik-kopia-${DateFormat('yyyyMMdd').format(DateTime.now())}.json';
  final f = File(p.join(dir.path, name));
  await f.writeAsString(store.backupJson());
  final res = await Share.shareXFiles([XFile(f.path)], text: 'Napiwnik: kopia zapasowa');
  if (res.status != ShareResultStatus.dismissed) {
    await store.markBackupDone();
  }
}

/// Udostępnia zwykły tekst (np. podsumowanie okresu).
Future<void> shareText(String text) async {
  await Share.share(text);
}
