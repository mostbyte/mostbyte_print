class Role {
  int id;
  String nameUz;
  String nameRu;
  String nameEn;
  String role;

  Role({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.role,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json["id"],
      nameUz: json["nameUz"],
      nameRu: json["nameRu"],
      nameEn: json["nameEng"],
      role: json["name"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "nameUz": nameUz,
        "nameRu": nameRu,
        "nameEng": nameEn,
        "name": role,
      };
}
