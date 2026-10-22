import 'earned_data.dart';
import 'prepayment_data.dart';

class Earned {
  EarnedData closed;
  EarnedData open;
  EarnedData refund;
  // Незакрытые заказы, оставшиеся с прошлых смен (не из этой открытой).
  // Справочная величина - в чистую выручку и вычеты не входит.
  // null, а не ноль - разница принципиальна: null значит, что бэк ещё не
  // умеет отдавать этот ключ (старая версия pos_order), и `open` по старой
  // логике включает вообще все незакрытые заказы филиала без рамки по
  // дате. Печатать в этом случае "0" в разбивке по возрасту - соврать
  // так же, как врал старый "ОСТАТОК В КАССЕ".
  EarnedData? carriedOver;
  double discount;
  double debt;
  double wasted;
  PrepaymentData? prepayment;
  EarnedData? currentAmount;
  // Счета смены, закрытые из админки: {count, sum}. null - ключа нет
  // (старая смена или старый бэк), строку на чеке не печатаем.
  int? closedByOthersCount;
  double? closedByOthersSum;
  // Размен: ключей нет у старых смен и старого бэка, раздел на чеке не печатаем.
  OpeningCash? openingCash;
  LeftForNext? leftForNext;
  CashBalance? cashBalance;
  // Погашения долгов из админки; ключа нет у старых смен и старого бэка.
  DebtRepayment? debtRepayment;

  Earned({
    required this.closed,
    required this.open,
    required this.refund,
    this.carriedOver,
    required this.debt,
    this.discount = 0,
    required this.wasted,
    this.prepayment,
    this.currentAmount,
    this.closedByOthersCount,
    this.closedByOthersSum,
    this.openingCash,
    this.leftForNext,
    this.cashBalance,
    this.debtRepayment,
  });

  factory Earned.fromJson(Map<String, dynamic> json) {
    // Check if current_amount has at least one non-null value
    EarnedData? currentAmountData;
    final currentAmountJson = json["current_amount"];
    if (currentAmountJson != null && currentAmountJson is Map<String, dynamic>) {
      final hasValue = currentAmountJson["sum"] != null ||
          currentAmountJson["terminal"] != null ||
          currentAmountJson["transfer_by_card"] != null;
      if (hasValue) {
        currentAmountData = EarnedData.fromJson(currentAmountJson);
      }
    }

    final byOthers = json["closed_by_others"];

    return Earned(
      closed: EarnedData.fromJson(json["closed"] ?? {}),
      open: EarnedData.fromJson(json["open"] ?? {}),
      refund: EarnedData.fromJson(json["refund"] ?? {}),
      // Ключа нет у старого бэка - оставляем null (не ноль), парсинг не падает.
      carriedOver: json["carried_over"] != null
          ? EarnedData.fromJson(json["carried_over"])
          : null,
      debt: (json["debt"] ?? 0).toDouble(),
      discount: (json["discount"] ?? 0).toDouble(),
      wasted: (json["wasted"] ?? 0).toDouble(),
      prepayment: json["prepayment"] != null
          ? PrepaymentData.fromJson(json["prepayment"])
          : null,
      currentAmount: currentAmountData,
      closedByOthersCount:
          byOthers is Map ? (byOthers["count"] ?? 0).toInt() : null,
      closedByOthersSum:
          byOthers is Map ? (byOthers["sum"] ?? 0).toDouble() : null,
      openingCash: json["opening_cash"] is Map<String, dynamic>
          ? OpeningCash.fromJson(json["opening_cash"])
          : null,
      leftForNext: json["left_for_next"] is Map<String, dynamic>
          ? LeftForNext.fromJson(json["left_for_next"])
          : null,
      cashBalance: json["cash_balance"] is Map<String, dynamic>
          ? CashBalance.fromJson(json["cash_balance"])
          : null,
      debtRepayment: json["debt_repayment"] is Map<String, dynamic>
          ? DebtRepayment.fromJson(json["debt_repayment"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "closed": closed.toJson(),
        "open": open.toJson(),
        "refund": refund.toJson(),
        "carried_over": carriedOver?.toJson(),
        "debt": debt,
        "discount": discount,
        "wasted": wasted,
        "prepayment": prepayment?.toJson(),
        "current_amount": currentAmount?.toJson(),
        "closed_by_others": closedByOthersCount == null
            ? null
            : {"count": closedByOthersCount, "sum": closedByOthersSum ?? 0},
        "opening_cash": openingCash?.toJson(),
        "left_for_next": leftForNext?.toJson(),
        "cash_balance": cashBalance?.toJson(),
        "debt_repayment": debtRepayment?.toJson(),
      };
}

/// Погашения долгов из админки по способам оплаты. В выручку не входят.
class DebtRepayment {
  final double cash;
  final double terminal;
  final double transferByCard;
  final double bankTransfer;
  final int count;

  DebtRepayment({
    this.cash = 0,
    this.terminal = 0,
    this.transferByCard = 0,
    this.bankTransfer = 0,
    this.count = 0,
  });

  factory DebtRepayment.fromJson(Map<String, dynamic> json) => DebtRepayment(
        cash: (json["cash"] ?? 0).toDouble(),
        terminal: (json["terminal"] ?? 0).toDouble(),
        transferByCard: (json["transfer_by_card"] ?? 0).toDouble(),
        bankTransfer: (json["bank_transfer"] ?? 0).toDouble(),
        count: (json["count"] ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        "cash": cash,
        "terminal": terminal,
        "transfer_by_card": transferByCard,
        "bank_transfer": bankTransfer,
        "count": count,
      };
}

double? _toDoubleOrNull(dynamic v) => v == null ? null : (v as num).toDouble();

/// Начальный остаток смены. source: carried | auto | manual | none.
class OpeningCash {
  final double amount;
  final String source;
  final double? leftAmount;

  OpeningCash({required this.amount, this.source = 'none', this.leftAmount});

  factory OpeningCash.fromJson(Map<String, dynamic> json) => OpeningCash(
        amount: (json["amount"] ?? 0).toDouble(),
        source: (json["source"] ?? 'none').toString(),
        leftAmount: _toDoubleOrNull(json["left_amount"]),
      );

  Map<String, dynamic> toJson() =>
      {"amount": amount, "source": source, "left_amount": leftAmount};
}

/// Размен, оставленный следующей смене. acceptedAmount null - ещё не принят.
class LeftForNext {
  final double amount;
  final double? acceptedAmount;

  LeftForNext({required this.amount, this.acceptedAmount});

  factory LeftForNext.fromJson(Map<String, dynamic> json) {
    final accepted = json["accepted"];
    return LeftForNext(
      amount: (json["amount"] ?? 0).toDouble(),
      acceptedAmount:
          accepted is Map ? _toDoubleOrNull(accepted["amount"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "accepted":
            acceptedAmount == null ? null : {"amount": acceptedAmount},
      };
}

/// Сверка наличных смены (считает сервер). actual/difference/handedOver
/// null, пока суммы не введены.
class CashBalance {
  final double opening;
  final double expected;
  final double? actual;
  final double? difference;
  final double leftForNext;
  final double? handedOver;
  // Наличные погашения долгов, уже входят в expected; null у старого бэка.
  final double? debtRepaymentCash;

  CashBalance({
    required this.opening,
    required this.expected,
    this.actual,
    this.difference,
    this.leftForNext = 0,
    this.handedOver,
    this.debtRepaymentCash,
  });

  factory CashBalance.fromJson(Map<String, dynamic> json) => CashBalance(
        opening: (json["opening"] ?? 0).toDouble(),
        expected: (json["expected"] ?? 0).toDouble(),
        actual: _toDoubleOrNull(json["actual"]),
        difference: _toDoubleOrNull(json["difference"]),
        leftForNext: (json["left_for_next"] ?? 0).toDouble(),
        handedOver: _toDoubleOrNull(json["handed_over"]),
        debtRepaymentCash: _toDoubleOrNull(json["debt_repayment_cash"]),
      );

  Map<String, dynamic> toJson() => {
        "opening": opening,
        "expected": expected,
        "actual": actual,
        "difference": difference,
        "left_for_next": leftForNext,
        "handed_over": handedOver,
        "debt_repayment_cash": debtRepaymentCash,
      };
}
