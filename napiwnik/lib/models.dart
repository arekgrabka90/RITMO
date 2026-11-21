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
