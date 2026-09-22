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
      };
}
