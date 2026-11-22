import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/backup.dart';
import 'package:napiwnik/models.dart';

String _withPlaces(List<Object?> places) => jsonEncode({
      'app': 'napiwnik',
      'version': 2,
      'workplaces': places,
      'tips': [],
      'shifts': [],
      'goal': 0,
    });

void main() {
  group('Workplace', () {
    test('toMap i fromMap zachowują stawkę', () {
      const w = Workplace(id: 2, name: 'Bar', hourlyRate: 3250);
      final back = Workplace.fromMap(w.toMap());
      expect(back.id, 2);
      expect(back.name, 'Bar');
      expect(back.hourlyRate, 3250);
    });

    test('brak stawki w danych to 0', () {
      final w = Workplace.fromMap({'id': 1, 'name': 'Bar'});
      expect(w.hourlyRate, 0);
    });
  });

  group('kopia zapasowa a stawki', () {
    test('stawka godzinowa przechodzi przez kopię', () {
      final data = parseBackup(encodeBackup(
        workplaces: const [Workplace(id: 1, name: 'Bar', hourlyRate: 3250), Workplace(id: 2, name: 'Kawiarnia')],
        tips: const [],
        goal: 0,
      ));
      expect(data.workplaces.first.hourlyRate, 3250);
      expect(data.workplaces.last.hourlyRate, 0);
    });

    test('starsza kopia bez stawek wczytuje się ze stawką 0', () {
      final data = parseBackup(_withPlaces([
        {'id': 1, 'name': 'Bar'}
      ]));
      expect(data.workplaces.single.hourlyRate, 0);
    });

    test('ujemna stawka to uszkodzony plik', () {
      expect(
        () => parseBackup(_withPlaces([
          {'id': 1, 'name': 'Bar', 'hourly_rate': -5}
        ])),
        throwsFormatException,
      );
    });
  });
}
