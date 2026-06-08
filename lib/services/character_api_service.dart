import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character.dart';
import 'dart:developer';

class CharacterApiService {
  static const String baseUrl = "https://hp-api.onrender.com/api";


  static Future<List<Character>> fetchCharacters() async {
    final url = Uri.parse("$baseUrl/characters");
    log("Wysyłam zapytanie pod adres: $url", name: "CharacterApiService");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.take(30).map<Character>((json) => Character.fromMap(json)).toList();
      } else {
        throw Exception("Błąd pobierania danych: ${response.statusCode}");
      }
    } catch (error) {
      log("Wystąpił wyjątek podczas komunikacji z API", name: "CharacterApiService", error: error);
      rethrow;
    }
  }


  static Future<Character> fetchCharacterDetails(String id) async {
    final url = Uri.parse("$baseUrl/character/$id");
    log("Wysyłam zapytanie o szczegóły: $url", name: "CharacterApiService");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Character.fromMap(data[0]);
        } else {
          throw Exception("Nie znaleziono postaci");
        }
      } else {
        throw Exception("Błąd pobierania szczegółów: ${response.statusCode}");
      }
    } catch (error) {
      rethrow;
    }
  }
}