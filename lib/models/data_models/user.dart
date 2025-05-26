import './data_models.dart';

class User {
  String id;
  String firstname;
  String surname;
  String? username;
  Filial? filial;
  Company? company;
  Role? role;
  String email;
  String patronymic;
  String phone;

  User({
    required this.id,
    required this.firstname,
    required this.surname,
    this.username,
    required this.filial,
    required this.company,
    required this.role,
    required this.email,
    required this.patronymic,
    required this.phone,
  });

  bool isAnonymous() {
    return role == 'ANONYMOUS';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["uuid"],
      username: json["userName"],
      firstname: json["firstName"],
      surname: json["surname"],
      filial: json["branch"] != null
          ? Filial.fromJson(Map<String, dynamic>.from(json["branch"]))
          : null,
      company: Company.fromJson(Map<String, dynamic>.from(json["company"])),
      role: json["role"] != null
          ? Role.fromJson(Map<String, dynamic>.from(json["role"]))
          : null,
      patronymic: json.containsKey("patronymic") ? json["patronymic"] : "",
      phone: json["phoneNumber"] ?? "",
      email: json.containsKey("email") ? json["email"] : "",
    );
  }

  Map<String, dynamic> toJson() => {
        "uuid": id,
        "userName": firstname,
        "firstName": firstname,
        "surname": surname,
        "filial_id": filial?.id,
        "branch": filial?.toJson(),
        "company": company?.toJson(),
        "role": role?.toJson(),
      };
}
