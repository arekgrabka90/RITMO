import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/util.dart';

void main() {
  group('fmtTime i fmtTimeRange', () {
    test('godziny z zerem z przodu', () {
      expect(fmtTime(0), '00:00');
      expect(fmtTime(65), '01:05');
      expect(fmtTime(16 * 60), '16:00');
      expect(fmtTime(1439), '23:59');
    });

    test('zmiana przez północ ma znacznik +1', () {
      expect(fmtTimeRange(960, 1320), '16:00–22:00');
      expect(fmtTimeRange(22 * 60, 6 * 60), '22:00–06:00 (+1)');
    });
  });

  group('fmtDuration i fmtHoursShort', () {
    test('czas pracy czytelnie', () {
      expect(fmtDuration(480), '8 h');
      expect(fmtDuration(450), '7 h 30 min');
      expect(fmtDuration(45), '45 min');
    });

    test('krótki zapis do kalendarza', () {
      expect(fmtHoursShort(480), '8h');
      expect(fmtHoursShort(450), '7,5h');
      expect(fmtHoursShort(440), '7,3h');
    });
  });

  test('fmtShiftCount: polska odmiana', () {
    expect(fmtShiftCount(0), '0 zmian');
    expect(fmtShiftCount(1), '1 zmiana');
    expect(fmtShiftCount(2), '2 zmiany');
    expect(fmtShiftCount(4), '4 zmiany');
    expect(fmtShiftCount(5), '5 zmian');
    expect(fmtShiftCount(12), '12 zmian');
    expect(fmtShiftCount(14), '14 zmian');
    expect(fmtShiftCount(22), '22 zmiany');
    expect(fmtShiftCount(112), '112 zmian');
  });
}
