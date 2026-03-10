import 'package:flutter_test/flutter_test.dart';
import 'package:mostbyte_print/enums/connection_type.dart';

void main() {
  group('ConnectionType enum', () {
    test('has exactly three values', () {
      expect(ConnectionType.values.length, 3);
    });

    test('contains network value', () {
      expect(ConnectionType.values, contains(ConnectionType.network));
    });

    test('contains bluetooth value', () {
      expect(ConnectionType.values, contains(ConnectionType.bluetooth));
    });

    test('contains usb value', () {
      expect(ConnectionType.values, contains(ConnectionType.usb));
    });
  });

  group('connectionTypeFromString', () {
    test('parses "network" correctly', () {
      expect(connectionTypeFromString('network'), ConnectionType.network);
    });

    test('parses "bluetooth" correctly', () {
      expect(connectionTypeFromString('bluetooth'), ConnectionType.bluetooth);
    });

    test('parses "usb" correctly', () {
      expect(connectionTypeFromString('usb'), ConnectionType.usb);
    });

    test('parses case-insensitively - uppercase', () {
      expect(connectionTypeFromString('NETWORK'), ConnectionType.network);
    });

    test('parses case-insensitively - mixed case', () {
      expect(connectionTypeFromString('Bluetooth'), ConnectionType.bluetooth);
    });

    test('parses case-insensitively - mixed case USB', () {
      expect(connectionTypeFromString('Usb'), ConnectionType.usb);
    });

    test('throws Exception on invalid input', () {
      expect(
        () => connectionTypeFromString('wifi'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception on empty string', () {
      expect(
        () => connectionTypeFromString(''),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception with descriptive message', () {
      expect(
        () => connectionTypeFromString('invalid'),
        throwsA(
          predicate((e) =>
              e is Exception && e.toString().contains('Unknown status')),
        ),
      );
    });
  });

  group('toStringConnectionType', () {
    test('converts network to "network"', () {
      expect(toStringConnectionType(ConnectionType.network), 'network');
    });

    test('converts bluetooth to "bluetooth"', () {
      expect(toStringConnectionType(ConnectionType.bluetooth), 'bluetooth');
    });

    test('converts usb to "usb"', () {
      expect(toStringConnectionType(ConnectionType.usb), 'usb');
    });
  });

  group('round-trip conversion', () {
    test('network survives round-trip', () {
      final str = toStringConnectionType(ConnectionType.network);
      expect(connectionTypeFromString(str), ConnectionType.network);
    });

    test('bluetooth survives round-trip', () {
      final str = toStringConnectionType(ConnectionType.bluetooth);
      expect(connectionTypeFromString(str), ConnectionType.bluetooth);
    });

    test('usb survives round-trip', () {
      final str = toStringConnectionType(ConnectionType.usb);
      expect(connectionTypeFromString(str), ConnectionType.usb);
    });
  });
}
