import 'package:flutter_test/flutter_test.dart';
import 'package:mostbyte_print/enums/bluetooth_printer_type.dart';
import 'package:mostbyte_print/enums/connection_type.dart';
import 'package:mostbyte_print/models/pos_printer.dart';
import 'package:mostbyte_print/models/bluetooth_printer.dart';
import 'package:mostbyte_print/models/network_printer.dart';
import 'package:mostbyte_print/models/usb_printer.dart';

void main() {
  // =========================================================================
  // POSPrinter
  // =========================================================================
  group('POSPrinter', () {
    test('default constructor has expected defaults', () {
      final printer = POSPrinter();

      expect(printer.id, isNull);
      expect(printer.name, isNull);
      expect(printer.address, isNull);
      expect(printer.deviceId, isNull);
      expect(printer.vendorId, isNull);
      expect(printer.productId, isNull);
      expect(printer.connected, isFalse);
      expect(printer.type, 0);
      expect(printer.connectionType, isNull);
    });

    test('constructor accepts all parameters', () {
      final printer = POSPrinter(
        id: 'printer-1',
        name: 'Office Printer',
        address: '192.168.1.100',
        deviceId: 1,
        vendorId: 0x04B8,
        productId: 0x0202,
        connected: true,
        type: 1,
        connectionType: ConnectionType.network,
      );

      expect(printer.id, 'printer-1');
      expect(printer.name, 'Office Printer');
      expect(printer.address, '192.168.1.100');
      expect(printer.deviceId, 1);
      expect(printer.vendorId, 0x04B8);
      expect(printer.productId, 0x0202);
      expect(printer.connected, isTrue);
      expect(printer.type, 1);
      expect(printer.connectionType, ConnectionType.network);
    });

    test('factory instance() creates printer with defaults', () {
      final printer = POSPrinter.instance();

      expect(printer.id, isNull);
      expect(printer.connected, isFalse);
      expect(printer.type, 0);
      expect(printer.connectionType, isNull);
    });
  });

  // =========================================================================
  // POSPrinter.bluetoothType computed property
  // =========================================================================
  group('POSPrinter.bluetoothType', () {
    test('type 0 maps to BluetoothPrinterType.unknown', () {
      final printer = POSPrinter(type: 0);
      expect(printer.bluetoothType, BluetoothPrinterType.unknown);
    });

    test('type 1 maps to BluetoothPrinterType.classic', () {
      final printer = POSPrinter(type: 1);
      expect(printer.bluetoothType, BluetoothPrinterType.classic);
    });

    test('type 2 maps to BluetoothPrinterType.le', () {
      final printer = POSPrinter(type: 2);
      expect(printer.bluetoothType, BluetoothPrinterType.le);
    });

    test('type 3 maps to BluetoothPrinterType.dual', () {
      final printer = POSPrinter(type: 3);
      expect(printer.bluetoothType, BluetoothPrinterType.dual);
    });

    test('type 99 (unrecognized) maps to BluetoothPrinterType.unknown', () {
      final printer = POSPrinter(type: 99);
      expect(printer.bluetoothType, BluetoothPrinterType.unknown);
    });

    test('negative type maps to BluetoothPrinterType.unknown', () {
      final printer = POSPrinter(type: -1);
      expect(printer.bluetoothType, BluetoothPrinterType.unknown);
    });
  });

  // =========================================================================
  // BluetoothPrinter
  // =========================================================================
  group('BluetoothPrinter', () {
    test('always sets connectionType to bluetooth', () {
      final printer = BluetoothPrinter();
      expect(printer.connectionType, ConnectionType.bluetooth);
    });

    test('connectionType is bluetooth even if network is passed', () {
      final printer = BluetoothPrinter(
        connectionType: ConnectionType.network,
      );
      // The constructor hard-codes ConnectionType.bluetooth
      expect(printer.connectionType, ConnectionType.bluetooth);
    });

    test('accepts all optional parameters', () {
      final printer = BluetoothPrinter(
        id: 'bt-001',
        name: 'BT Printer',
        address: 'AA:BB:CC:DD:EE:FF',
        connected: true,
        type: 1,
      );

      expect(printer.id, 'bt-001');
      expect(printer.name, 'BT Printer');
      expect(printer.address, 'AA:BB:CC:DD:EE:FF');
      expect(printer.connected, isTrue);
      expect(printer.type, 1);
      expect(printer.connectionType, ConnectionType.bluetooth);
    });

    test('is a subtype of POSPrinter', () {
      final printer = BluetoothPrinter();
      expect(printer, isA<POSPrinter>());
    });

    test('defaults connected to false', () {
      final printer = BluetoothPrinter();
      expect(printer.connected, isFalse);
    });

    test('bluetoothType works via inherited type field', () {
      final printer = BluetoothPrinter(type: 1);
      expect(printer.bluetoothType, BluetoothPrinterType.classic);
    });
  });

  // =========================================================================
  // NetWorkPrinter
  // =========================================================================
  group('NetWorkPrinter', () {
    test('always sets connectionType to network', () {
      final printer = NetWorkPrinter();
      expect(printer.connectionType, ConnectionType.network);
    });

    test('connectionType is network even if usb is passed', () {
      final printer = NetWorkPrinter(
        connectionType: ConnectionType.usb,
      );
      expect(printer.connectionType, ConnectionType.network);
    });

    test('accepts all optional parameters', () {
      final printer = NetWorkPrinter(
        id: 'net-001',
        name: 'Network Printer',
        address: '192.168.1.50',
        connected: true,
        type: 2,
      );

      expect(printer.id, 'net-001');
      expect(printer.name, 'Network Printer');
      expect(printer.address, '192.168.1.50');
      expect(printer.connected, isTrue);
      expect(printer.type, 2);
      expect(printer.connectionType, ConnectionType.network);
    });

    test('is a subtype of POSPrinter', () {
      final printer = NetWorkPrinter();
      expect(printer, isA<POSPrinter>());
    });

    test('defaults connected to false', () {
      final printer = NetWorkPrinter();
      expect(printer.connected, isFalse);
    });
  });

  // =========================================================================
  // USBPrinter
  // =========================================================================
  group('USBPrinter', () {
    test('always sets connectionType to usb', () {
      final printer = USBPrinter();
      expect(printer.connectionType, ConnectionType.usb);
    });

    test('connectionType is usb even if bluetooth is passed', () {
      final printer = USBPrinter(
        connectionType: ConnectionType.bluetooth,
      );
      expect(printer.connectionType, ConnectionType.usb);
    });

    test('accepts all optional parameters including USB-specific fields', () {
      final printer = USBPrinter(
        id: 'usb-001',
        name: 'USB Printer',
        address: '/dev/usb/lp0',
        deviceId: 5,
        vendorId: 0x04B8,
        productId: 0x0E15,
        connected: true,
        type: 3,
      );

      expect(printer.id, 'usb-001');
      expect(printer.name, 'USB Printer');
      expect(printer.address, '/dev/usb/lp0');
      expect(printer.deviceId, 5);
      expect(printer.vendorId, 0x04B8);
      expect(printer.productId, 0x0E15);
      expect(printer.connected, isTrue);
      expect(printer.type, 3);
      expect(printer.connectionType, ConnectionType.usb);
    });

    test('is a subtype of POSPrinter', () {
      final printer = USBPrinter();
      expect(printer, isA<POSPrinter>());
    });

    test('defaults connected to false', () {
      final printer = USBPrinter();
      expect(printer.connected, isFalse);
    });

    test('USB-specific fields default to null', () {
      final printer = USBPrinter();
      expect(printer.deviceId, isNull);
      expect(printer.vendorId, isNull);
      expect(printer.productId, isNull);
    });
  });

  // =========================================================================
  // BluetoothPrinterType enum
  // =========================================================================
  group('BluetoothPrinterType enum', () {
    test('has exactly four values', () {
      expect(BluetoothPrinterType.values.length, 4);
    });

    test('contains classic, dual, le, and unknown', () {
      expect(BluetoothPrinterType.values,
          contains(BluetoothPrinterType.classic));
      expect(
          BluetoothPrinterType.values, contains(BluetoothPrinterType.dual));
      expect(BluetoothPrinterType.values, contains(BluetoothPrinterType.le));
      expect(BluetoothPrinterType.values,
          contains(BluetoothPrinterType.unknown));
    });
  });
}
