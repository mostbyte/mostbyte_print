library print;

export 'package:mostbyte_print/enums/cyrillic_encoding.dart';

import 'dart:ffi';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:mostbyte_print/enums/connection_type.dart';
import 'package:mostbyte_print/enums/cyrillic_encoding.dart';
import 'package:mostbyte_print/esc_pos/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart';
import 'package:win32/win32.dart';
import './usb_esc_printer_windows.dart' as usb_esc_printer_windows;

import './models/data_models/data_models.dart';

class MostbytePrint {
  ConnectionType connectionType;
  PaperSize paperSize;
  String ip;
  String name;
  CapabilityProfile? profile;

  /// Кодировка для кириллицы.
  /// По умолчанию `auto` - автоматически определяется на основе имени принтера.
  /// Для RONGTA автоматически выбирается CP1251.
  CyrillicEncoding cyrillicEncoding;

  /// Кэшированная реальная кодировка (определённая из auto или заданная явно)
  CyrillicEncoding? _resolvedEncoding;

  MostbytePrint({
    required this.ip,
    this.connectionType = ConnectionType.network,
    required this.name,
    this.paperSize = PaperSize.mm80,
    this.profile,
    this.cyrillicEncoding = CyrillicEncoding.auto,
  });

  /// Возвращает реальную кодировку (разрешает auto в конкретное значение)
  CyrillicEncoding get resolvedEncoding {
    if (_resolvedEncoding != null) return _resolvedEncoding!;

    if (cyrillicEncoding == CyrillicEncoding.auto) {
      // Определяем на основе имени принтера и профиля
      _resolvedEncoding = detectBestEncoding(
        profile?.name ?? name,
        name,
      );
    } else {
      _resolvedEncoding = cyrillicEncoding;
    }

    return _resolvedEncoding!;
  }

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

  /// Тестовая печать кириллицы с разными code page для поиска правильной кодировки.
  /// Печатает "Привет Мир" с code page от [startPage] до [endPage].
  /// Используйте этот метод чтобы найти правильную кодировку для вашего принтера.
  Future<List<int>> testCyrillicCodePages({
    int startPage = 0,
    int endPage = 50,
  }) async {
    final profile1 = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile ?? profile1);
    List<int> bytes = [];

    final testText = "Привет Мир";

    bytes += generator.text('=== Cyrillic Code Page Test ===',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(1);

    // Тестируем CP866
    bytes += generator.text('CP866 encoding:');
    bytes += generator.setGlobalCodeTable('CP866');
    bytes += generator.textEncoded(
        await CharsetConverter.encode('CP866', testText));
    bytes += generator.emptyLines(1);

    // Тестируем CP1251
    bytes += generator.text('CP1251 encoding:');
    bytes += generator.setGlobalCodeTable('CP1251');
    bytes += generator.textEncoded(
        await CharsetConverter.encode('windows-1251', testText));
    bytes += generator.emptyLines(1);

    // Тестируем прямые code page номера с CP866 кодировкой
    bytes += generator.text('Direct code pages (CP866 encoded):');
    for (int page = startPage; page <= endPage; page++) {
      // Устанавливаем code page напрямую через ESC t n
      bytes += [0x1B, 0x74, page]; // ESC t n
      bytes += generator.text('Page $page: ');
      bytes += await CharsetConverter.encode('CP866', testText);
      bytes += generator.emptyLines(1);
    }

    // Тестируем прямые code page номера с CP1251 кодировкой
    bytes += generator.text('Direct code pages (CP1251 encoded):');
    for (int page = startPage; page <= endPage; page++) {
      // Устанавливаем code page напрямую через ESC t n
      bytes += [0x1B, 0x74, page]; // ESC t n
      bytes += generator.text('Page $page: ');
      bytes += await CharsetConverter.encode('windows-1251', testText);
      bytes += generator.emptyLines(1);
    }

    bytes += generator.feed(2);
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
    bytes += generator.setGlobalCodeTable(codeTableName);
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
    bytes += generator.setGlobalCodeTable(codeTableName);
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

  /// Format ISO date string to readable format
  String _formatShiftDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    } catch (e) {
      return isoDate;
    }
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

    bytes += generator.setGlobalCodeTable(codeTableName);

    // Header
    bytes += generator.textEncoded(await getEncoded("ID смены: ${shift.id}"));
    bytes += generator.textEncoded(
        await getEncoded("Филиал: ${shift.user?.filial?.name_ru ?? ''}"));
    bytes += generator.textEncoded(
        await getEncoded("Начало: ${_formatShiftDate(shift.openedAt)}"));
    bytes += generator.textEncoded(
        await getEncoded("Конец: ${_formatShiftDate(shift.closedAt)}"));
    bytes += generator.textEncoded(await getEncoded(
        "Ответственный: ${shift.user?.surname ?? ''} ${shift.user?.firstname ?? ''}"));
    bytes += generator.hr();

    if (shift.earned != null) {
      final earned = shift.earned!;

      // Closed orders section (Сумма к сдаче)
      bytes += generator.textEncoded(
          await getEncoded("СУММА К СДАЧЕ"), linesAfter: 1);
      bytes += generator.textEncoded(
          await getEncoded("Наличка: ${formattedNumber(earned.closed.sum)}"));
      bytes += generator.textEncoded(
          await getEncoded("Терминал: ${formattedNumber(earned.closed.terminal)}"));
      bytes += generator.textEncoded(
          await getEncoded("Перевод: ${formattedNumber(earned.closed.transferByCard)}"));

      final closedTotal = earned.closed.sum + earned.closed.terminal + earned.closed.transferByCard;
      bytes += generator.textEncoded(
          await getEncoded("Итого: ${formattedNumber(closedTotal)}"));
      bytes += generator.hr();

      // Deductions section
      bytes += generator.textEncoded(
          await getEncoded("ВЫЧЕТЫ"), linesAfter: 1);
      bytes += generator.textEncoded(
          await getEncoded("Скидки: ${formattedNumber(earned.discount)}"));
      bytes += generator.textEncoded(
          await getEncoded("Долги: ${formattedNumber(earned.debt)}"));
      bytes += generator.textEncoded(
          await getEncoded("Расходы: ${formattedNumber(earned.wasted)}"));
      bytes += generator.textEncoded(
          await getEncoded("Возвраты: ${formattedNumber(earned.refund.sum)}"));

      final deductionsTotal = earned.discount + earned.debt + earned.wasted + earned.refund.sum;
      bytes += generator.textEncoded(
          await getEncoded("Итого вычетов: ${formattedNumber(deductionsTotal)}"));
      bytes += generator.hr();

      // Open orders section (Остаток в кассе / Незакрытые)
      bytes += generator.textEncoded(
          await getEncoded("ОСТАТОК В КАССЕ"), linesAfter: 1);
      bytes += generator.textEncoded(
          await getEncoded("Наличка: ${formattedNumber(earned.open.sum)}"));
      bytes += generator.textEncoded(
          await getEncoded("Терминал: ${formattedNumber(earned.open.terminal)}"));
      bytes += generator.textEncoded(
          await getEncoded("Перевод: ${formattedNumber(earned.open.transferByCard)}"));

      final openTotal = earned.open.sum + earned.open.terminal + earned.open.transferByCard;
      bytes += generator.textEncoded(
          await getEncoded("Итого: ${formattedNumber(openTotal)}"));
      bytes += generator.hr();

      // Prepayment section
      if (earned.prepayment != null) {
        final prepay = earned.prepayment!;
        final prepayTotal = prepay.cash + prepay.terminal + prepay.transferByCard;
        if (prepayTotal > 0) {
          bytes += generator.textEncoded(
              await getEncoded("ПРЕДОПЛАТЫ"), linesAfter: 1);
          bytes += generator.textEncoded(
              await getEncoded("Наличка: ${formattedNumber(prepay.cash)}"));
          bytes += generator.textEncoded(
              await getEncoded("Терминал: ${formattedNumber(prepay.terminal)}"));
          bytes += generator.textEncoded(
              await getEncoded("Перевод: ${formattedNumber(prepay.transferByCard)}"));
          bytes += generator.textEncoded(
              await getEncoded("Итого: ${formattedNumber(prepayTotal)}"));
          bytes += generator.hr();
        }
      }

      // Current amount section (entered by cashier)
      if (earned.currentAmount != null) {
        final current = earned.currentAmount!;
        // sum is the total, cash = sum - terminal - transfer
        final currentCash = current.sum - current.terminal - current.transferByCard;
        bytes += generator.textEncoded(
            await getEncoded("ФАКТ. СУММА В КАССЕ"), linesAfter: 1);
        bytes += generator.textEncoded(
            await getEncoded("Наличка: ${formattedNumber(currentCash)}"));
        bytes += generator.textEncoded(
            await getEncoded("Терминал: ${formattedNumber(current.terminal)}"));
        bytes += generator.textEncoded(
            await getEncoded("Перевод: ${formattedNumber(current.transferByCard)}"));
        bytes += generator.textEncoded(
            await getEncoded("Итого: ${formattedNumber(current.sum)}"));
        bytes += generator.hr();
      }

      // Final totals
      final netTotal = closedTotal - deductionsTotal;
      bytes += generator.textEncoded(
          await getEncoded("ЧИСТАЯ ВЫРУЧКА: ${formattedNumber(netTotal)}"),
          linesAfter: 1);
    }

    bytes += generator.hr();
    bytes += generator.text(time);
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.drawer();
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

    bytes += generator.setGlobalCodeTable(codeTableName);
    for (final raw in lines) {
      final padded = padCenter(sanitize(raw), maxCharsPerLine);

      // Encode text using selected Cyrillic encoding
      List<int> encodedBytes =
          await CharsetConverter.encode(resolvedEncoding.charsetName, padded);

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

    bytes += generator.setGlobalCodeTable(codeTableName);
    for (final raw in line) {
      final padded = padCenter(sanitize(raw), maxCharsPerLine);

      // Encode text using selected Cyrillic encoding
      List<int> encodedBytes =
          await CharsetConverter.encode(resolvedEncoding.charsetName, padded);

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
    bytes += generator.drawer();
    if (isSound) {
      bytes += generator.beep();
    }
    bytes += generator.reset();
    return bytes;
  }

  void printRawData(String printerName, List<int> data) {
    final printerNamePtr = printerName.toNativeUtf16();
    final phPrinter = calloc<HANDLE>();

    // 1. Open printer
    final openResult = OpenPrinter(printerNamePtr, phPrinter, nullptr);
    if (openResult == 0) {
      print('Failed to open printer: ${GetLastError()}');
      calloc.free(printerNamePtr);
      calloc.free(phPrinter);
      return;
    }

    // 2. Start document
    final docInfo = calloc<DOC_INFO_1>()
      ..ref.pDocName = 'ESC/POS RAW Document'.toNativeUtf16()
      ..ref.pOutputFile = nullptr
      ..ref.pDatatype = 'RAW'.toNativeUtf16();

    if (StartDocPrinter(phPrinter.value, 1, docInfo) == 0) {
      print('Failed to start document: ${GetLastError()}');
      ClosePrinter(phPrinter.value);
      calloc.free(printerNamePtr);
      calloc.free(phPrinter);
      calloc.free(docInfo);
      return;
    }

    StartPagePrinter(phPrinter.value);

    // 3. Send RAW content
    final lpData = calloc<Uint8>(data.length);
    for (var i = 0; i < data.length; i++) {
      lpData[i] = data[i];
    }

    final bytesWritten = calloc<Uint32>();
    WritePrinter(phPrinter.value, lpData, data.length, bytesWritten);

    // 4. End print job
    EndPagePrinter(phPrinter.value);
    EndDocPrinter(phPrinter.value);
    ClosePrinter(phPrinter.value);

    // 5. Cleanup
    calloc.free(printerNamePtr);
    calloc.free(phPrinter);
    calloc.free(lpData);
    calloc.free(bytesWritten);
    calloc.free(docInfo);

    print('Print completed!');
  }

  Future<bool> printTicket(List<int> ticket) async {
    final stopwatch = Stopwatch()..start();
    if (connectionType == ConnectionType.usb) {
      try {
        final escReset = [0x1B, 0x40]; // ESC @ reset
        final cut = [0x1D, 0x56, 0x00];

        final data = [...escReset, ...ticket, ...cut];
        printRawData(ip, data);
        stopwatch.stop();
        print(
            'Время выполнения не print $ip :${stopwatch.elapsedMilliseconds} мс');
      } catch (e) {
        stopwatch.stop();
        print(
            'Время выполнения не print $ip :${stopwatch.elapsedMilliseconds} мс');
        print('Ошибка при печати по USB: $e');
      }
      return true;
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
    final encoded =
        await CharsetConverter.encode(resolvedEncoding.charsetName, text);
    return encoded;
  }

  /// Возвращает имя code table для ESC/POS команды setGlobalCodeTable
  String get codeTableName => resolvedEncoding.codeTableName;
}
