import 'dart:convert';

import 'models.dart';

const backupApp = 'napiwnik';
const backupVersion = 1;

class BackupData {
  final List<Workplace> workplaces;
  final List<Tip> tips;
  final int goal;
  const BackupData({required this.workplaces, required this.tips, required this.goal});
}

String encodeBackup({
  required List<Workplace> workplaces,
  required List<Tip> tips,
  required int goal,
}) =>
    const JsonEncoder.withIndent('  ').convert({
      'app': backupApp,
      'version': backupVersion,
      'workplaces': workplaces.map((w) => w.toMap()).toList(),
      'tips': tips.map((t) => t.toMap()).toList(),
      'goal': goal,
    });

/// Czyta i waliduje kopię zapasową BEZ dotykania bazy. Rzuca FormatException z komunikatem po polsku.
/// Wpis wskazujący na nieistniejące miejsce pracy zostaje, ale traci przypisanie do miejsca.
BackupData parseBackup(String json) {
  const notBackup = FormatException('To nie jest kopia zapasowa Napiwnika.');
  const broken = FormatException('Plik kopii jest uszkodzony.');

  Object? data;
  try {
    data = jsonDecode(json);
  } catch (_) {
    throw notBackup;
  }
  if (data is! Map || data['app'] != backupApp || data['version'] != backupVersion) {
    throw notBackup;
  }

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

    final goal = (data['goal'] as num?)?.toInt() ?? 0;
    if (goal < 0) throw broken;
    return BackupData(workplaces: workplaces, tips: tips, goal: goal);
  } catch (_) {
    throw broken;
  }
}
