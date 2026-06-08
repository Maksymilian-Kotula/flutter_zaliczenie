import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'models/character.dart';
import 'services/character_local_database.dart';
import 'services/character_sync_service.dart';
import 'services/character_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox("characters");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "KrakFlow - Harry Potter",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ---------------- GŁÓWNY EKRAN Z DOLNYM PASKIEM NAWIGACJI ----------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista trzech głównych ekranów
  final List<Widget> _screens = [
    const CharacterListScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Lista"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Ulubione"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ustawienia"),
        ],
      ),
    );
  }
}

// ---------------- EKRAN 1: LISTA POSTACI ----------------

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  List<Character> allCharacters = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _wczytajPostaci();
  }

  Future<void> _wczytajPostaci() async {
    try {
      await CharacterSyncService.loadInitialDataIfNeeded();
      final characters = CharacterLocalDatabase.getCharacters();

      setState(() {
        allCharacters = characters;
        isLoading = false;
        errorMessage = null;
      });

      // ---> EVENT 1: Analityka - załadowanie listy <---
      await FirebaseAnalytics.instance.logEvent(name: "lista_zaladowana");

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Błąd połączenia. Upewnij się, że masz internet.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Postacie z HP"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _wczytajPostaci();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : ListView.builder(
        itemCount: allCharacters.length,
        itemBuilder: (context, index) {
          final character = allCharacters[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(character.name[0]),
              ),
              title: Text(character.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Dom: ${character.house.isNotEmpty ? character.house : 'Brak'}"),
              trailing: IconButton(
                icon: Icon(
                  character.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: character.isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  // Przełączanie statusu Ulubione
                  character.isFavorite = !character.isFavorite;
                  await CharacterLocalDatabase.updateCharacter(character);
                  setState(() {}); // Odśwież widok

                  // ---> EVENT 2: Analityka - kliknięcie w serduszko <---
                  await FirebaseAnalytics.instance.logEvent(
                    name: "ulubione_klikniete",
                    parameters: {
                      "character_name": character.name,
                      "is_favorite": character.isFavorite.toString(),
                    },
                  );
                },
              ),
              onTap: () async {
                // ---> EVENT 3: Analityka - wejście w szczegóły postaci <---
                await FirebaseAnalytics.instance.logEvent(
                  name: "szczegoly_postaci_otwarte",
                  parameters: {"character_name": character.name},
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterDetailsScreen(characterId: character.id),
                  ),
                ).then((_) {
                  // Odświeżanie listy po powrocie
                  setState(() {
                    allCharacters = CharacterLocalDatabase.getCharacters();
                  });
                });
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------- EKRAN 2: ULUBIONE ---------------

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Odczytanie bazy za każdym razem przy wejsciu na ekran
    final allCharacters = CharacterLocalDatabase.getCharacters();
    final favoriteCharacters = allCharacters.where((c) => c.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ulubione postacie"),
      ),
      body: favoriteCharacters.isEmpty
          ? const Center(child: Text("Jeszcze nikogo nie polubiłeś!"))
          : ListView.builder(
        itemCount: favoriteCharacters.length,
        itemBuilder: (context, index) {
          final character = favoriteCharacters[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(character.name[0])),
              title: Text(character.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Dom: ${character.house}"),
              trailing: const Icon(Icons.favorite, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}

// ------------- EKRAN 3: USTAWIENIA ---------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ustawienia"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("O aplikacji"),
            subtitle: Text("Projekt zaliczeniowy z użyciem Fluttera i HP-API."),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Wyczyść lokalną bazę danych", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Hive.box("characters").clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Baza została wyczyszczona.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// -------------- EKRAN 4: SZCZEGÓŁY POSTACI ----------------

class CharacterDetailsScreen extends StatefulWidget {
  final String characterId;

  const CharacterDetailsScreen({super.key, required this.characterId});

  @override
  State<CharacterDetailsScreen> createState() => _CharacterDetailsScreenState();
}

class _CharacterDetailsScreenState extends State<CharacterDetailsScreen> {
  Character? characterDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _pobierzSzczegoly();
  }

  Future<void> _pobierzSzczegoly() async {
    try {
      final details = await CharacterApiService.fetchCharacterDetails(widget.characterId);
      setState(() {
        characterDetails = details;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Nie udało się pobrać szczegółów postaci z serwera.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Szczegóły"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (characterDetails!.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  characterDetails!.image,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                ),
              )
            else
              const Icon(Icons.person, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              characterDetails!.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Dom Hogwartu"),
                subtitle: Text(characterDetails!.house.isNotEmpty ? characterDetails!.house : "Brak przydziału"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}