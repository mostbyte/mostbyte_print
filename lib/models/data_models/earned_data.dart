// part '../hive/filial.g.dart';

class EarnedData {
  double sum;
  double terminal;
  double transferByCard;
  double bankTransfer;

  EarnedData({
    required this.sum,
    required this.terminal,
    this.transferByCard = 0,
    this.bankTransfer = 0,
  });

  factory EarnedData.fromJson(Map<String, dynamic> json) {
    return EarnedData(
      sum: (json["sum"] ?? 0).toDouble(),
      terminal: (json["terminal"] ?? 0).toDouble(),
      transferByCard: (json["transfer_by_card"] ?? 0).toDouble(),
      bankTransfer: (json["bank_transfer"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        "sum": sum,
        "terminal": terminal,
        "transfer_by_card": transferByCard,
        "bank_transfer": bankTransfer,
      };
}
