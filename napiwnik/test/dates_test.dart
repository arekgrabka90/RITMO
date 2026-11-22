import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:napiwnik/dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl');
  });

  test('weekStart zwraca poniedziałek', () {
    expect(weekStart(DateTime(2026, 11, 25)), DateTime(2026, 11, 23)); // środa
    expect(weekStart(DateTime(2026, 11, 23)), DateTime(2026, 11, 23)); // poniedziałek
    expect(weekStart(DateTime(2026, 11, 22)), DateTime(2026, 11, 16)); // niedziela
  });

  test('addMonths i addDays przechodzą przez granicę roku', () {
    expect(addMonths(DateTime(2026, 11, 1), 2), DateTime(2027, 1, 1));
    expect(addMonths(DateTime(2026, 1, 1), -1), DateTime(2025, 12, 1));
    expect(addDays(DateTime(2026, 12, 30), 3), DateTime(2027, 1, 2));
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
  });

  test('daysInMonth', () {
    expect(daysInMonth(DateTime(2026, 2, 1)), 28);
    expect(daysInMonth(DateTime(2028, 2, 1)), 29);
    expect(daysInMonth(DateTime(2026, 11, 1)), 30);
    expect(daysInMonth(DateTime(2026, 12, 1)), 31);
  });

  test('sameDay, sameMonth, dateOnly, monthStart', () {
    expect(sameDay(DateTime(2026, 11, 21, 9), DateTime(2026, 11, 21, 23)), isTrue);
    expect(sameDay(DateTime(2026, 11, 21), DateTime(2026, 11, 22)), isFalse);
    expect(sameMonth(DateTime(2026, 11, 1), DateTime(2026, 11, 30)), isTrue);
    expect(sameMonth(DateTime(2026, 11, 1), DateTime(2025, 11, 1)), isFalse);
    expect(dateOnly(DateTime(2026, 11, 21, 18, 30)), DateTime(2026, 11, 21));
    expect(monthStart(DateTime(2026, 11, 21)), DateTime(2026, 11, 1));
  });

  test('tytuły miesiąca i tygodnia', () {
    expect(monthTitle(DateTime(2026, 11, 1)), 'Listopad 2026');
    expect(weekTitle(DateTime(2026, 11, 16)), '16–22 lis 2026');
    expect(weekTitle(DateTime(2026, 11, 30)), '30 lis – 6 gru 2026');
    expect(weekTitle(DateTime(2026, 12, 28)), '28 gru 2026 – 3 sty 2027');
  });
}
