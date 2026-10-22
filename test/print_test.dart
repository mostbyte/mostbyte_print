import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mostbyte_print/enums/connection_type.dart';
import 'package:mostbyte_print/esc_pos/esc_pos_utils_plus.dart' show PaperSize;
import 'package:mostbyte_print/print.dart';

// ---------------------------------------------------------------------------
// Helper to build shift/calculate-income-подобный JSON для generateShift
// ---------------------------------------------------------------------------

Map<String, dynamic> _earnedDataJson({
  double sum = 0,
  double terminal = 0,
  double transferByCard = 0,
  double bankTransfer = 0,
}) =>
    {
      'sum': sum,
      'terminal': terminal,
      'transfer_by_card': transferByCard,
      'bank_transfer': bankTransfer,
    };

// Дефолт по умолчанию для carried_over (можно передать null - имитация
// старого бэка, у которого этого ключа в ответе ещё нет).
const _defaultCarriedOverJson = {
  'sum': 6241271.0,
  'terminal': 0.0,
  'transfer_by_card': 0.0,
  'bank_transfer': 0.0,
};

Map<String, dynamic> _buildShiftData({
  String openedAt = '2024-01-15T02:54:43.000000Z',
  String? closedAt = '2024-01-15T12:00:00.000000Z',
  Map<String, dynamic>? openJson,
  Map<String, dynamic>? refundJson,
  // null означает, что бэк ключ carried_over вообще не прислал (старая версия).
  Map<String, dynamic>? carriedOverJson = _defaultCarriedOverJson,
  // null: ключа closed_by_others нет (старая смена или старый бэк).
  Map<String, dynamic>? closedByOthersJson,
  // Ключи размена: null - нет ключа (старая смена или старый бэк).
  Map<String, dynamic>? openingCashJson,
  Map<String, dynamic>? cashBalanceJson,
  // null: ключа debt_repayment нет (старая смена или старый бэк).
  Map<String, dynamic>? debtRepaymentJson,
}) {
  final earned = <String, dynamic>{
    // Закрытые заказы - реально принятые деньги.
    'closed': _earnedDataJson(
        sum: 100000, terminal: 20000, transferByCard: 10000, bankTransfer: 5000),
    // Открыты в эту смену.
    'open': openJson ?? _earnedDataJson(sum: 30000),
    'refund': refundJson ?? _earnedDataJson(sum: 4000),
    'discount': 1000.0,
    'debt': 2000.0,
    'wasted': 3000.0,
  };
  if (closedByOthersJson != null) {
    earned['closed_by_others'] = closedByOthersJson;
  }
  if (openingCashJson != null) earned['opening_cash'] = openingCashJson;
  if (cashBalanceJson != null) earned['cash_balance'] = cashBalanceJson;
  if (debtRepaymentJson != null) earned['debt_repayment'] = debtRepaymentJson;
  if (carriedOverJson != null) {
    // Висят с прошлых смен.
    earned['carried_over'] = carriedOverJson;
  }

  return {
    'id': 7,
    'user': {
      'uuid': 'u-1',
      'firstName': 'Иван',
      'surname': 'Кассиров',
      'branch': {
        'id': 1,
        'nameUz': 'Markaziy',
        'nameRu': 'Центральный',
        'nameEng': 'Central'
      },
    },
    'opened_at': openedAt,
    'closed_at': closedAt,
    'earned': earned,
  };
}

void main() {
  // Печать использует CharsetConverter.encode (platform channel) для
  // кириллических строк - подменяем его identity-реализацией на utf8,
  // чтобы можно было прочитать текст чека обратно в тесте.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('charset_converter'),
            (MethodCall call) async {
      if (call.method == 'encode') {
        final data = (call.arguments as Map)['data'] as String;
        return Uint8List.fromList(utf8.encode(data));
      }
      return null;
    });
  });

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

  // =========================================================================
  // MostbytePrint.generateShift
  // =========================================================================
  group('MostbytePrint.generateShift', () {
    late MostbytePrint printer;

    setUp(() {
      printer = MostbytePrint(ip: '127.0.0.1', name: 'Test');
    });

    /// Декодирует байты чека обратно в текст (charset_converter замокан на utf8).
    String receiptText(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

    test('раздел незакрытых заказов подписан "НЕЗАКРЫТЫЕ ЗАКАЗЫ", а не "ОСТАТОК В КАССЕ"', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('НЕЗАКРЫТЫЕ ЗАКАЗЫ'));
      expect(text, isNot(contains('ОСТАТОК В КАССЕ')));
    });

    test('время начала и конца смены: формат строго dd.MM.yyyy HH:mm:ss, время локальное', () async {
      const rawOpened = '2024-01-15T02:54:43.000000Z';
      const rawClosed = '2024-01-15T12:00:00.000000Z';
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(openedAt: rawOpened, closedAt: rawClosed),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      // Сырые ISO-строки с 'T' и микросекундами на чеке быть не должно.
      expect(text, isNot(contains('2024-01-15T02:54:43')));
      expect(text, isNot(contains('2024-01-15T12:00:00')));

      // Формат зафиксирован явной регуляркой (не переиспользует формулу
      // прод-кода): если реализация откатится на HH:mm без секунд,
      // группа с секундами не совпадёт и матч будет null.
      final openedMatch = RegExp(r'Начало: (\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}:\d{2})')
          .firstMatch(text);
      final closedMatch = RegExp(r'Конец: (\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}:\d{2})')
          .firstMatch(text);
      expect(openedMatch, isNotNull,
          reason: 'строка "Начало:" должна быть в формате dd.MM.yyyy HH:mm:ss');
      expect(closedMatch, isNotNull,
          reason: 'строка "Конец:" должна быть в формате dd.MM.yyyy HH:mm:ss');

      // Ожидаемое значение считается через текущий офсет машины напрямую
      // (DateTime.add), а не через DateTime.toLocal() как в _formatShiftDate -
      // так тест не завязан на ту же формулу, что и прод-код. Проверка
      // безусловна (не спрятана за if по офсету): под TZ=UTC offset = 0,
      // и сравнение остаётся корректным и содержательным. Дат с переходом
      // на летнее время тут нет ни в Ташкенте, ни в UTC, так что офсет,
      // актуальный "сейчас", совпадает с офсетом на 2024-01-15.
      final offset = DateTime.now().timeZoneOffset;
      String expectedFor(String rawIso) {
        final shifted = DateTime.parse(rawIso).add(offset);
        return DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime(
            shifted.year,
            shifted.month,
            shifted.day,
            shifted.hour,
            shifted.minute,
            shifted.second));
      }

      expect(openedMatch!.group(1), expectedFor(rawOpened));
      expect(closedMatch!.group(1), expectedFor(rawClosed));
    });

    test('пустой closedAt не приводит к падению и не печатает null', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(closedAt: null),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('Конец: '));
      expect(text, isNot(contains('null')));
    });

    test('итог вычетов разделён на ушедшие из кассы деньги и недополученные суммы', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      // wasted(3000) + refund.sum(4000) = 7000 - реально изъятая наличность.
      expect(text, contains('Ушло из кассы: 7 000'));
      // discount(1000) + debt(2000) = 3000 - деньги, которые в кассу не заходили.
      expect(text, contains('Недополучено: 3 000'));
      // Старой совокупной строки вычетов быть не должно.
      expect(text, isNot(contains('Итого вычетов')));

      // ЧИСТАЯ ВЫРУЧКА = closed.sum(100000) - (7000 + 3000) = 90000.
      expect(text, contains('ЧИСТАЯ ВЫРУЧКА: 90 000'));
    });

    test('"Ушло из кассы" учитывает только наличную часть возврата, не весь refund.sum', () async {
      final bytes = await printer.generateShift(
        // Возврат 500000 целиком закрыт переводом на карту - из денежного
        // ящика физически ничего не изымалось.
        shiftData: _buildShiftData(
          refundJson: _earnedDataJson(sum: 500000, transferByCard: 500000),
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      // Наличная часть возврата = 500000 - 500000 = 0, значит "Ушло из
      // кассы" - это только wasted(3000), а не 503000.
      expect(text, contains('Ушло из кассы: 3 000'));
      // ЧИСТАЯ ВЫРУЧКА при этом по-прежнему уменьшается на весь возврат,
      // независимо от способа оплаты: 100000 - (1000+2000+3000+500000).
      expect(text, contains('ЧИСТАЯ ВЫРУЧКА: -406 000'));
    });

    test('блок незакрытых заказов печатает возраст (эта смена / прошлые смены), а не оплаты', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
          openJson: _earnedDataJson(sum: 30000),
          carriedOverJson: _earnedDataJson(sum: 6241271),
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('Эта смена: 30 000'));
      expect(text, contains('С прошлых смен: 6 241 271'));
      // Итог - сумма обеих строк.
      expect(text, contains('Итого: 6 271 271'));

      // Раскладки по видам оплаты (Наличка/Терминал/Перевод/Перечисление)
      // в этом блоке больше нет - только заголовок, возраст, итог и
      // отдельная строка про безнал, до следующего раздела (ЧИСТАЯ
      // ВЫРУЧКА, т.к. предоплат и факт. суммы в тестовых данных нет).
      final openIdx = text.indexOf('НЕЗАКРЫТЫЕ ЗАКАЗЫ');
      final netIdx = text.indexOf('ЧИСТАЯ ВЫРУЧКА');
      final openSection = text.substring(openIdx, netIdx);
      expect(openSection, isNot(contains('Наличка')));
      expect(openSection, isNot(contains('Терминал')));
      expect(openSection, isNot(contains('Перевод:')));
      expect(openSection, isNot(contains('Перечисление')));
    });

    test('НАЛИЧНЫЕ В КАССЕ: раздел есть с cash_balance, после ВЫЧЕТОВ', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
          openingCashJson: {
            'amount': 90000,
            'source': 'carried',
            'left_amount': 100000
          },
          cashBalanceJson: {
            'opening': 90000,
            'sales_cash': 65000,
            'expected': 148000,
            'actual': 150000,
            'difference': 2000,
            'left_for_next': 50000,
            'handed_over': 100000,
          },
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('НАЛИЧНЫЕ В КАССЕ'));
      expect(text, contains('Нач. остаток: 90 000'));
      expect(text, contains('принят 90 000 из 100 000'));
      expect(text, contains('Ожидалось: 148 000'));
      expect(text, contains('Факт: 150 000'));
      expect(text, contains('Разница: 2 000'));
      expect(text, contains('На размен: 50 000'));
      expect(text, contains('Сдать наличными: 100 000'));
      expect(text.indexOf('ВЫЧЕТЫ'),
          lessThan(text.indexOf('НАЛИЧНЫЕ В КАССЕ')));
      // Существующий раздел не переименован.
      expect(text, contains('СУММА К СДАЧЕ'));
    });

    test('НАЛИЧНЫЕ В КАССЕ: без ключа раздела нет', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(),
        time: '15.01.2024 18:00:00',
      );
      expect(receiptText(bytes), isNot(contains('НАЛИЧНЫЕ В КАССЕ')));
    });

    test('НАЛИЧНЫЕ В КАССЕ: открытая смена без факта, источники manual и auto', () async {
      for (final entry in {
        'manual': 'введён вручную',
        'auto': 'не подтверждён',
      }.entries) {
        final bytes = await printer.generateShift(
          shiftData: _buildShiftData(
            openingCashJson: {'amount': 5000, 'source': entry.key},
            cashBalanceJson: {
              'opening': 5000,
              'expected': 70000,
              'actual': null,
              'difference': null,
              'left_for_next': 0,
              'handed_over': null,
            },
          ),
          time: '15.01.2024 18:00:00',
        );
        final text = receiptText(bytes);
        expect(text, contains(entry.value));
        expect(text, isNot(contains('Факт: ')));
        expect(text, isNot(contains('Сдать наличными')));
      }
    });

    test('НАЛИЧНЫЕ В КАССЕ: строки раздела укладываются в 32 символа', () async {
      final narrow =
          MostbytePrint(ip: '127.0.0.1', name: 'T', paperSize: PaperSize.mm58);
      final bytes = await narrow.generateShift(
        shiftData: _buildShiftData(
          openingCashJson: {
            'amount': 999999999,
            'source': 'carried',
            'left_amount': 999999999
          },
          cashBalanceJson: {
            'opening': 999999999,
            'expected': 999999999999,
            'actual': 999999999999,
            'difference': -999999999999,
            'left_for_next': 999999999,
            'handed_over': 999999999999,
          },
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);
      final start = text.indexOf('НАЛИЧНЫЕ В КАССЕ');
      final end = text.indexOf('НЕЗАКРЫТЫЕ ЗАКАЗЫ');
      final lines = text
          .substring(start, end)
          .split(RegExp(r'[\n\r]'))
          .map((l) => l.replaceFirst(RegExp(r'^[^А-Яа-я]*'), ''))
          .where((l) => l.contains(':') || l.contains('принят') || l.startsWith('из '));
      expect(lines, isNotEmpty);
      for (final l in lines) {
        expect(l.runes.length, lessThanOrEqualTo(32), reason: l);
      }
    });

    test('ПОГАШЕНИЯ ДОЛГОВ: ненулевые способы, строка в наличных, 58 мм', () async {
      final narrow =
          MostbytePrint(ip: '127.0.0.1', name: 'T', paperSize: PaperSize.mm58);
      final bytes = await narrow.generateShift(
        shiftData: _buildShiftData(
          debtRepaymentJson: {
            'cash': 999999999999,
            'terminal': 0,
            'transfer_by_card': 0,
            'bank_transfer': 999999999999,
            'count': 2,
          },
          cashBalanceJson: {
            'opening': 0,
            'expected': 999999999999,
            'left_for_next': 0,
            'debt_repayment_cash': 999999999999,
          },
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);
      expect(text, contains('ПОГАШЕНИЯ ДОЛГОВ'));
      final start = text.indexOf('ПОГАШЕНИЯ ДОЛГОВ');
      final end = text.indexOf('ВЫЧЕТЫ');
      final section = text.substring(start, end);
      expect(section, contains('Наличка: 999 999 999 999'));
      expect(section, contains('Перечисление: 999 999 999 999'));
      expect(section, isNot(contains('Терминал')));
      expect(section, isNot(contains('Перевод')));
      expect(text, contains('в т.ч. погаш.: 999 999 999 999'));
      // Выручка и закрытые не затронуты.
      expect(text.indexOf('СУММА К СДАЧЕ'), lessThan(start));
      final lines = [
        ...section.split(RegExp(r'[\n\r]')),
        ...text
            .substring(text.indexOf('НАЛИЧНЫЕ В КАССЕ'))
            .split(RegExp(r'[\n\r]'))
            .where((l) => l.contains('в т.ч.')),
      ]
          .map((l) => l.replaceFirst(RegExp(r'^[^А-Яа-я]*'), ''))
          .where((l) => l.contains(':'));
      expect(lines, isNotEmpty);
      for (final l in lines) {
        expect(l.runes.length, lessThanOrEqualTo(32), reason: l);
      }
    });

    test('ПОГАШЕНИЯ ДОЛГОВ: без ключа или при count 0 раздела нет', () async {
      for (final json in <Map<String, dynamic>?>[
        null,
        {'cash': 0, 'terminal': 0, 'transfer_by_card': 0, 'bank_transfer': 0, 'count': 0},
      ]) {
        final bytes = await printer.generateShift(
          shiftData: _buildShiftData(debtRepaymentJson: json),
          time: '15.01.2024 18:00:00',
        );
        expect(receiptText(bytes), isNot(contains('ПОГАШЕНИЯ ДОЛГОВ')));
      }
    });

    test('закрытые из админки: строка под "Итого" закрытых, если count > 0', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
            closedByOthersJson: {'count': 3, 'sum': 45000}),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('из них закрыто из админки: 3, 45 000'));
      expect(text.indexOf('Итого: 135 000'),
          lessThan(text.indexOf('из них закрыто из админки')));
    });

    test('закрытые из админки: нет ключа или count = 0 - строки нет', () async {
      for (final json in <Map<String, dynamic>?>[
        null,
        {'count': 0, 'sum': 0},
      ]) {
        final bytes = await printer.generateShift(
          shiftData: _buildShiftData(closedByOthersJson: json),
          time: '15.01.2024 18:00:00',
        );
        expect(receiptText(bytes), isNot(contains('закрыто из админки')));
      }
    });

    test('отсутствие carried_over в JSON не роняет печать и не делит на два блока', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
          openJson: _earnedDataJson(sum: 30000),
          carriedOverJson: null,
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      // Без carried_over от старого бэка разбивку по возрасту не обещаем -
      // печатаем один общий итог, а не "Эта смена: 30000 / С прошлых
      // смен: 0" (последнее было бы тем же обманом, что и старый "ОСТАТОК
      // В КАССЕ": open по старой логике включает все незакрытые заказы
      // филиала, а не только эту смену).
      expect(text, isNot(contains('Эта смена')));
      expect(text, isNot(contains('С прошлых смен')));
      final openIdx = text.indexOf('НЕЗАКРЫТЫЕ ЗАКАЗЫ');
      final netIdx = text.indexOf('ЧИСТАЯ ВЫРУЧКА');
      final openSection = text.substring(openIdx, netIdx);
      expect(openSection, contains('Итого: 30 000'));
    });

    test('carried_over не влияет на ЧИСТУЮ ВЫРУЧКУ и вычеты - это справочная величина', () async {
      final bytesWithoutCarry = await printer.generateShift(
        shiftData: _buildShiftData(carriedOverJson: null),
        time: '15.01.2024 18:00:00',
      );
      final bytesWithCarry = await printer.generateShift(
        shiftData: _buildShiftData(
            carriedOverJson: _earnedDataJson(sum: 999999999)),
        time: '15.01.2024 18:00:00',
      );

      final textWithoutCarry = receiptText(bytesWithoutCarry);
      final textWithCarry = receiptText(bytesWithCarry);

      // closed.sum(100000) - (7000 + 3000) = 90000 в обоих случаях.
      expect(textWithoutCarry, contains('ЧИСТАЯ ВЫРУЧКА: 90 000'));
      expect(textWithCarry, contains('ЧИСТАЯ ВЫРУЧКА: 90 000'));
      expect(textWithCarry, isNot(contains('Ушло из кассы: 999')));
      expect(textWithCarry, isNot(contains('Недополучено: 999')));
    });

    // -----------------------------------------------------------------
    // "в т.ч. безналом" - безналичная часть незакрытых заказов
    // -----------------------------------------------------------------

    test('"в т.ч. безналом" суммирует безнал из open и carried_over', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
          openJson: _earnedDataJson(
              sum: 50000, terminal: 30000, transferByCard: 20000),
          carriedOverJson: _earnedDataJson(sum: 200000, terminal: 92648),
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      // open non-cash: 30000+20000=50000, carried_over non-cash: 92648.
      expect(text, contains('в т.ч. безналом: 142 648'));
    });

    test('"в т.ч. безналом" без carried_over считается только по open', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
          openJson: _earnedDataJson(
              sum: 50000, terminal: 30000, transferByCard: 20000),
          carriedOverJson: null,
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('в т.ч. безналом: 50 000'));
    });

    test('"в т.ч. безналом" печатается нулём, если весь оборот наличный', () async {
      // Строка печатается всегда (как и остальные суммовые строки чека,
      // например "Терминал: 0" в блоке "СУММА К СДАЧЕ") - отсутствие
      // строки при нуле создавало бы двусмысленность: не посчитали или
      // действительно ноль.
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(
          openJson: _earnedDataJson(sum: 30000),
          carriedOverJson: _earnedDataJson(sum: 6241271),
        ),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      expect(text, contains('в т.ч. безналом: 0'));
    });

    test('порядок секций чека: сумма к сдаче -> вычеты -> незакрытые -> чистая выручка', () async {
      final bytes = await printer.generateShift(
        shiftData: _buildShiftData(),
        time: '15.01.2024 18:00:00',
      );
      final text = receiptText(bytes);

      final closedIdx = text.indexOf('СУММА К СДАЧЕ');
      final deductionsIdx = text.indexOf('ВЫЧЕТЫ');
      final cashOutIdx = text.indexOf('Ушло из кассы');
      final openIdx = text.indexOf('НЕЗАКРЫТЫЕ ЗАКАЗЫ');
      final netIdx = text.indexOf('ЧИСТАЯ ВЫРУЧКА');

      expect(closedIdx, greaterThanOrEqualTo(0));
      expect(deductionsIdx, greaterThan(closedIdx));
      expect(cashOutIdx, greaterThan(deductionsIdx));
      expect(openIdx, greaterThan(cashOutIdx));
      expect(netIdx, greaterThan(openIdx));
    });
  });
}
