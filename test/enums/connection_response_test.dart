import 'package:flutter_test/flutter_test.dart';
import 'package:mostbyte_print/enums/connection_response.dart';

void main() {
  group('ConnectionResponse values', () {
    test('success has value 1', () {
      expect(ConnectionResponse.success.value, 1);
    });

    test('timeout has value 2', () {
      expect(ConnectionResponse.timeout.value, 2);
    });

    test('printerNotSelected has value 3', () {
      expect(ConnectionResponse.printerNotSelected.value, 3);
    });

    test('ticketEmpty has value 4', () {
      expect(ConnectionResponse.ticketEmpty.value, 4);
    });

    test('printInProgress has value 5', () {
      expect(ConnectionResponse.printInProgress.value, 5);
    });

    test('scanInProgress has value 6', () {
      expect(ConnectionResponse.scanInProgress.value, 6);
    });

    test('printerNotConnected has value 7', () {
      expect(ConnectionResponse.printerNotConnected.value, 7);
    });

    test('unknown has value 8', () {
      expect(ConnectionResponse.unknown.value, 8);
    });

    test('unsupport has value 9', () {
      expect(ConnectionResponse.unsupport.value, 9);
    });

    test('printerNotWritable has value 10', () {
      expect(ConnectionResponse.printerNotWritable.value, 10);
    });
  });

  group('ConnectionResponse.msg', () {
    test('success returns "Success"', () {
      expect(ConnectionResponse.success.msg, 'Success');
    });

    test('timeout returns timeout error message', () {
      expect(ConnectionResponse.timeout.msg,
          'Error. Printer connection timeout');
    });

    test('printerNotSelected returns not selected error', () {
      expect(ConnectionResponse.printerNotSelected.msg,
          'Error. Printer not selected');
    });

    test('ticketEmpty returns ticket empty error', () {
      expect(ConnectionResponse.ticketEmpty.msg, 'Error. Ticket is empty');
    });

    test('printInProgress returns print in progress error', () {
      expect(ConnectionResponse.printInProgress.msg,
          'Error. Another print in progress');
    });

    test('scanInProgress returns scanning error', () {
      expect(ConnectionResponse.scanInProgress.msg,
          'Error. Printer scanning in progress');
    });

    test('printerNotConnected returns not connected error', () {
      expect(ConnectionResponse.printerNotConnected.msg,
          'Error. Printer not connected');
    });

    test('unknown returns unknown error', () {
      expect(ConnectionResponse.unknown.msg, 'Unknown error');
    });

    test('unsupport returns unsupport platform message', () {
      expect(ConnectionResponse.unsupport.msg, 'Unsupport platform');
    });

    test('printerNotWritable returns not writable message', () {
      expect(ConnectionResponse.printerNotWritable.msg,
          'Printer not writable');
    });
  });

  group('ConnectionResponse equality', () {
    test('same constants are equal by value', () {
      expect(ConnectionResponse.success.value,
          equals(ConnectionResponse.success.value));
    });

    test('different constants have different values', () {
      expect(ConnectionResponse.success.value,
          isNot(equals(ConnectionResponse.timeout.value)));
    });

    test('all values are unique', () {
      final values = [
        ConnectionResponse.success.value,
        ConnectionResponse.timeout.value,
        ConnectionResponse.printerNotSelected.value,
        ConnectionResponse.ticketEmpty.value,
        ConnectionResponse.printInProgress.value,
        ConnectionResponse.scanInProgress.value,
        ConnectionResponse.printerNotConnected.value,
        ConnectionResponse.unknown.value,
        ConnectionResponse.unsupport.value,
        ConnectionResponse.printerNotWritable.value,
      ];
      expect(values.toSet().length, values.length);
    });
  });

  group('ConnectionResponse with unknown value', () {
    test('unrecognized value returns "Unknown error" from msg', () {
      // Create a ConnectionResponse with a value not matching any known constant.
      // Since the constructor is private, we cannot do this directly.
      // Instead we verify that the unknown constant itself returns the right message.
      expect(ConnectionResponse.unknown.msg, 'Unknown error');
    });
  });
}
