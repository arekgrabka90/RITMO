import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/models.dart';
import 'package:napiwnik/planning.dart';

Shift _s({int? id, required DateTime date, int start = 600, int end = 900, int? wid}) =>
    Shift(id: id, workplaceId: wid, date: date, startMin: start, endMin: end);

void main() {
  group('ShiftTemplate', () {
    test('poprawny szablon', () {
      final t = ShiftTemplate.tryParse({'name': ' Lunch ', 'start': 600, 'end': 960});
      expect(t, isNotNull);
      expect(t!.name, 'Lunch');
      expect(t.range.minutes, 360);
      expect(ShiftTemplate.tryParse(t.toMap())!.start, 600);
    });

    test('złe dane to null', () {
      expect(ShiftTemplate.tryParse(null), isNull);
      expect(ShiftTemplate.tryParse('x'), isNull);
      expect(ShiftTemplate.tryParse({'name': '', 'start': 600, 'end': 900}), isNull);
      expect(ShiftTemplate.tryParse({'name': 'A', 'start': 600, 'end': 600}), isNull);
      expect(ShiftTemplate.tryParse({'name': 'A', 'start': 1440, 'end': 100}), isNull);
      expect(ShiftTemplate.tryParse({'name': 'A', 'start': '10', 'end': 900}), isNull);
    });
  });

  group('shiftsOverlap', () {
    final day = DateTime(2026, 11, 21);
    test('nakładające się zmiany', () {
      expect(shiftsOverlap(_s(date: day, start: 600, end: 900), _s(date: day, start: 800, end: 1000)), isTrue);
    });

    test('zmiany jedna po drugiej nie nakładają się', () {
      expect(shiftsOverlap(_s(date: day, start: 600, end: 900), _s(date: day, start: 900, end: 1000)), isFalse);
    });

    test('zmiana przez północ nakłada się na poranek następnego dnia', () {
      final night = _s(date: day, start: 22 * 60, end: 6 * 60);
      final morning = _s(date: DateTime(2026, 11, 22), start: 5 * 60, end: 9 * 60);
      final later = _s(date: DateTime(2026, 11, 22), start: 6 * 60, end: 9 * 60);
      expect(shiftsOverlap(night, morning), isTrue);
      expect(shiftsOverlap(night, later), isFalse);
    });

    test('różne dni', () {
      expect(shiftsOverlap(_s(date: day), _s(date: DateTime(2026, 11, 22))), isFalse);
    });
  });

  group('copyWeekPlan', () {
    final monday = DateTime(2026, 11, 16);
    final tue = DateTime(2026, 11, 17);
    final fri = DateTime(2026, 11, 20);

    test('kopiuje zmiany o tydzień do przodu bez napiwków', () {
      final src = [
        Shift(id: 1, workplaceId: 2, date: tue, startMin: 600, endMin: 960, note: 'x', tipId: 7),
        _s(id: 2, date: fri, start: 1000, end: 1300),
        _s(id: 3, date: DateTime(2026, 11, 25)), // spoza kopiowanego tygodnia
      ];
      final p = copyWeekPlan(weekStartDate: monday, source: src, existing: src);
      expect(p.add.length, 2);
      expect(p.add.first.date, DateTime(2026, 11, 24));
      expect(p.add.first.workplaceId, 2);
      expect(p.add.first.note, 'x');
      expect(p.add.first.tipId, isNull);
      expect(p.add.last.date, DateTime(2026, 11, 27));
      expect(p.add.last.startMin, 1000);
      expect(p.skippedDays, 0);
      expect(p.replace, isEmpty);
    });

    test('pomija dni, które w następnym tygodniu mają już zmianę', () {
      final src = [_s(id: 1, date: tue), _s(id: 2, date: fri)];
      final existing = [...src, _s(id: 9, date: DateTime(2026, 11, 24))];
      final p = copyWeekPlan(weekStartDate: monday, source: src, existing: existing);
      expect(p.add.length, 1);
      expect(p.add.single.date, DateTime(2026, 11, 27));
      expect(p.skippedDays, 1);
    });

    test('pusty tydzień nic nie kopiuje', () {
      final p = copyWeekPlan(weekStartDate: monday, source: const [], existing: const []);
      expect(p.add, isEmpty);
    });
  });
}
