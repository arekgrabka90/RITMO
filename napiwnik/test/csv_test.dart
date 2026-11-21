import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/util.dart';

void main() {
  group('csvCell', () {
    test('zwykły tekst w cudzysłowie', () {
      expect(csvCell('Bar'), '"Bar"');
      expect(csvCell(''), '""');
    });

    test('cudzysłowy są podwajane', () {
      expect(csvCell('on powiedział "dzięki"'), '"on powiedział ""dzięki"""');
    });

    test('formuły dostają apostrof z przodu', () {
      expect(csvCell('=1+1'), '"\'=1+1"');
      expect(csvCell('+48 123'), '"\'+48 123"');
      expect(csvCell('-5'), '"\'-5"');
      expect(csvCell('@cmd'), '"\'@cmd"');
    });

    test('separator ; zostaje wewnątrz cudzysłowu', () {
      expect(csvCell('a;b'), '"a;b"');
    });
  });
}
