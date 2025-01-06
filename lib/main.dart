import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokémon App',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PokemonWordlePage(),
    const PokedexPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: 'Wordle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Pokédex',
          ),
        ],
      ),
    );
  }
}

class PokemonWordlePage extends StatefulWidget {
  const PokemonWordlePage({Key? key}) : super(key: key);

  @override
  _PokemonWordlePageState createState() => _PokemonWordlePageState();
}

class _PokemonWordlePageState extends State<PokemonWordlePage> {
  String _pokemonName = '';
  String? _pokemonImage;
  String? _correctPokemonName;
  int _attemptsLeft = 5;
  String _message = '';
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Future<void> _startNewGame() async {
    setState(() {
      _attemptsLeft = 5;
      _message = '';
      _gameOver = false;
      _correctPokemonName = null;
      _pokemonImage = null;
    });

    final randomId = Random().nextInt(151) + 1; // IDs de 1 a 151 (Primera generación)
    try {
      final data = await fetchPokemon(randomId);
      setState(() {
        _pokemonImage = data['sprites']['front_default'];
        _correctPokemonName = data['name'];
      });
    } catch (e) {
      setState(() {
        _message = 'Error al cargar el Pokémon. Intenta nuevamente.';
      });
    }
  }

  Future<void> _checkGuess() async {
    if (_gameOver) return;

    if (_pokemonName.toLowerCase() == _correctPokemonName?.toLowerCase()) {
      setState(() {
        _message = '¡Correcto! Era $_correctPokemonName';
        _gameOver = true;
      });
    } else {
      setState(() {
        _attemptsLeft--;
        if (_attemptsLeft == 0) {
          _message = '¡Has perdido! Era $_correctPokemonName';
          _gameOver = true;
        } else {
          _message = 'Intento incorrecto. Te quedan $_attemptsLeft intentos.';
        }
      });
    }
    _pokemonName = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Wordle'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 120, 167, 253), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_pokemonImage != null)
              Image.network(
                _pokemonImage!,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Adivina el nombre del Pokémon',
                labelStyle: const TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => _pokemonName = value,
              enabled: !_gameOver,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: !_gameOver ? _checkGuess : null,
              child: const Text('Adivinar', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_gameOver)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _startNewGame,
                child: const Text('Reiniciar Juego', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}

class PokedexPage extends StatefulWidget {
  const PokedexPage({Key? key}) : super(key: key);

  @override
  _PokedexPageState createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  final List<Map<String, dynamic>> _pokedex = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentOffset = 1; // Empieza en el ID 1
  final int _limit = 10; // Cantidad de Pokémon a cargar por lote

  @override
  void initState() {
    super.initState();
    _fetchNextBatch(); // Cargar el primer lote
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
        _fetchNextBatch(); // Cargar más cuando llegue al final
      }
    });
  }

  Future<void> _fetchNextBatch() async {
    setState(() => _isLoading = true);

    final List<Map<String, dynamic>> newPokemon = [];
    for (int i = _currentOffset; i < _currentOffset + _limit; i++) {
      if (i > 151) break; // Limitar a la primera generación
      try {
        final data = await fetchPokemon(i);
        newPokemon.add({
          'id': i,
          'name': data['name'],
          'sprite': data['sprites']['front_default'],
        });
      } catch (e) {
        break; // En caso de error, salir del bucle
      }
    }

    setState(() {
      _pokedex.addAll(newPokemon);
      _currentOffset += _limit; // Actualizar el siguiente lote
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _pokedex.length + 1,
              itemBuilder: (context, index) {
                if (index < _pokedex.length) {
                  final pokemon = _pokedex[index];
                  return ListTile(
                    leading: Image.network(pokemon['sprite']),
                    title: Text(pokemon['name']),
                    subtitle: Text('ID: ${pokemon['id']}'),
                  );
                } else if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return const SizedBox.shrink(); // Placeholder vacío
                }
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}


Future<Map<String, dynamic>> fetchPokemon(int id) async {
  final url = 'https://pokeapi.co/api/v2/pokemon/$id';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load Pokémon');
  }
}
