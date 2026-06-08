class Character {
  final String id;
  final String name;
  final String house;
  final String image;

  Character({
    required this.id,
    required this.name,
    required this.house,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "house": house,
      "image": image,
    };
  }

  factory Character.fromMap(Map map) {
    return Character(
      id: map["id"] ?? "",
      name: map["name"] ?? "Brak imienia",
      house: map["house"] ?? "Brak domu",
      image: map["image"] ?? "",
    );
  }
}