import 'package:intl/intl.dart';

final _dayFmt = DateFormat('yyyy-MM-dd');

class Workplace {
  final int? id;
  final String name;
  const Workplace({this.id, required this.name});

  Map<String, Object?> toMap() => {'id': id, 'name': name};
  factory Workplace.fromMap(Map<String, Object?> m) =>
      Workplace(id: m['id'] as int?, name: m['name'] as String);
}

/// Kwoty trzymamy w groszach (int), żeby uniknąć błędów zaokrągleń.
class Tip {
  final int? id;
  final int? workplaceId;
  final DateTime date; // sama data, lokalna północ
  final int cash;
  final int card;
  final int tipOut; // odliczenie, np. podział z barem/kuchnią
  final double? hours;
  final String note;

  const Tip({
    this.id,
    this.workplaceId,
    required this.date,
    this.cash = 0,
    this.card = 0,
    this.tipOut = 0,
    this.hours,
    this.note = '',
  });

  int get gross => cash + card;
  int get net => cash + card - tipOut;
  double? get perHour =>
      (hours != null && hours! > 0) ? net / hours! : null; // w groszach

  Tip asNew() => Tip(
        workplaceId: workplaceId,
        date: date,
        cash: cash,
        card: card,
        tipOut: tipOut,
        hours: hours,
        note: note,
      );

  Tip withId(int id) => Tip(
        id: id,
        workplaceId: workplaceId,
        date: date,
        cash: cash,
        card: card,
        tipOut: tipOut,
        hours: hours,
        note: note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'workplace_id': workplaceId,
        'date': _dayFmt.format(date),
        'cash': cash,
        'card': card,
        'tip_out': tipOut,
        'hours': hours,
        'note': note,
      };

  factory Tip.fromMap(Map<String, Object?> m) {
    final d = DateTime.parse(m['date'] as String);
    return Tip(
      id: m['id'] as int?,
      workplaceId: m['workplace_id'] as int?,
      date: DateTime(d.year, d.month, d.day),
      cash: (m['cash'] as num?)?.toInt() ?? 0,
      card: (m['card'] as num?)?.toInt() ?? 0,
      tipOut: (m['tip_out'] as num?)?.toInt() ?? 0,
      hours: (m['hours'] as num?)?.toDouble(),
      note: (m['note'] as String?) ?? '',
    );
  }
}

/// Zaplanowana zmiana w grafiku. Godziny to minuty od północy dnia rozpoczęcia [date];
/// gdy [endMin] <= [startMin], zmiana kończy się następnego dnia (np. 22:00–06:00).
/// [tipId] wskazuje wpis napiwków utworzony z tej zmiany.
class Shift {
  final int? id;
  final int? workplaceId;
  final DateTime date; // sama data, lokalna północ
  final int startMin;
  final int endMin;
  final String note;
  final int? tipId;

  const Shift({
    this.id,
    this.workplaceId,
    required this.date,
    required this.startMin,
    required this.endMin,
    this.note = '',
    this.tipId,
  });

  int get durationMin => endMin > startMin ? endMin - startMin : 1440 - startMin + endMin;

  /// Godziny zaokrąglone do 2 miejsc (7 h 20 min = 7,33), gotowe do pola godzin we wpisie.
  double get hours => (durationMin / 60 * 100).round() / 100;

  bool get overnight => endMin <= startMin;

  bool get isDone => tipId != null;

  DateTime get start => DateTime(date.year, date.month, date.day, 0, startMin);

  DateTime get end => DateTime(date.year, date.month, date.day, 0, startMin + durationMin);

  bool hasEnded(DateTime now) => !end.isAfter(now);

  Shift withId(int id) => Shift(
        id: id,
        workplaceId: workplaceId,
        date: date,
        startMin: startMin,
        endMin: endMin,
        note: note,
        tipId: tipId,
      );

  Shift withTip(int? tipId) => Shift(
        id: id,
        workplaceId: workplaceId,
        date: date,
        startMin: startMin,
        endMin: endMin,
        note: note,
        tipId: tipId,
      );

  Shift asNew() => Shift(
        workplaceId: workplaceId,
        date: date,
        startMin: startMin,
        endMin: endMin,
        note: note,
        tipId: tipId,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'workplace_id': workplaceId,
        'date': _dayFmt.format(date),
        'start_min': startMin,
        'end_min': endMin,
        'note': note,
        'tip_id': tipId,
      };

  factory Shift.fromMap(Map<String, Object?> m) {
    final d = DateTime.parse(m['date'] as String);
    return Shift(
      id: m['id'] as int?,
      workplaceId: m['workplace_id'] as int?,
      date: DateTime(d.year, d.month, d.day),
      startMin: (m['start_min'] as num).toInt(),
      endMin: (m['end_min'] as num).toInt(),
      note: (m['note'] as String?) ?? '',
      tipId: m['tip_id'] as int?,
    );
  }
}
