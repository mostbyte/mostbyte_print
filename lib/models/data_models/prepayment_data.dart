class PrepaymentData {
  double cash;
  double terminal;
  double transferByCard;
  double bankTransfer;

  PrepaymentData({
    required this.cash,
    required this.terminal,
    this.transferByCard = 0,
    this.bankTransfer = 0,
  });

  factory PrepaymentData.fromJson(Map<String, dynamic> json) {
    return PrepaymentData(
      cash: (json["cash"] ?? 0).toDouble(),
      terminal: (json["terminal"] ?? 0).toDouble(),
      transferByCard: (json["transfer_by_card"] ?? 0).toDouble(),
      bankTransfer: (json["bank_transfer"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        "cash": cash,
        "terminal": terminal,
        "transfer_by_card": transferByCard,
        "bank_transfer": bankTransfer,
      };
}
