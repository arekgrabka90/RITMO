import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db.dart';
import 'models.dart';

final store = Store();

class Store extends ChangeNotifier {
  List<Workplace> workplaces = [];
  List<Tip> tips = [];
  int? filterId; // null = wszystkie miejsca
  int goal = 0; // cel miesięczny w groszach, 0 = brak
  ThemeMode themeMode = ThemeMode.system;

  List<Tip> get visible => filterId == null
      ? tips
      : tips.where((t) => t.workplaceId == filterId).toList();

  String workplaceName(int? id) {
    if (id == null) return 'Bez miejsca';
    for (final w in workplaces) {
      if (w.id == id) return w.name;
    }
    return 'Bez miejsca';
  }

  Future<void> load() async {
    final db = await AppDb.instance;
    workplaces = (await db.query('workplaces', orderBy: 'name COLLATE NOCASE'))
        .map(Workplace.fromMap)
        .toList();
    tips = (await db.query('tips')).map(Tip.fromMap).toList();
    _sort();
    final prefs = await SharedPreferences.getInstance();
    goal = prefs.getInt('goal') ?? 0;
    themeMode = ThemeMode.values[prefs.getInt('theme') ?? 0];
    notifyListeners();
  }

  void _sort() {
    tips.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : (b.id ?? 0).compareTo(a.id ?? 0);
    });
  }

  // ---- wpisy ----
  Future<void> addTip(Tip t) async {
    final db = await AppDb.instance;
    final id = await db.insert('tips', t.toMap()..remove('id'));
    tips.add(t.withId(id));
    _sort();
    notifyListeners();
  }

  Future<void> updateTip(Tip t) async {
    final db = await AppDb.instance;
    await db.update('tips', t.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [t.id]);
    final i = tips.indexWhere((x) => x.id == t.id);
    if (i >= 0) tips[i] = t;
    _sort();
    notifyListeners();
  }

  Future<void> deleteTip(Tip t) async {
    tips.removeWhere((x) => x.id == t.id);
    notifyListeners();
    final db = await AppDb.instance;
    await db.delete('tips', where: 'id = ?', whereArgs: [t.id]);
  }

  // ---- miejsca pracy ----
  Future<void> addWorkplace(String name) async {
    final db = await AppDb.instance;
    await db.insert('workplaces', {'name': name});
    await _reloadWorkplaces();
  }

  Future<void> renameWorkplace(int id, String name) async {
    final db = await AppDb.instance;
    await db.update('workplaces', {'name': name},
        where: 'id = ?', whereArgs: [id]);
    await _reloadWorkplaces();
  }

  /// Wpisy zostają, tylko tracą przypisanie do miejsca.
  Future<void> deleteWorkplace(int id) async {
    final db = await AppDb.instance;
    await db.delete('workplaces', where: 'id = ?', whereArgs: [id]);
    if (filterId == id) filterId = null;
    tips = (await db.query('tips')).map(Tip.fromMap).toList();
    _sort();
    await _reloadWorkplaces();
  }

  Future<void> _reloadWorkplaces() async {
    final db = await AppDb.instance;
    workplaces = (await db.query('workplaces', orderBy: 'name COLLATE NOCASE'))
        .map(Workplace.fromMap)
        .toList();
    notifyListeners();
  }

  void setFilter(int? id) {
    filterId = id;
    notifyListeners();
  }

  // ---- ustawienia ----
  Future<void> setGoal(int grosze) async {
    goal = grosze;
    (await SharedPreferences.getInstance()).setInt('goal', grosze);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    (await SharedPreferences.getInstance()).setInt('theme', m.index);
    notifyListeners();
  }

  // ---- kopia zapasowa ----
  String backupJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'napiwnik',
        'version': 1,
        'workplaces': workplaces.map((w) => w.toMap()).toList(),
        'tips': tips.map((t) => t.toMap()).toList(),
        'goal': goal,
      });

  /// Zastępuje całą bazę zawartością kopii. Rzuca FormatException przy złym pliku.
  Future<void> restore(String json) async {
    final data = jsonDecode(json);
    if (data is! Map || data['app'] != 'napiwnik' || data['version'] != 1) {
      throw const FormatException('To nie jest kopia zapasowa Napiwnika.');
    }
    final ws = (data['workplaces'] as List)
        .map((e) => Workplace.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    final ts = (data['tips'] as List)
        .map((e) => Tip.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    final db = await AppDb.instance;
    await db.transaction((txn) async {
      await txn.delete('tips');
      await txn.delete('workplaces');
      for (final w in ws) {
        await txn.insert('workplaces', w.toMap());
      }
      for (final t in ts) {
        await txn.insert('tips', t.toMap());
      }
    });
    await setGoal((data['goal'] as num?)?.toInt() ?? 0);
    filterId = null;
    await load();
  }
}
