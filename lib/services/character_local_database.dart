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

  static Future<void> saveCharacters(List<Character> characters) async {
    await _box.clear();
    for (final char in characters) {
      await _box.put(char.id, char.toMap());
    }
    log("Zapisano bazę listą ${characters.length} postaci", name: "CharacterLocalDatabase");
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}