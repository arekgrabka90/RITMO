import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup.dart';
import 'dates.dart';
import 'db.dart';
import 'models.dart';
import 'period.dart';
import 'planning.dart';

final store = Store();

/// Wynik masowego dodania zmian: pozwala to cofnąć (usuwa dodane i przywraca zastąpione).
class BulkResult {
  final List<int> addedIds;
  final List<Shift> replaced;
  const BulkResult(this.addedIds, this.replaced);
}

class Store extends ChangeNotifier {
  List<Workplace> workplaces = [];
  List<Tip> tips = [];
  List<Shift> shifts = [];
  int? filterId; // null = wszystkie miejsca
  int goal = 0; // cel napiwków na okres rozliczeniowy w groszach, 0 = brak
  ThemeMode themeMode = ThemeMode.system;

  // ---- ustawienia okresu, tygodnia i wypłaty ----
  /// Dzień tygodnia, od którego zaczyna się tydzień w kalendarzach (1 = pn ... 7 = nd).
  int weekStartDay = DateTime.monday;
  PeriodType periodType = PeriodType.monthly;

  /// Pierwszy dzień jednego z okresów rozliczeniowych (dla okresów tygodniowych i dwutygodniowych).
  DateTime periodAnchor = weekStart(dateOnly(DateTime.now()));

  /// Dzień miesiąca, w którym przychodzi wypłata (1–31), 0 = nie ustawiono.
  int payDay = 0;

  /// Ostatnio użyte godziny zmiany: podpowiedź przy planowaniu.
  TimeRange lastRange = const TimeRange(960, 1320);

  /// Wybrany miesiąc (pierwszy dzień) wspólny dla Statystyk. Nigdy w przyszłości.
  DateTime month = monthStart(DateTime.now());
  bool _followNow = true; // dopóki użytkownik nie wybierze innego miesiąca, śledzimy bieżący

  List<Tip> get visible => filterId == null
      ? tips
      : tips.where((t) => t.workplaceId == filterId).toList();

  List<Shift> get visibleShifts => filterId == null
      ? shifts
      : shifts.where((s) => s.workplaceId == filterId).toList();

  List<Shift> shiftsOn(DateTime day) =>
      visibleShifts.where((s) => sameDay(s.date, day)).toList();

  Tip? tipById(int id) {
    for (final t in tips) {
      if (t.id == id) return t;
    }
    return null;
  }

  String workplaceName(int? id) {
    if (id == null) return 'Bez miejsca';
    for (final w in workplaces) {
      if (w.id == id) return w.name;
    }
    return 'Bez miejsca';
  }

  /// Stawki godzinowe miejsc pracy (id miejsca -> grosze za godzinę), tylko ustawione.
  Map<int, int> get rates => {
        for (final w in workplaces)
          if (w.id != null && w.hourlyRate > 0) w.id!: w.hourlyRate,
      };

  /// Bieżący okres rozliczeniowy według ustawień.
  BillingPeriod get currentPeriod => periodFor(DateTime.now(), periodType, periodAnchor);

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
    await _reloadShifts();
    final prefs = await SharedPreferences.getInstance();
    goal = prefs.getInt('goal') ?? 0;
    final theme = prefs.getInt('theme') ?? 0;
    themeMode = (theme >= 0 && theme < ThemeMode.values.length)
        ? ThemeMode.values[theme]
        : ThemeMode.system;
    final rs = prefs.getInt('range_start');
    final re = prefs.getInt('range_end');
    if (rs != null && re != null && TimeRange(rs, re).valid) lastRange = TimeRange(rs, re);

    final ws = prefs.getInt('week_start');
    weekStartDay = (ws != null && ws >= 1 && ws <= 7) ? ws : DateTime.monday;
    final pt = prefs.getInt('period_type');
    periodType = (pt != null && pt >= 0 && pt < PeriodType.values.length)
        ? PeriodType.values[pt]
        : PeriodType.monthly;
    final pa = DateTime.tryParse(prefs.getString('period_anchor') ?? '');
    if (pa != null) {
      periodAnchor = dateOnly(pa);
    } else {
      // Pierwsze uruchomienie: początek bieżącego tygodnia, zapisany na stałe.
      periodAnchor = weekStart(dateOnly(DateTime.now()), weekStartDay);
      await prefs.setString('period_anchor', dayKey(periodAnchor));
    }
    final pd = prefs.getInt('pay_day');
    payDay = (pd != null && pd >= 1 && pd <= 31) ? pd : 0;
    notifyListeners();
  }

  Future<void> _reloadTips() async {
    final db = await AppDb.instance;
    tips = (await db.query('tips')).map(Tip.fromMap).toList();
    _sort();
  }

  Future<void> _reloadShifts() async {
    final db = await AppDb.instance;
    shifts = (await db.query('shifts', orderBy: 'date, start_min')).map(Shift.fromMap).toList();
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

  /// Dodaje wpis napiwków i w tej samej transakcji łączy go ze zmianą z grafiku.
  Future<void> addTipForShift(Tip t, Shift s) async {
    final current = shifts.firstWhere((x) => x.id == s.id, orElse: () => s);
    if (current.tipId != null) throw StateError('Zmiana ma już wpis napiwków');
    final db = await AppDb.instance;
    late int id;
    await db.transaction((txn) async {
      id = await txn.insert('tips', t.toMap()..remove('id'));
      await txn.update('shifts', {'tip_id': id}, where: 'id = ?', whereArgs: [s.id]);
    });
    tips.add(t.withId(id));
    _sort();
    final i = shifts.indexWhere((x) => x.id == s.id);
    if (i >= 0) shifts[i] = shifts[i].withTip(id);
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
  /// Zmiana z grafiku, która była z nim połączona, wraca do stanu „bez napiwków” (baza robi to sama).
  /// Zwraca false, gdy usunięcie z bazy się nie udało; wtedy dane są odczytywane z bazy na nowo.
  Future<bool> deleteTip(Tip t) async {
    tips.removeWhere((x) => x.id == t.id);
    shifts = [for (final s in shifts) s.tipId == t.id ? s.withTip(null) : s];
    notifyListeners();
    try {
      final db = await AppDb.instance;
      await db.delete('tips', where: 'id = ?', whereArgs: [t.id]);
      return true;
    } catch (_) {
      try {
        await _reloadTips();
        await _reloadShifts();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  // ---- grafik ----
  Future<void> addShift(Shift s) async {
    final db = await AppDb.instance;
    await db.insert('shifts', s.toMap()..remove('id'));
    await _reloadShifts();
    notifyListeners();
  }

  Future<void> updateShift(Shift s) async {
    final db = await AppDb.instance;
    await db.update('shifts', s.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [s.id]);
    await _reloadShifts();
    notifyListeners();
  }

  /// Jak [deleteTip]: znika od razu, a przy błędzie bazy lista jest odczytywana na nowo i wynik to false.
  Future<bool> deleteShift(Shift s) async {
    shifts.removeWhere((x) => x.id == s.id);
    notifyListeners();
    try {
      final db = await AppDb.instance;
      await db.delete('shifts', where: 'id = ?', whereArgs: [s.id]);
      return true;
    } catch (_) {
      try {
        await _reloadShifts();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  /// Dodaje wiele zmian naraz (i usuwa zastępowane) w jednej transakcji.
  Future<BulkResult> applyBulk({required List<Shift> add, List<Shift> replace = const []}) async {
    final db = await AppDb.instance;
    final ids = <int>[];
    await db.transaction((txn) async {
      for (final s in replace) {
        await txn.delete('shifts', where: 'id = ?', whereArgs: [s.id]);
      }
      for (final s in add) {
        ids.add(await txn.insert('shifts', s.toMap()..remove('id')));
      }
    });
    await _reloadShifts();
    notifyListeners();
    return BulkResult(ids, replace);
  }

  Future<void> revertBulk(BulkResult r) async {
    final db = await AppDb.instance;
    await db.transaction((txn) async {
      for (final id in r.addedIds) {
        await txn.delete('shifts', where: 'id = ?', whereArgs: [id]);
      }
      for (final s in r.replaced) {
        await txn.insert('shifts', s.toMap()..remove('id'));
      }
    });
    await _reloadShifts();
    notifyListeners();
  }

  Future<void> setLastRange(TimeRange r) async {
    if (!r.valid) return;
    lastRange = r;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('range_start', r.start);
    await prefs.setInt('range_end', r.end);
  }

  // ---- miejsca pracy ----
  Future<void> addWorkplace(String name, {int rate = 0}) async {
    final db = await AppDb.instance;
    await db.insert('workplaces', {'name': name, 'hourly_rate': rate});
    await _reloadWorkplaces();
  }

  Future<void> updateWorkplace(int id, String name, int rate) async {
    final db = await AppDb.instance;
    await db.update('workplaces', {'name': name, 'hourly_rate': rate},
        where: 'id = ?', whereArgs: [id]);
    await _reloadWorkplaces();
  }

  /// Miejsce znika z listy od razu (Dismissible tego wymaga). Wpisy i zmiany zostają, tylko tracą
  /// przypisanie do miejsca. Przy błędzie bazy rzuca wyjątek (wołający odczytuje dane na nowo).
  Future<void> deleteWorkplace(int id) async {
    workplaces.removeWhere((w) => w.id == id);
    if (filterId == id) filterId = null;
    notifyListeners();
    final db = await AppDb.instance;
    await db.delete('workplaces', where: 'id = ?', whereArgs: [id]);
    await _reloadTips();
    await _reloadShifts();
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

  Future<void> setWeekStartDay(int day) async {
    if (day < 1 || day > 7) return;
    weekStartDay = day;
    (await SharedPreferences.getInstance()).setInt('week_start', day);
    notifyListeners();
  }

  Future<void> setPeriodType(PeriodType t) async {
    periodType = t;
    (await SharedPreferences.getInstance()).setInt('period_type', t.index);
    notifyListeners();
  }

  Future<void> setPeriodAnchor(DateTime d) async {
    periodAnchor = dateOnly(d);
    (await SharedPreferences.getInstance()).setString('period_anchor', dayKey(periodAnchor));
    notifyListeners();
  }

  /// [day] 1–31, 0 = bez wypłaty.
  Future<void> setPayDay(int day) async {
    if (day < 0 || day > 31) return;
    payDay = day;
    (await SharedPreferences.getInstance()).setInt('pay_day', day);
    notifyListeners();
  }

  // ---- kopia zapasowa ----
  String backupJson() =>
      encodeBackup(workplaces: workplaces, tips: tips, shifts: shifts, goal: goal);

  /// Zastępuje całą bazę zawartością kopii. Plik jest w całości sprawdzany ZANIM cokolwiek zostanie
  /// usunięte, a zapis do bazy to jedna transakcja (przy błędzie stare dane zostają).
  /// Rzuca FormatException przy złym pliku. Ustawienia okresu i wypłaty nie są w kopii.
  Future<void> restore(String json) async {
    final backup = parseBackup(json);
    final db = await AppDb.instance;
    await db.transaction((txn) async {
      await txn.delete('shifts');
      await txn.delete('tips');
      await txn.delete('workplaces');
      for (final w in backup.workplaces) {
        await txn.insert('workplaces', w.toMap());
      }
      for (final t in backup.tips) {
        await txn.insert('tips', t.toMap());
      }
      for (final s in backup.shifts) {
        await txn.insert('shifts', s.toMap());
      }
    });
    await setGoal(backup.goal);
    filterId = null;
    await load();
  }
}
