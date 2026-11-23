/// Procent do wyświetlenia: 11,2% albo 11% (jedno miejsce po przecinku, bez zbędnego „,0”).
String fmtPercent(double p) {
  final r = (p * 10).round() / 10;
  if (r == r.roundToDouble()) return '${r.round()}%';
  return '${r.toString().replaceAll('.', ',')}%';
}
