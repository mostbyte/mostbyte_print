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
    bytes +=
        generator.text('Test page', styles: const PosStyles(), linesAfter: 1);
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

  Future<bool> printTicket(List<int> ticket) async {
    final printer = PrinterNetworkManager(ip);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing = await printer.printTicket(ticket);

      print(printing.msg);
      printer.disconnect();
      return printing.msg == "Success" ? true : false;
    }
    return false;
  }

  Future<Uint8List> getEncoded(String text) async {
    final encoded = await CharsetConverter.encode("CP866", text);
    return encoded;
  }
}
