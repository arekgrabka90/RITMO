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

String _json({List<Object?>? workplaces, List<Object?>? tips, Object? goal = 0, String app = 'napiwnik', int version = 1}) =>
    jsonEncode({
      'app': app,
      'version': version,
      'workplaces': workplaces ?? [{'id': 1, 'name': 'Bar'}],
      'tips': tips ?? [_tip()],
      'goal': goal,
    });

void main() {
  test('zapis i odczyt kopii zachowują dane', () {
    final ws = [const Workplace(id: 1, name: 'Bar'), const Workplace(id: 2, name: 'Kawiarnia')];
    final ts = [
      Tip(id: 1, workplaceId: 1, date: DateTime(2026, 11, 20), cash: 1000, card: 500, tipOut: 100, hours: 6.5, note: 'x'),
      Tip(id: 2, workplaceId: null, date: DateTime(2026, 11, 21), cash: 0, card: 0, hours: 4),
    ];
    final data = parseBackup(encodeBackup(workplaces: ws, tips: ts, goal: 300000));
    expect(data.workplaces.map((w) => w.name), ['Bar', 'Kawiarnia']);
    expect(data.tips.length, 2);
    expect(data.tips.first.hours, 6.5);
    expect(data.tips.first.note, 'x');
    expect(data.tips.last.workplaceId, isNull);
    expect(data.goal, 300000);
  });

  test('obcy plik lub zła wersja to FormatException', () {
    expect(() => parseBackup('to nie jest json'), throwsFormatException);
    expect(() => parseBackup('[]'), throwsFormatException);
    expect(() => parseBackup(_json(app: 'inna')), throwsFormatException);
    expect(() => parseBackup(_json(version: 2)), throwsFormatException);
  });

  test('uszkodzone dane to FormatException', () {
    expect(() => parseBackup(jsonEncode({'app': 'napiwnik', 'version': 1})), throwsFormatException);
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

  test('wpis z nieistniejącym miejscem traci przypisanie', () {
    final data = parseBackup(_json(tips: [_tip(wid: 99)]));
    expect(data.tips.single.workplaceId, isNull);
    expect(data.tips.single.cash, 100);
  });
}
