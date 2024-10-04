library print;

import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:mostbyte_print/esc_pos/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class MostbytePrint {
  PaperSize paperSize;
  String ip;
  String name;
  CapabilityProfile? profile;
  MostbytePrint(
      {required this.ip,
      required this.name,
      this.paperSize = PaperSize.mm80,
      this.profile});

  NumberFormat numberFormatter = NumberFormat("#,##0", "en_US");
  String formattedNumber(double number) {
    return numberFormatter.format(number).replaceAll(',', ' ');
  }

  Future<List<int>> testTicket() async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: const PosStyles(codeTable: 'CP1252'));
    bytes += generator.text('Special 2: blåbærgrød',
        styles: const PosStyles(codeTable: 'CP1252'));

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    bytes += generator.text('Align left',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded(
            'Автоматизациыфвал орфылдвар фылоравдл фырвая ресторанов'),
        width: 12,
        styles: const PosStyles(
            align: PosAlign.center,
            underline: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: '',
        width: 3,
        styles: const PosStyles(
            align: PosAlign.center, underline: true, height: PosTextSize.size1),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(
            align: PosAlign.center, underline: true, height: PosTextSize.size1),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    // bytes += generator.text('Text size 200%',
    //     styles: const PosStyles(
    //       height: PosTextSize.size2,
    //       width: PosTextSize.size2,
    //     ));

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    // bytes += generator.barcode(Barcode.code128(barData));

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> generateCheck(
      {required int orderId,
      required String employee,
      required String department,
      required String time,
      required List<String> orders}) async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.textEncoded(await getEncoded("Счет №: $orderId"),
        styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.reset();
    bytes += generator.textEncoded(await getEncoded("Сотрудник: $employee"));
    bytes += generator.textEncoded(await getEncoded("Отдел: $department"));
    bytes += generator.hr();
    for (String orderItem in orders) {
      bytes += generator.textEncoded(await getEncoded(orderItem),
          styles: const PosStyles(bold: true));
    }
    bytes += generator.hr();
    // bytes += generator.reset();
    bytes +=
        generator.text(time, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.beep();
    return bytes;
  }

  Future<List<int>> generateReciept(
      {required String companyName,
      String? comment,
      required int orderId,
      required String employee,
      required String time,
      required double allSum,
      required double cash,
      required double terminal,
      required double discount,
      required List<Map<String, dynamic>> orders}) async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.reset();
    bytes += generator.textEncoded(
        await getEncoded(
          companyName,
        ), //companyName
        styles: const PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size2,
            height: PosTextSize.size2,
            bold: true));
    bytes += generator.textEncoded(await getEncoded("Счет №: $orderId"),
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.reset();
    bytes += generator.textEncoded(await getEncoded("Распечатано: $time"),
        styles: const PosStyles(align: PosAlign.left)); //print
    bytes += generator
        .textEncoded(await getEncoded("ОТветственный: $employee")); // emopoyee
    bytes += generator
        .textEncoded(await getEncoded("Коммент: ${comment ?? ""}")); // comment
    bytes += generator.hr();
    for (Map<String, dynamic> orderItem in orders) {
      bytes += generator.row([
        PosColumn(
            textEncoded: await getEncoded(orderItem["name"]),
            width: 12,
            styles: const PosStyles(
              bold: true,
              underline: true,
            )),
      ]);
      bytes += generator.row([
        PosColumn(
          text: "",
          width: 4,
        ),
        PosColumn(
          text: "${orderItem["amount"]} * ${orderItem["price"]}",
          width: 4,
        ),
        PosColumn(
          text: "${formattedNumber(orderItem["amount"] * orderItem["price"])}",
          width: 4,
        )
      ]);
      // bytes += generator.textEncoded(await getEncoded(orderItem),
      //     styles: const PosStyles(bold: true));
    }
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Сумма заказа:"),
        width: 9,
      ),
      PosColumn(
        textEncoded: await getEncoded("${formattedNumber(allSum)}"),
        width: 3,
      )
    ]);
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Наличные:"),
        width: 9,
      ),
      PosColumn(
        textEncoded: await getEncoded("${formattedNumber(cash)}"),
        width: 3,
      )
    ]);
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Терминал:"),
        width: 9,
      ),
      PosColumn(
        textEncoded: await getEncoded("${formattedNumber(terminal)}"),
        width: 3,
      )
    ]);
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Скидка:"),
        width: 9,
      ),
      PosColumn(
        textEncoded: await getEncoded("${formattedNumber(discount)}"),
        width: 3,
      )
    ]);
    // bytes += generator.reset();
    bytes += generator.textEncoded(
        await getEncoded("Итого: ${formattedNumber(allSum - discount)}"),
        styles: const PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size2,
            height: PosTextSize.size2,
            bold: true));
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.beep();
    bytes += generator.reset();
    return bytes;
  }

  Future<void> printTicket(List<int> ticket) async {
    final printer = PrinterNetworkManager(ip);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing = await printer.printTicket(ticket);

      print(printing.msg);
      printer.disconnect();
    }
  }

  Future<Uint8List> getEncoded(String text) async {
    final encoded = await CharsetConverter.encode("CP866", text);
    return encoded;
  }
}
