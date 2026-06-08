import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/character.dart';
import 'dart:developer';

class CharacterLocalDatabase {
  static Box get _box => Hive.box("characters");

  static List<Character> getCharacters() {
    final characters = _box.values.map((item) {
      return Character.fromMap(Map<String, dynamic>.from(item));
    }).toList();

    log("Odczytano ${characters.length} postaci z lokalnej bazy", name: "CharacterLocalDatabase");
    return characters;
  }

  static Future<void> saveCharacters(List<Character> newCharacters) async {
    final existing = getCharacters();
    final favoriteIds = existing.where((c) => c.isFavorite).map((c) => c.id).toSet();

    await _box.clear();
    for (final char in newCharacters) {
      if (favoriteIds.contains(char.id)) {
        char.isFavorite = true;
      }
      await _box.put(char.id, char.toMap());
    }
    log("Zapisano bazę listą ${newCharacters.length} postaci", name: "CharacterLocalDatabase");
  }

  static Future<void> updateCharacter(Character character) async {
    await _box.put(character.id, character.toMap());
    log("Zaktualizowano postać ${character.name} (Ulubione: ${character.isFavorite})", name: "CharacterLocalDatabase");
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}