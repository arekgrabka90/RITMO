import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:napiwnik/buckets.dart';
import 'package:napiwnik/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl');
  });

  test('dailyBuckets: okno kończy się dzisiaj, wpisy spoza okna są pomijane', () {
    final today = DateTime(2026, 11, 21); // sobota
    final tips = [
      Tip(date: DateTime(2026, 11, 21), cash: 1000),
      Tip(date: DateTime(2026, 11, 15), cash: 500),
      Tip(date: DateTime(2026, 11, 14), cash: 9999), // poza oknem 7 dni
    ];
    final b = dailyBuckets(tips, today, 7, weekdayLabels: true);
    expect(b.length, 7);
    expect(b.first.label, 'Nd');
    expect(b.first.value, 5.0);
    expect(b.last.label, 'So');
    expect(b.last.value, 10.0);
    expect(b.map((x) => x.value).reduce((a, c) => a + c), 15.0);
  });

  test('dailyBuckets: kilka wpisów z tego samego dnia się sumuje, etykiety to numery dni', () {
    final today = DateTime(2026, 11, 21);
    final tips = [
      Tip(date: DateTime(2026, 11, 21), cash: 1000, tipOut: 200),
      Tip(date: DateTime(2026, 11, 21), card: 500),
    ];
    final b = dailyBuckets(tips, today, 30, weekdayLabels: false);
    expect(b.length, 30);
    expect(b.last.label, '21');
    expect(b.last.value, 13.0);
    expect(b.first.label, '23'); // 23 października
  });

  test('monthlyBuckets: przejście przez granicę roku', () {
    final today = DateTime(2026, 1, 15);
    final tips = [Tip(date: DateTime(2025, 12, 10), cash: 2000)];
    final b = monthlyBuckets(tips, today, 3);
    expect(b.map((x) => x.value).toList(), [0.0, 20.0, 0.0]);
  });

  test('monthlyBuckets sumuje miesiące', () {
    final today = DateTime(2026, 11, 21);
    final tips = [
      Tip(date: DateTime(2026, 10, 3), cash: 1000),
      Tip(date: DateTime(2026, 11, 1), cash: 200),
      Tip(date: DateTime(2026, 11, 20), card: 300),
    ];
    final b = monthlyBuckets(tips, today, 3);
    expect(b.map((x) => x.value).toList(), [0.0, 10.0, 5.0]);
  });

  test('monthsSpanned', () {
    final today = DateTime(2026, 11, 21);
    expect(monthsSpanned([], today), 1);
    expect(monthsSpanned([Tip(date: DateTime(2026, 11, 2), cash: 1)], today), 1);
    expect(monthsSpanned([Tip(date: DateTime(2024, 1, 5), cash: 1)], today), 35);
  });

  test('yearlyBuckets obejmuje wszystkie lata, także puste', () {
    final today = DateTime(2026, 11, 21);
    final tips = [
      Tip(date: DateTime(2023, 5, 1), cash: 1000),
      Tip(date: DateTime(2025, 2, 1), cash: 500),
      Tip(date: DateTime(2025, 3, 1), cash: 500),
    ];
    final b = yearlyBuckets(tips, today);
    expect(b.map((x) => x.label).toList(), ['2023', '2024', '2025', '2026']);
    expect(b.map((x) => x.value).toList(), [10.0, 0.0, 10.0, 0.0]);
  });
}
