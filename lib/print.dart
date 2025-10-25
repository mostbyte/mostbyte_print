library print;

import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:mostbyte_print/enums/connection_type.dart';
import 'package:mostbyte_print/esc_pos/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart';
import './usb_esc_printer_windows.dart' as usb_esc_printer_windows;

import './models/data_models/data_models.dart';

class MostbytePrint {
  ConnectionType connectionType;
  PaperSize paperSize;
  String ip;
  String name;
  CapabilityProfile? profile;

  MostbytePrint(
      {required this.ip,
      this.connectionType = ConnectionType.network,
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

  Future<List<int>> generateOrderCheck({
    required int orderNum,
    required String type,
    required String user,
    required String time,
    bool isSound = true,
  }) async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.row([
      PosColumn(width: 1),
      PosColumn(
          textEncoded: await getEncoded(
            "Ваш номер очереди",
          ), //companyName
          styles: const PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size1,
            bold: false,
            height: PosTextSize.size1,
          ),
          width: 11)
    ]);

    // bytes += generator.reset();
    bytes += generator.row([
      PosColumn(width: 1),
      PosColumn(
          textEncoded: await getEncoded("$orderNum"),
          styles: const PosStyles(
              align: PosAlign.center,
              width: PosTextSize.size5,
              height: PosTextSize.size5,
              bold: true),
          width: 11),
    ]);

    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Врач:  "),
        width: 1,
        styles: const PosStyles(
            align: PosAlign.left,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
            bold: false),
      ),
      PosColumn(
          textEncoded: await getEncoded("$user"),
          styles: const PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: false),
          width: 11),
    ]);

    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded("Тип услиги:  "),
        width: 1,
        styles: const PosStyles(
            align: PosAlign.left,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
            bold: false),
      ),
      PosColumn(
          textEncoded: await getEncoded(
              "${type == "slow" ? "Обычная процедура" : "Быстрая процедура"}"),
          styles: const PosStyles(
              align: PosAlign.left,
              width: PosTextSize.size1,
              height: PosTextSize.size1,
              bold: false),
          width: 11),
    ]);

    bytes += generator.hr();
    bytes += generator.textEncoded(
      await getEncoded("Время и дата выдачи"),
      styles: const PosStyles(
          align: PosAlign.center,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
          bold: false),
    );
    bytes += generator.textEncoded(
      await getEncoded(time),
      styles: const PosStyles(
          align: PosAlign.center,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
          bold: false),
    );
    bytes += generator.cut();
    if (isSound) {
      bytes += generator.beep();
    }
    bytes += generator.reset();
    return bytes;
  }

  Future<List<int>> generateCheck(
      {required int orderId,
      required String employee,
      required String department,
      required String time,
      required String currentTime,
      bool isSound = true,
      required List<Map<String, dynamic>> orders}) async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    bytes += generator.setGlobalCodeTable("CP866");
    bytes += generator.textEncoded(await getEncoded("Счет №: $orderId"),
        styles: const PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size1,
            height: PosTextSize.size1));
    // bytes += generator.reset();
    bytes += generator.textEncoded(await getEncoded("Сотрудник: $employee"));
    bytes += generator.textEncoded(await getEncoded("Отдел: $department"));
    bytes +=
        generator.textEncoded(await getEncoded("Распечатано: $currentTime"));
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
    if (isSound) {
      bytes += generator.beep();
    }
    bytes += generator.reset();
    return bytes;
  }

  Future<List<int>> generateShift({
    required Map<String, dynamic> shiftData,
    required String time,
    bool isSound = true,
  }) async {
    Shift shift = Shift.fromJson(shiftData);
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
    bytes += generator.textEncoded(await getEncoded("ID смены: ${shift.id}"));
    bytes += generator
        .textEncoded(await getEncoded("Филиал: ${shift.user.filial!.name_ru}"));
    bytes +=
        generator.textEncoded(await getEncoded("Начало: ${shift.openedAt}"));
    bytes +=
        generator.textEncoded(await getEncoded("Конец: ${shift.closedAt}"));
    bytes += generator.textEncoded(await getEncoded(
        "Ответственный: ${shift.user.surname} ${shift.user.firstname}"));
    bytes += generator.hr();

    bytes +=
        generator.textEncoded(await getEncoded("Сумма к сдаче"), linesAfter: 1);
    if (shift.earned != null) {
      bytes += generator.textEncoded(await getEncoded(
          "Терминал: ${formattedNumber(double.parse(shift.earned!.closed.terminal.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Перевод на карту: ${formattedNumber(double.parse(shift.earned!.closed.transferByCard.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Наличка: ${formattedNumber(double.parse((shift.earned!.closed.sum - shift.earned!.closed.terminal - shift.earned!.closed.transferByCard).toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Скидки: ${formattedNumber(double.parse(shift.earned!.discount.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Долги: ${formattedNumber(double.parse(shift.earned!.debt.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Расходы: ${formattedNumber(double.parse(shift.earned!.wasted.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Возвраты: ${formattedNumber(double.parse(shift.earned!.refund.sum.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Общая сумма: ${formattedNumber(double.parse((shift.earned!.closed.sum - shift.earned!.wasted - shift.earned!.discount - shift.earned!.debt).toString()))}"));

      bytes += generator.hr();

      bytes += generator.textEncoded(await getEncoded("Сумма Остатка в кассе"),
          linesAfter: 1);
      bytes += generator.textEncoded(await getEncoded(
          "Терминал: ${formattedNumber(double.parse(shift.earned!.open.terminal.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Перевод на карту: ${formattedNumber(double.parse(shift.earned!.open.transferByCard.toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Наличка: ${formattedNumber(double.parse((shift.earned!.open.sum - shift.earned!.open.terminal - shift.earned!.open.transferByCard).toString()))}"));
      bytes += generator.textEncoded(await getEncoded(
          "Общая сумма: ${formattedNumber(double.parse(shift.earned!.open.sum.toString()))}"));
    }
    bytes += generator.hr();
    bytes += generator.text(time);
    bytes += generator.feed(2);
    bytes += generator.cut();
    if (isSound) {
      bytes += generator.beep();
    }
    return bytes;
  }

  Future<List<int>> generateReciept(
      {required String companyName,
      String? comment,
      required int orderId,
      required int orderNum,
      required String employee,
      required String time,
      required double allSum,
      required double cash,
      required double terminal,
      required double transferByCard,
      required double discount,
      required double percent,
      required String orderType,
      bool isSound = true,
      Image? barcodeImg,
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
    // tableTotalPrice =
    //     double.parse((tableTotalPrice / 100).toStringAsFixed(2)).round() * 100;
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];
    int maxCharsPerLine = paperSize.value == PaperSize.mm58.value ? 32 : 40;

    // --- 1. Split the text into lines that fit printer width ---
    List<String> wrap(String s, int max) {
      final words = s.split(RegExp(r'\s+'));
      final lines = <String>[];
      var buf = '';
      for (final w in words) {
        if (buf.isEmpty) {
          buf = w;
        } else if ((buf.length + 1 + w.length) <= max) {
          buf = '$buf $w';
        } else {
          lines.add(buf);
          buf = w;
        }
      }
      if (buf.isNotEmpty) lines.add(buf);
      return lines;
    }

    String padCenter(String line, int width) {
      if (line.length >= width) return line;
      final left = ((width - line.length) / 2).floor();
      return ' ' * left + line; // pad with spaces on the left
    }

    String sanitize(String s) => s
        .replaceAll('\u00A0', ' ') // NBSP -> space
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '');

    final lines = wrap(companyName, maxCharsPerLine);

    bytes += generator.setGlobalCodeTable("CP866");
    for (final raw in lines) {
      final padded = padCenter(sanitize(raw), maxCharsPerLine);

      // Encode your text to CP866 or Windows-1251 (try CP866 first)
      List<int> encodedBytes = await CharsetConverter.encode('CP866', padded);

      // ✅ Convert to Uint8List before passing to textEncoded
      Uint8List encoded = Uint8List.fromList(encodedBytes);

      bytes.addAll(generator.textEncoded(
        encoded,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          width: PosTextSize.size1,
          height: PosTextSize.size2,
          // codeTable: PosCodeTable.pc866_cyrillic,
        ),
      ));
    }
    bytes += generator.row([
      PosColumn(width: 1),
      PosColumn(
        textEncoded: await getEncoded("Счет №: $orderNum"),
        width: 11,
      )
    ]);
    bytes += generator.hr();
    bytes += generator.reset();
    bytes += generator.textEncoded(await getEncoded("Тип счета: $orderType"),
        styles: const PosStyles(align: PosAlign.left)); //reciept type
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
    if (comment != null && comment.isNotEmpty) {
      bytes += generator
          .textEncoded(await getEncoded("Коммент: ${comment}")); // comment
    }
    bytes += generator.hr();
    for (Map<String, dynamic> orderItem in orders) {
      if (!orderItem["isVisible"]) continue;
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
          width: paperSize.value == PaperSize.mm58.value ? 1 : 4,
        ),
        PosColumn(
          text:
              "${orderItem["amount"]} * ${formattedNumber(double.parse(orderItem["price"].toString()))}",
          width: paperSize.value == PaperSize.mm58.value ? 6 : 4,
        ),
        PosColumn(
          text: "${formattedNumber(orderItem["amount"] * orderItem["price"])}",
          width: paperSize.value == PaperSize.mm58.value ? 5 : 4,
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
          width: paperSize.value == PaperSize.mm58.value ? 1 : 4,
        ),
        PosColumn(
          text: "${hours ?? 1}:${minutes} * ${formattedNumber(tablePrice)}",
          width: paperSize.value == PaperSize.mm58.value ? 6 : 4,
        ),
        PosColumn(
          text: "${formattedNumber(tableTotalPrice)}",
          width: paperSize.value == PaperSize.mm58.value ? 5 : 4,
        )
      ]);
    }

    bytes += generator.hr();
    if (percent > 0) {
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
    }
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
    if (terminal > 0) {
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
    }
    if (transferByCard > 0) {
      bytes += generator.row([
        PosColumn(
          textEncoded: await getEncoded("Перевод на карту:"),
          width: 9,
        ),
        PosColumn(
          textEncoded: await getEncoded("${formattedNumber(transferByCard)}"),
          width: 3,
        )
      ]);
    }
    if (discount > 0) {
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
    }
    // bytes += generator.reset();
    maxCharsPerLine = paperSize.value == PaperSize.mm58.value ? 17 : 25;
    final line = wrap(
        "Итого: ${formattedNumber(double.parse(((allSum - discount + tableTotalPrice) / 100).toStringAsFixed(2)).round() * 100)}",
        maxCharsPerLine);

    bytes += generator.setGlobalCodeTable("CP866");
    for (final raw in line) {
      final padded = padCenter(sanitize(raw), maxCharsPerLine);

      // Encode your text to CP866 or Windows-1251 (try CP866 first)
      List<int> encodedBytes = await CharsetConverter.encode('CP866', padded);

      // ✅ Convert to Uint8List before passing to textEncoded
      Uint8List encoded = Uint8List.fromList(encodedBytes);

      bytes.addAll(generator.textEncoded(
        encoded,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
          // codeTable: PosCodeTable.pc866_cyrillic,
        ),
      ));
    }
    // bytes += generator.row([
    //   PosColumn(
    //       textEncoded: await getEncoded(
    //           // "Итого: ${formattedNumber(allSum - discount + tableTotalPrice)}"), //companyName
    //           ), //companyName
    //       styles: const PosStyles(
    //           align: PosAlign.center,
    //           width: PosTextSize.size2,
    //           height: PosTextSize.size2,
    //           bold: true),
    //       width: 12)
    // ]);

    bytes += generator.feed(2);
    if (barcodeImg != null) {
      bytes += generator.imageRaster(barcodeImg, align: PosAlign.center);
    }
    // bytes += generator.barcode(
    //     width: 150,
    //     Barcode.code128("{B $orderId".split("")),
    //     height: 50,
    //     align: PosAlign.center);

    // bytes += generator.feed(2);
    bytes += generator.cut();
    if (isSound) {
      bytes += generator.beep();
    }
    bytes += generator.reset();
    return bytes;
  }

  Future<bool> printTicket(List<int> ticket) async {
    final stopwatch = Stopwatch()..start();
    if (connectionType == ConnectionType.usb) {
      await usb_esc_printer_windows.sendPrintRequest(ticket, ip);
      print('USB printing is not supported in this method yet.');
    } else if (connectionType == ConnectionType.network) {
      final printer = PrinterNetworkManager(ip);

      PosPrintResult connect =
          await printer.connect(timeout: Duration(seconds: 2));

      stopwatch.stop();
      print(
          'Время выполнения подключения с $ip :${stopwatch.elapsedMilliseconds} мс');
      stopwatch.start();
      if (connect == PosPrintResult.success) {
        PosPrintResult printing = await printer.printTicket(ticket);

        printer.disconnect();
        stopwatch.stop();
        print(
            'Время выполнения print $ip :${stopwatch.elapsedMilliseconds} мс');
        return printing.msg == "Success" ? true : false;
      }
    }
    stopwatch.stop();
    print('Время выполнения не print $ip :${stopwatch.elapsedMilliseconds} мс');
    return false;
  }

  Future<Uint8List> getEncoded(String text) async {
    final encoded = await CharsetConverter.encode("CP866", text);
    return encoded;
  }
}
