import 'earned_data.dart';

class Earned {
  EarnedData closed;
  EarnedData open;
  EarnedData refund;
  double discount;
  double debt;
  double wasted;

  Earned({
    required this.closed,
    required this.open,
    required this.refund,
    required this.debt,
    this.discount = 0,
    required this.wasted,
  });

  factory Earned.fromJson(Map<String, dynamic> json) {
    return Earned(
      closed: EarnedData.fromJson(json["closed"]),
      open: EarnedData.fromJson(json["open"]),
      refund: EarnedData.fromJson(json["refund"]),
      debt: json["debt"],
      discount: json["discount"],
      wasted: json["wasted"],
    );
  }

  Map<String, dynamic> toJson() => {
        "closed": closed.toJson(),
        "open": open.toJson(),
        "refund": refund.toJson(),
        "debt": debt,
        "discount": discount,
        "wasted": wasted,
      };
}
