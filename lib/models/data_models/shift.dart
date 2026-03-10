import './data_models.dart';

class Shift {
  int id;
  User? user;
  String openedAt;
  String? closedAt;
  Earned? earned;

  Shift({
    required this.id,
    this.user,
    required this.openedAt,
    this.closedAt,
    this.earned,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json["id"],
      user: json["user"] != null ? User.fromJson(json["user"]) : null,
      openedAt: json["opened_at"],
      closedAt: json["closed_at"],
      earned: json["earned"] != null ? Earned.fromJson(json["earned"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "user": user?.toJson(),
        "opened_at": openedAt,
        "closed_at": closedAt,
        "earned": earned,
      };
}
