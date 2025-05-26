class Filial {
  int id;
  String name_uz;
  String name_ru;
  String name_en;

  Filial({
    required this.id,
    required this.name_uz,
    required this.name_ru,
    required this.name_en,
  });

  factory Filial.fromJson(Map<String, dynamic> json) {
    return Filial(
      id: json["id"],
      name_uz: json["nameUz"],
      name_ru: json["nameRu"],
      name_en: json["nameEng"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "nameUz": name_uz,
        "nameRu": name_ru,
        "nameEng": name_en,
      };
}
