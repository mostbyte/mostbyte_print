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
      required List<Map<String, dynamic>> orders}) async {
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
    for (Map<String, dynamic> orderItem in orders) {
      bytes += generator.row([
        PosColumn(
          textEncoded: await getEncoded("${orderItem["name"]}"),
          width: 9,
        ),
        PosColumn(
          text: "${orderItem["amount"]}",
          width: 3,
        )
      ]);
      // bytes += generator.textEncoded(await getEncoded(orderItem),
      //     styles: const PosStyles(bold: true));
    }
    bytes += generator.hr();
    bytes += generator.reset();
    bytes +=
        generator.text(time, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.beep();
    bytes += generator.reset();
    return bytes;
  }

  Future<List<int>> generateShift(
      {required int shiftId,
      required String employee,
      required String filial,
      required String createdAt,
      required String closedAt,
      required String time,
      required Map<String, dynamic> earned}) async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];

    // <p>ID смены: <b>${shift.id}</b></p>
    // <p>Филиал: <b>${globals.userData!.filial!.name_ru}</b></p>
    // <p>Начало: <b>${globals.dateDashTimeFormat(date: shift.openedAt, timezone: true)}</b></p>
    // <p>Конец: <b>${globals.dateDashTimeFormat(date: shift.closedAt!, timezone: true)}</b></p>
    // <p>Ответственный: <b>${shift.user.surname} ${shift.user.firstname}</b></p>
    // <hr>
    // <p class="total"> Сумма к сдаче</p>
    // <p>Терминал: <b>${globals.formattedNumber(double.parse(shift.earned!['closed']['terminal'].toString()))}</b></p>
    // <p>Наличка: <b>${globals.formattedNumber(double.parse((shift.earned!['closed']['sum'] - shift.earned!['closed']['terminal']).toString()))}</b></p>
    // <p>Скидки: <b>${globals.formattedNumber(double.parse(shift.earned!['discount'].toString()))}</b></p>
    // <p>Расходы: <b>${globals.formattedNumber(double.parse(shift.earned!['wasted'].toString()))}</b></p>
    // <p>Общая сумма: <b>${globals.formattedNumber(double.parse((shift.earned?['closed']['sum'] - shift.earned?['wasted'] - shift.earned?['discount']).toString()))}</b></p>
    // <hr>
    // <p class="total"> Сумма Остатка в кассе</p>
    // <p>Терминал: <b>${globals.formattedNumber(double.parse(shift.earned!['open']['terminal'].toString()))}</b></p>
    // <p>Наличка: <b>${globals.formattedNumber(double.parse((shift.earned?['open']['sum'] - shift.earned?['open']['terminal']).toString()))}</b></p>
    // <p>Общая сумма: <b>${globals.formattedNumber(double.parse(shift.earned!['open']['sum'].toString()))}</b></p>

    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.textEncoded(await getEncoded("ID смены: $shiftId"));
    bytes += generator.textEncoded(await getEncoded("Филиал: $filial"));
    bytes += generator.textEncoded(await getEncoded("Начало: $createdAt"));
    bytes += generator.textEncoded(await getEncoded("Конец: $closedAt"));
    bytes +=
        generator.textEncoded(await getEncoded("Ответственный: $employee"));
    bytes += generator.hr();

    bytes +=
        generator.textEncoded(await getEncoded("Сумма к сдаче"), linesAfter: 1);
    bytes += generator.textEncoded(await getEncoded(
        "Терминал: ${formattedNumber(double.parse(earned['closed']['terminal'].toString()))}"));
    bytes += generator.textEncoded(await getEncoded(
        "Наличка: ${formattedNumber(double.parse((earned['closed']['sum'] - earned['closed']['terminal']).toString()))}"));
    bytes += generator.textEncoded(await getEncoded(
        "Скидки: ${formattedNumber(double.parse(earned['discount'].toString()))}"));
    bytes += generator.textEncoded(await getEncoded(
        "Расходы: ${formattedNumber(double.parse(earned['wasted'].toString()))}}"));
    bytes += generator.textEncoded(await getEncoded(
        "Общая сумма: ${formattedNumber(double.parse((earned['closed']['sum'] - earned['wasted'] - earned['discount']).toString()))}"));

    bytes += generator.hr();

    bytes += generator.textEncoded(await getEncoded("Сумма Остатка в кассе"),
        linesAfter: 1);
    bytes += generator.textEncoded(await getEncoded(
        "Терминал: ${formattedNumber(double.parse(earned['open']['terminal'].toString()))}"));
    bytes += generator.textEncoded(await getEncoded(
        "Наличка: ${formattedNumber(double.parse((earned['open']['sum'] - earned['open']['terminal']).toString()))}"));
    bytes += generator.textEncoded(await getEncoded(
        "Общая сумма: ${formattedNumber(double.parse(earned['open']['sum'].toString()))}"));
    bytes += generator.hr();
    bytes += generator.text(time);
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
      required double percent,
      int? hours,
      int? minutes,
      double? tablePrice,
      String? tableName,
      String? createdAt,
      String? closedAt,
      required List<Map<String, dynamic>> orders}) async {
    double tableTotalPrice = tablePrice != null
        ? ((hours != null
                ? (hours + (minutes != null ? (minutes / 60) : 0))
                : 1) *
            tablePrice)
        : 0;
    tableTotalPrice =
        double.parse((tableTotalPrice / 100).toStringAsFixed(2)).round() * 100;
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.row([
      PosColumn(width: 1),
      PosColumn(
          textEncoded: await getEncoded(
            companyName,
          ), //companyName
          styles: const PosStyles(
              align: PosAlign.center,
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              bold: true),
          width: 11)
    ]);
    bytes += generator.row([
      PosColumn(width: 1),
      PosColumn(
        textEncoded: await getEncoded("Счет №: $orderId"),
        width: 11,
      )
    ]);
    bytes += generator.hr();
    bytes += generator.reset();
    bytes += generator.textEncoded(await getEncoded("Распечатано: $time"),
        styles: const PosStyles(align: PosAlign.left)); //print
    if (createdAt != null) {
      bytes += generator.textEncoded(await getEncoded("Начало: $createdAt"),
          styles: const PosStyles(align: PosAlign.left)); //print
    }
    if (closedAt != null) {
      bytes += generator.textEncoded(await getEncoded("Конец: $closedAt"),
          styles: const PosStyles(align: PosAlign.left)); //print
    }
    bytes += generator
        .textEncoded(await getEncoded("Ответственный: $employee")); // emopoyee
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
          text:
              "${orderItem["amount"]} * ${formattedNumber(orderItem["price"])}",
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

    if (tableName != null &&
        tablePrice != null &&
        (hours != null || minutes != null)) {
      bytes += generator.row([
        PosColumn(
            textEncoded: await getEncoded(tableName),
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
          text: "${hours ?? 1}:${minutes} * $formattedNumber(tablePrice)",
          width: 4,
        ),
        PosColumn(
          text: "${formattedNumber(tableTotalPrice)}",
          width: 4,
        )
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Обслуживание $percent%: "),
        width: 9,
      ),
      PosColumn(
        textEncoded: await getEncoded(
            "${formattedNumber(allSum * percent / (100 + percent))}"),
        width: 3,
      )
    ]);
    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Сумма заказа:"),
        width: 9,
      ),
      PosColumn(
        textEncoded:
            await getEncoded("${formattedNumber(allSum + tableTotalPrice)}"),
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
    bytes += generator.row([
      PosColumn(width: 1),
      PosColumn(
          textEncoded: await getEncoded(
              "Итого: ${formattedNumber(allSum - discount + tableTotalPrice)}"), //companyName
          styles: const PosStyles(
              align: PosAlign.center,
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              bold: true),
          width: 11)
    ]);

    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.beep();
    return bytes;
  }

  Future<bool> printTicket(List<int> ticket) async {
    final printer = PrinterNetworkManager(ip);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing = await printer.printTicket(ticket);

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
