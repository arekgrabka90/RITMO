import 'dart:convert';

import 'models.dart';

const backupApp = 'napiwnik';
const backupVersion = 2; // 1 = bez grafiku (nadal wczytywana), 2 = z grafikiem

class BackupData {
  final List<Workplace> workplaces;
  final List<Tip> tips;
  final List<Shift> shifts;
  final int goal;
  const BackupData({
    required this.workplaces,
    required this.tips,
    this.shifts = const [],
    required this.goal,
  });
}

String encodeBackup({
  required List<Workplace> workplaces,
  required List<Tip> tips,
  List<Shift> shifts = const [],
  required int goal,
}) =>
    const JsonEncoder.withIndent('  ').convert({
      'app': backupApp,
      'version': backupVersion,
      'workplaces': workplaces.map((w) => w.toMap()).toList(),
      'tips': tips.map((t) => t.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'goal': goal,
    });

/// Czyta i waliduje kopię zapasową BEZ dotykania bazy. Rzuca FormatException z komunikatem po polsku.
/// Wpis lub zmiana wskazujące na nieistniejące miejsce pracy zostają, ale tracą przypisanie.
/// Zmiana wskazująca na nieistniejący (albo już zajęty) wpis napiwków traci to połączenie.
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
      if (id == null || w.name.trim().isEmpty || !workplaceIds.add(id)) throw broken;
      workplaces.add(w);
    }

    final tips = <Tip>[];
    final tipIds = <int>{};
    for (final e in data['tips'] as List) {
      final t = Tip.fromMap(Map<String, Object?>.from(e as Map));
      if (t.cash < 0 || t.card < 0 || t.tipOut < 0) throw broken;
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
    return BackupData(workplaces: workplaces, tips: tips, shifts: shifts, goal: goal);
  } catch (_) {
    throw broken;
  }
}
