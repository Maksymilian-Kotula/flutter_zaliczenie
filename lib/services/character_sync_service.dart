import 'character_api_service.dart';
import 'character_local_database.dart';

class CharacterSyncService {
  static Future<void> loadInitialDataIfNeeded() async {
    if (!CharacterLocalDatabase.isEmpty()) {
      return;
    }

    final characters = await CharacterApiService.fetchCharacters();
    await CharacterLocalDatabase.saveCharacters(characters);
  }
}