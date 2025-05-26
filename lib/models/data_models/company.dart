class Company {
  int id;
  String name;
  String address;
  String inn;
  String type;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.inn,
    required this.type,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json["id"],
      name: json["name"],
      address: json["address"],
      inn: json["inn"],
      type: json["type"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "address": address,
        "inn": inn,
        "type": type,
      };
}
