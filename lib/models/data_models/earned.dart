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
      closed: json["closed"] != null
          ? EarnedData.fromJson(json["closed"])
          : EarnedData(sum: 0, terminal: 0),
      open: json["open"] != null
          ? EarnedData.fromJson(json["open"])
          : EarnedData(sum: 0, terminal: 0),
      refund: json["refund"] != null
          ? EarnedData.fromJson(json["refund"])
          : EarnedData(sum: 0, terminal: 0),
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
