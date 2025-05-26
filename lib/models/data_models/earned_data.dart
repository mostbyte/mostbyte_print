// part '../hive/filial.g.dart';

class EarnedData {
  double sum;
  double terminal;
  double transferByCard;

  EarnedData({
    required this.sum,
    required this.terminal,
    this.transferByCard = 0,
  });

  factory EarnedData.fromJson(Map<String, dynamic> json) {
    return EarnedData(
      sum: json["sum"],
      terminal: json["terminal"],
      transferByCard:
          json.containsKey("transfer_by_card") ? json["transfer_by_card"] : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "sum": sum,
        "terminal": terminal,
        "transfer_by_card": transferByCard,
      };
}
