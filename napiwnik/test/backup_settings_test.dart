import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/backup.dart';
import 'package:napiwnik/period.dart';

String _withSettings(Object? settings) => jsonEncode({
      'app': 'napiwnik',
      'version': 2,
      'workplaces': [],
      'tips': [],
      'shifts': [],
      'goal': 0,
      'settings': settings,
    });

void main() {
  test('ustawienia przechodzą przez kopię', () {
    final data = parseBackup(encodeBackup(
      workplaces: const [],
      tips: const [],
      goal: 0,
      settings: BackupSettings(
        weekStartDay: 7,
        periodType: PeriodType.biweekly,
        periodAnchor: DateTime(2026, 11, 2),
        payDay: 10,
      ),
    ));
    final s = data.settings!;
    expect(s.weekStartDay, 7);
    expect(s.periodType, PeriodType.biweekly);
    expect(s.periodAnchor, DateTime(2026, 11, 2));
    expect(s.payDay, 10);
  });

  test('brak wypłaty (0) jest poprawną wartością', () {
    final data = parseBackup(encodeBackup(
      workplaces: const [],
      tips: const [],
      goal: 0,
      settings: const BackupSettings(payDay: 0),
    ));
    expect(data.settings!.payDay, 0);
  });

  test('kopia bez ustawień wczytuje się, a ustawienia to null', () {
    final data = parseBackup(encodeBackup(workplaces: const [], tips: const [], goal: 0));
    expect(data.settings, isNull);
  });

  test('złe wartości ustawień są pomijane, nie psują kopii', () {
    final data = parseBackup(_withSettings({
      'week_start': 9,
      'period_type': 7,
      'period_anchor': 'jutro',
      'pay_day': 40,
    }));
    final s = data.settings!;
    expect(s.weekStartDay, isNull);
    expect(s.periodType, isNull);
    expect(s.periodAnchor, isNull);
    expect(s.payDay, isNull);
  });

  test('częściowo poprawne ustawienia: poprawne zostają', () {
    final data = parseBackup(_withSettings({
      'week_start': 3,
      'period_type': 'miesiąc',
      'pay_day': 15,
    }));
    final s = data.settings!;
    expect(s.weekStartDay, 3);
    expect(s.periodType, isNull);
    expect(s.payDay, 15);
  });

  test('ustawienia, które nie są obiektem, są ignorowane', () {
    expect(parseBackup(_withSettings('tekst')).settings, isNull);
    expect(parseBackup(_withSettings(5)).settings, isNull);
  });
}
