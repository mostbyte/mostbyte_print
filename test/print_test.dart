import 'package:flutter_test/flutter_test.dart';
import 'package:mostbyte_print/enums/connection_type.dart';
import 'package:mostbyte_print/print.dart';

void main() {
  // =========================================================================
  // MostbytePrint constructor
  // =========================================================================
  group('MostbytePrint constructor', () {
    test('can be instantiated with required parameters', () {
      final print = MostbytePrint(ip: '192.168.1.100', name: 'Test Printer');

      expect(print.ip, '192.168.1.100');
      expect(print.name, 'Test Printer');
    });

    test('defaults connectionType to network', () {
      final print = MostbytePrint(ip: '10.0.0.1', name: 'Printer');

      expect(print.connectionType, ConnectionType.network);
    });

    test('accepts bluetooth connectionType', () {
      final print = MostbytePrint(
        ip: '10.0.0.1',
        name: 'BT Printer',
        connectionType: ConnectionType.bluetooth,
      );

      expect(print.connectionType, ConnectionType.bluetooth);
    });

    test('accepts usb connectionType', () {
      final print = MostbytePrint(
        ip: 'USB001',
        name: 'USB Printer',
        connectionType: ConnectionType.usb,
      );

      expect(print.connectionType, ConnectionType.usb);
    });

    test('profile defaults to null', () {
      final print = MostbytePrint(ip: '10.0.0.1', name: 'Printer');

      expect(print.profile, isNull);
    });
  });

  // =========================================================================
  // formattedNumber
  // =========================================================================
  group('MostbytePrint.formattedNumber', () {
    late MostbytePrint printer;

    setUp(() {
      printer = MostbytePrint(ip: '127.0.0.1', name: 'Test');
    });

    test('formats zero', () {
      expect(printer.formattedNumber(0), '0');
    });

    test('formats small number without separator', () {
      expect(printer.formattedNumber(100), '100');
    });

    test('formats 999 without separator', () {
      expect(printer.formattedNumber(999), '999');
    });

    test('formats 1000 with space separator', () {
      expect(printer.formattedNumber(1000), '1 000');
    });

    test('formats 10000 with space separator', () {
      expect(printer.formattedNumber(10000), '10 000');
    });

    test('formats 100000 with space separator', () {
      expect(printer.formattedNumber(100000), '100 000');
    });

    test('formats 1000000 with two space separators', () {
      expect(printer.formattedNumber(1000000), '1 000 000');
    });

    test('formats large number with multiple separators', () {
      expect(printer.formattedNumber(1234567890), '1 234 567 890');
    });

    test('truncates decimals (rounds to integer format)', () {
      // NumberFormat("#,##0") rounds/truncates to integer
      final result = printer.formattedNumber(1234.56);
      expect(result, '1 235'); // rounds to nearest integer
    });

    test('formats negative numbers', () {
      final result = printer.formattedNumber(-5000);
      expect(result, '-5 000');
    });

    test('formats negative large numbers', () {
      final result = printer.formattedNumber(-1234567);
      expect(result, '-1 234 567');
    });

    test('formats 0.5 rounds to 0 or 1', () {
      // NumberFormat("#,##0") will round 0.5
      final result = printer.formattedNumber(0.5);
      // Depending on rounding: "0" or "1"
      expect(result, anyOf('0', '1'));
    });

    test('formats very small decimal close to zero', () {
      final result = printer.formattedNumber(0.001);
      expect(result, '0');
    });

    test('formats 50000', () {
      expect(printer.formattedNumber(50000), '50 000');
    });

    test('formats 999999', () {
      expect(printer.formattedNumber(999999), '999 999');
    });
  });
}
