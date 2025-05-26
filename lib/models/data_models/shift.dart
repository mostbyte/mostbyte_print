import './data_models.dart';

class Shift {
  int id;
  User user;
  String openedAt;
  String? closedAt;
  Earned? earned;

  Shift({
    required this.id,
    required this.user,
    required this.openedAt,
    required this.closedAt,
    required this.earned,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json["id"],
      user: User.fromJson(json["user"]),
      openedAt: json["opened_at"],
      closedAt: json["closed_at"],
      earned: json["earned"] != null ? Earned.fromJson(json["earned"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "user": user.toJson(),
        "opened_at": openedAt,
        "closed_at": closedAt,
        "earned": earned,
      };
}
