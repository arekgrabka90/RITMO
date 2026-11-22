import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup.dart';
import 'dates.dart';
import 'db.dart';
import 'models.dart';

final store = Store();

class Store extends ChangeNotifier {
  List<Workplace> workplaces = [];
  List<Tip> tips = [];
  int? filterId; // null = wszystkie miejsca
  int goal = 0; // cel miesięczny w groszach, 0 = brak
  ThemeMode themeMode = ThemeMode.system;

  /// Wybrany miesiąc (pierwszy dzień) wspólny dla Dziennika i Statystyk. Nigdy w przyszłości.
  DateTime month = monthStart(DateTime.now());
  bool _followNow = true; // dopóki użytkownik nie wybierze innego miesiąca, śledzimy bieżący

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

  void setMonth(DateTime m) {
    final current = monthStart(DateTime.now());
    var v = monthStart(m);
    if (v.isAfter(current)) v = current;
    month = v;
    _followNow = v == current;
    notifyListeners();
  }

  /// Wywoływane po powrocie do aplikacji: przelicza „dzisiaj”, a jeśli użytkownik jest
  /// na bieżącym miesiącu, to przechodzi za nim na nowy.
  void refreshClock() {
    if (_followNow) month = monthStart(DateTime.now());
    notifyListeners();
  }

  Future<void> load() async {
    final db = await AppDb.instance;
    workplaces = (await db.query('workplaces', orderBy: 'name COLLATE NOCASE'))
        .map(Workplace.fromMap)
        .toList();
    await _reloadTips();
    final prefs = await SharedPreferences.getInstance();
    goal = prefs.getInt('goal') ?? 0;
    final theme = prefs.getInt('theme') ?? 0;
    themeMode = (theme >= 0 && theme < ThemeMode.values.length)
        ? ThemeMode.values[theme]
        : ThemeMode.system;
    notifyListeners();
  }

  Future<void> _reloadTips() async {
    final db = await AppDb.instance;
    tips = (await db.query('tips')).map(Tip.fromMap).toList();
    _sort();
  }

  void _sort() {
    tips.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : (b.id ?? 0).compareTo(a.id ?? 0);
    });
  }

  // ---- wpisy ----
  // Zapis do bazy idzie PRZED zmianą w pamięci i błąd jest rzucany do wywołującego,
  // więc ekran może go pokazać zamiast zamykać się po cichu.
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

  /// Wpis znika z listy od razu (Dismissible tego wymaga), a baza jest aktualizowana zaraz potem.
  /// Zwraca false, gdy usunięcie z bazy się nie udało; wtedy lista jest odczytywana z bazy na nowo.
  Future<bool> deleteTip(Tip t) async {
    tips.removeWhere((x) => x.id == t.id);
    notifyListeners();
    try {
      final db = await AppDb.instance;
      await db.delete('tips', where: 'id = ?', whereArgs: [t.id]);
      return true;
    } catch (_) {
      try {
        await _reloadTips();
      } catch (_) {}
      notifyListeners();
      return false;
    }
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
    await _reloadTips();
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
  String backupJson() => encodeBackup(workplaces: workplaces, tips: tips, goal: goal);

  /// Zastępuje całą bazę zawartością kopii. Plik jest w całości sprawdzany ZANIM cokolwiek zostanie
  /// usunięte, a zapis do bazy to jedna transakcja (przy błędzie stare dane zostają).
  /// Rzuca FormatException przy złym pliku.
  Future<void> restore(String json) async {
    final backup = parseBackup(json);
    final db = await AppDb.instance;
    await db.transaction((txn) async {
      await txn.delete('tips');
      await txn.delete('workplaces');
      for (final w in backup.workplaces) {
        await txn.insert('workplaces', w.toMap());
      }
      for (final t in backup.tips) {
        await txn.insert('tips', t.toMap());
      }
    });
    await setGoal(backup.goal);
    filterId = null;
    await load();
  }
}
