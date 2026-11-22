import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/backup.dart';
import 'package:napiwnik/models.dart';

Map<String, Object?> _tip({int id = 1, int? wid = 1, int cash = 100, int card = 0, int out = 0, Object? hours}) => {
      'id': id,
      'workplace_id': wid,
      'date': '2026-11-20',
      'cash': cash,
      'card': card,
      'tip_out': out,
      'hours': hours,
      'note': '',
    };

Map<String, Object?> _shift({int id = 1, int? wid = 1, int start = 600, int end = 960, int? tipId}) => {
      'id': id,
      'workplace_id': wid,
      'date': '2026-11-20',
      'start_min': start,
      'end_min': end,
      'note': '',
      'tip_id': tipId,
    };

String _json({
  List<Object?>? workplaces,
  List<Object?>? tips,
  List<Object?>? shifts,
  Object? goal = 0,
  String app = 'napiwnik',
  int version = 2,
}) =>
    jsonEncode({
      'app': app,
      'version': version,
      'workplaces': workplaces ?? [{'id': 1, 'name': 'Bar'}],
      'tips': tips ?? [_tip()],
      'shifts': shifts ?? [],
      'goal': goal,
    });

void main() {
  test('zapis i odczyt kopii zachowują dane, z grafikiem', () {
    final ws = [const Workplace(id: 1, name: 'Bar'), const Workplace(id: 2, name: 'Kawiarnia')];
    final ts = [
      Tip(id: 1, workplaceId: 1, date: DateTime(2026, 11, 20), cash: 1000, card: 500, tipOut: 100, hours: 6.5, note: 'x'),
      Tip(id: 2, workplaceId: null, date: DateTime(2026, 11, 21), cash: 0, card: 0, hours: 4),
    ];
    final ss = [
      Shift(id: 1, workplaceId: 1, date: DateTime(2026, 11, 20), startMin: 600, endMin: 960, tipId: 1),
      Shift(id: 2, workplaceId: 2, date: DateTime(2026, 11, 28), startMin: 22 * 60, endMin: 6 * 60, note: 'wesele'),
    ];
    final data = parseBackup(encodeBackup(workplaces: ws, tips: ts, shifts: ss, goal: 300000));
    expect(data.workplaces.map((w) => w.name), ['Bar', 'Kawiarnia']);
    expect(data.tips.length, 2);
    expect(data.tips.first.hours, 6.5);
    expect(data.tips.first.note, 'x');
    expect(data.tips.last.workplaceId, isNull);
    expect(data.shifts.length, 2);
    expect(data.shifts.first.tipId, 1);
    expect(data.shifts.last.endMin, 360);
    expect(data.shifts.last.note, 'wesele');
    expect(data.goal, 300000);
  });

  test('stara kopia (wersja 1, bez grafiku) nadal się wczytuje', () {
    final old = jsonEncode({
      'app': 'napiwnik',
      'version': 1,
      'workplaces': [
        {'id': 1, 'name': 'Bar'}
      ],
      'tips': [_tip()],
      'goal': 5000,
    });
    final data = parseBackup(old);
    expect(data.tips.length, 1);
    expect(data.shifts, isEmpty);
    expect(data.goal, 5000);
  });

  test('obcy plik lub zła wersja to FormatException', () {
    expect(() => parseBackup('to nie jest json'), throwsFormatException);
    expect(() => parseBackup('[]'), throwsFormatException);
    expect(() => parseBackup(_json(app: 'inna')), throwsFormatException);
    expect(() => parseBackup(_json(version: 3)), throwsFormatException);
    expect(() => parseBackup(_json(version: 0)), throwsFormatException);
  });

  test('uszkodzone dane to FormatException', () {
    expect(() => parseBackup(jsonEncode({'app': 'napiwnik', 'version': 2})), throwsFormatException);
    expect(() => parseBackup(_json(tips: [_tip(cash: -1)])), throwsFormatException);
    expect(() => parseBackup(_json(tips: [_tip(hours: 100.0)])), throwsFormatException);
    expect(() => parseBackup(_json(tips: [_tip(id: 1), _tip(id: 1)])), throwsFormatException);
    expect(() => parseBackup(_json(goal: -5)), throwsFormatException);
    expect(
      () => parseBackup(_json(workplaces: [
        {'id': 1, 'name': 'A'},
        {'id': 1, 'name': 'B'},
      ])),
      throwsFormatException,
    );
    expect(() => parseBackup(_json(workplaces: [{'id': 1, 'name': '  '}])), throwsFormatException);
    expect(() => parseBackup(_json(tips: [
          {...(_tip()), 'date': 'wczoraj'}
        ])), throwsFormatException);
  });

  test('uszkodzone zmiany z grafiku to FormatException', () {
    expect(() => parseBackup(_json(shifts: [_shift(start: 600, end: 600)])), throwsFormatException);
    expect(() => parseBackup(_json(shifts: [_shift(start: 1440)])), throwsFormatException);
    expect(() => parseBackup(_json(shifts: [_shift(end: -1)])), throwsFormatException);
    expect(() => parseBackup(_json(shifts: [_shift(id: 1), _shift(id: 1)])), throwsFormatException);
    expect(
      () => parseBackup(_json(shifts: [
        {..._shift(), 'date': 'jutro'}
      ])),
      throwsFormatException,
    );
  });

  test('wpis z nieistniejącym miejscem traci przypisanie', () {
    final data = parseBackup(_json(tips: [_tip(wid: 99)]));
    expect(data.tips.single.workplaceId, isNull);
    expect(data.tips.single.cash, 100);
  });

  test('zmiana z nieistniejącym miejscem traci przypisanie, godziny zostają', () {
    final data = parseBackup(_json(shifts: [_shift(wid: 99)]));
    expect(data.shifts.single.workplaceId, isNull);
    expect(data.shifts.single.startMin, 600);
    expect(data.shifts.single.endMin, 960);
  });

  test('połączenie zmiany z wpisem: dobry link zostaje, zły i podwójny znikają', () {
    final data = parseBackup(_json(
      tips: [_tip(id: 1), _tip(id: 2)],
      shifts: [
        _shift(id: 1, tipId: 1),
        _shift(id: 2, tipId: 1), // ten sam wpis drugi raz
        _shift(id: 3, tipId: 77), // wpis nie istnieje
        _shift(id: 4, tipId: 2),
      ],
    ));
    expect(data.shifts.map((s) => s.tipId).toList(), [1, null, null, 2]);
  });
}
