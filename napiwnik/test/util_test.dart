import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/util.dart';

void main() {
  group('parseMoney', () {
    test('pusty tekst to zero', () {
      expect(parseMoney(''), 0);
      expect(parseMoney('   '), 0);
    });

    test('poprawne kwoty', () {
      expect(parseMoney('120,50'), 12050);
      expect(parseMoney('120.5'), 12050);
      expect(parseMoney('12,5'), 1250);
      expect(parseMoney('12,'), 1200);
      expect(parseMoney('7'), 700);
      expect(parseMoney(' 1 200 '), 120000);
      expect(parseMoney('0,05'), 5);
    });

    test('błędne kwoty to null', () {
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('-5'), isNull);
      expect(parseMoney('12,345'), isNull);
      expect(parseMoney('1,2,3'), isNull);
      expect(parseMoney(',5'), isNull);
      expect(parseMoney('Infinity'), isNull);
      expect(parseMoney('NaN'), isNull);
      expect(parseMoney('1e3'), isNull);
    });

    test('górny limit', () {
      expect(parseMoney('1000000'), maxMoneyGrosze);
      expect(parseMoney('1000000,01'), isNull);
      expect(parseMoney('10000000'), isNull);
      expect(parseMoney('99999999999'), isNull);
    });
  });

  group('parseHours', () {
    test('poprawne godziny', () {
      expect(parseHours('6,5'), 6.5);
      expect(parseHours('6.5'), 6.5);
      expect(parseHours('48'), 48.0);
    });

    test('brak lub błąd to null', () {
      expect(parseHours(''), isNull);
      expect(parseHours('0'), isNull);
      expect(parseHours('-1'), isNull);
      expect(parseHours('49'), isNull);
      expect(parseHours('NaN'), isNull);
      expect(parseHours('Infinity'), isNull);
      expect(parseHours('abc'), isNull);
    });
  });

  group('fmtHours', () {
    test('całkowite bez przecinka', () {
      expect(fmtHours(8.0), '8');
      expect(fmtHours(10.0), '10');
    });

    test('ułamki z przecinkiem, bez gubienia cyfr', () {
      expect(fmtHours(6.5), '6,5');
      expect(fmtHours(7.25), '7,25');
      expect(fmtHours(10.05), '10,05');
    });
  });

  group('fmtMoney / fmtInput', () {
    test('formatowanie kwot', () {
      expect(fmtMoney(12345), '123,45 zł');
      expect(fmtMoney(5), '0,05 zł');
      expect(fmtMoney(-5), '-0,05 zł');
    });

    test('fmtInput i parseMoney są odwrotne', () {
      for (final g in [1, 99, 100, 12050, 100000000]) {
        expect(parseMoney(fmtInput(g)), g);
      }
      expect(fmtInput(0), '');
    });
  });
}
