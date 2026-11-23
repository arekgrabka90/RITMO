import 'dart:convert';

import 'dates.dart';
import 'models.dart';
import 'period.dart';
import 'planning.dart';

const backupApp = 'napiwnik';
const backupVersion = 2; // 1 = bez grafiku (nadal wczytywana), 2 = z grafikiem

/// Ustawienia zapisywane w kopii. Każde pole może być null (nie podano lub zła wartość),
/// a wtedy po przywróceniu zostaje obecne ustawienie. PIN blokady nie jest w kopii.
class BackupSettings {
  final int? weekStartDay; // 1–7
  final PeriodType? periodType;
  final DateTime? periodAnchor;
  final int? payDay; // 0 = brak, 1–31 (wypłata co miesiąc)
  final int? payOffset; // -1 = brak, 0–14 (dni po końcu okresu tygodniowego/dwutygodniowego)
  final List<ShiftTemplate>? templates;
  const BackupSettings({
    this.weekStartDay,
    this.periodType,
    this.periodAnchor,
    this.payDay,
    this.payOffset,
    this.templates,
  });

  Map<String, Object?> toMap() => {
        'week_start': weekStartDay,
        'period_type': periodType?.index,
        'period_anchor': periodAnchor == null ? null : dayKey(periodAnchor!),
        'pay_day': payDay,
        'pay_offset': payOffset,
        'templates': templates?.map((t) => t.toMap()).toList(),
      };
}

class BackupData {
  final List<Workplace> workplaces;
  final List<Tip> tips;
  final List<Shift> shifts;
  final int goal;
  final BackupSettings? settings;
  const BackupData({
    required this.workplaces,
    required this.tips,
    this.shifts = const [],
    required this.goal,
    this.settings,
  });
}

String encodeBackup({
  required List<Workplace> workplaces,
  required List<Tip> tips,
  List<Shift> shifts = const [],
  required int goal,
  BackupSettings? settings,
}) =>
    const JsonEncoder.withIndent('  ').convert({
      'app': backupApp,
      'version': backupVersion,
      'workplaces': workplaces.map((w) => w.toMap()).toList(),
      'tips': tips.map((t) => t.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'goal': goal,
      if (settings != null) 'settings': settings.toMap(),
    });

/// Ustawienia czytamy łagodnie: zła wartość jest po prostu pomijana, a nie uszkadza całej kopii.
BackupSettings? _parseSettings(Object? raw) {
  if (raw is! Map) return null;
  int? ranged(Object? v, int min, int max) => (v is int && v >= min && v <= max) ? v : null;
  final pt = ranged(raw['period_type'], 0, PeriodType.values.length - 1);
  DateTime? anchor;
  final a = raw['period_anchor'];
  if (a is String) {
    final d = DateTime.tryParse(a);
    if (d != null && d.year >= 2000 && d.year <= 2100) anchor = dateOnly(d);
  }
  final tr = raw['templates'];
  final templates = tr is List
      ? tr.map(ShiftTemplate.tryParse).whereType<ShiftTemplate>().toList()
      : null;
  return BackupSettings(
    weekStartDay: ranged(raw['week_start'], 1, 7),
    periodType: pt == null ? null : PeriodType.values[pt],
    periodAnchor: anchor,
    payDay: ranged(raw['pay_day'], 0, 31),
    payOffset: ranged(raw['pay_offset'], -1, 14),
    templates: templates,
  );
}

/// Czyta i waliduje kopię zapasową BEZ dotykania bazy. Rzuca FormatException z komunikatem po polsku.
/// Wpis lub zmiana wskazujące na nieistniejące miejsce pracy zostają, ale tracą przypisanie.
/// Zmiana wskazująca na nieistniejący (albo już zajęty) wpis napiwków traci to połączenie.
/// Starsze kopie bez stawki godzinowej miejsca pracy, bez utargu wpisu i bez ustawień wczytują się
/// z wartościami domyślnymi.
BackupData parseBackup(String json) {
  const notBackup = FormatException('To nie jest kopia zapasowa Napiwnika.');
  const broken = FormatException('Plik kopii jest uszkodzony.');

  Object? data;
  try {
    data = jsonDecode(json);
  } catch (_) {
    throw notBackup;
  }
  if (data is! Map || data['app'] != backupApp) throw notBackup;
  final version = data['version'];
  if (version != 1 && version != 2) throw notBackup;

  try {
    final workplaces = <Workplace>[];
    final workplaceIds = <int>{};
    for (final e in data['workplaces'] as List) {
      final w = Workplace.fromMap(Map<String, Object?>.from(e as Map));
      final id = w.id;
      if (id == null || w.name.trim().isEmpty || w.hourlyRate < 0 || !workplaceIds.add(id)) {
        throw broken;
      }
      workplaces.add(w);
    }

    final tips = <Tip>[];
    final tipIds = <int>{};
    for (final e in data['tips'] as List) {
      final t = Tip.fromMap(Map<String, Object?>.from(e as Map));
      if (t.cash < 0 || t.card < 0 || t.tipOut < 0) throw broken;
      final sales = t.sales;
      if (sales != null && sales < 0) throw broken;
      final h = t.hours;
      if (h != null && (!h.isFinite || h <= 0 || h > 48)) throw broken;
      final id = t.id;
      if (id != null && !tipIds.add(id)) throw broken;
      final wid = t.workplaceId;
      tips.add(wid != null && !workplaceIds.contains(wid)
          ? Tip(
              id: t.id,
              workplaceId: null,
              date: t.date,
              cash: t.cash,
              card: t.card,
              tipOut: t.tipOut,
              hours: t.hours,
              note: t.note,
              sales: t.sales,
            )
          : t);
    }

    final shifts = <Shift>[];
    final shiftIds = <int>{};
    final usedTips = <int>{};
    for (final e in (data['shifts'] as List?) ?? const []) {
      final s = Shift.fromMap(Map<String, Object?>.from(e as Map));
      if (s.startMin < 0 || s.startMin > 1439 || s.endMin < 0 || s.endMin > 1439 || s.startMin == s.endMin) {
        throw broken;
      }
      final id = s.id;
      if (id != null && !shiftIds.add(id)) throw broken;
      final wid = s.workplaceId;
      final tid = s.tipId;
      final tipOk = tid != null && tipIds.contains(tid) && usedTips.add(tid);
      shifts.add(Shift(
        id: s.id,
        workplaceId: (wid != null && !workplaceIds.contains(wid)) ? null : wid,
        date: s.date,
        startMin: s.startMin,
        endMin: s.endMin,
        note: s.note,
        tipId: tipOk ? tid : null,
      ));
    }

    final goal = (data['goal'] as num?)?.toInt() ?? 0;
    if (goal < 0) throw broken;
    return BackupData(
      workplaces: workplaces,
      tips: tips,
      shifts: shifts,
      goal: goal,
      settings: _parseSettings(data['settings']),
    );
  } catch (_) {
    throw broken;
  }
}
