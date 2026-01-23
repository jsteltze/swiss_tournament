import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jni/jni.dart';

import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'java.g.dart';
import 'tournament_details_page.dart';

void main() {
  //Jni.spawn(dylibDir: 'build/jni', classPath: ['java']);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swiss Tournament',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Swiss Tournament Home Page"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Tournament> _tournaments = [];
  final TournamentStorage _storage = TournamentStorage();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    final tournaments = await _storage.loadTournaments();
    setState(() {
      _tournaments = tournaments;
    });
  }

  Future<void> _saveTournaments() async {
    await _storage.saveTournaments(_tournaments);
  }

  void _addTournament() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController roundsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Tournament'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter tournament name',
                ),
                autofocus: true,
              ),
              TextField(
                controller: roundsController,
                decoration: const InputDecoration(hintText: 'Number of rounds'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    roundsController.text.isNotEmpty) {
                  var newTournament = Tournament(
                    title: titleController.text,
                    numberOfRounds: int.parse(roundsController.text),
                  );
                  setState(() {
                    _tournaments.add(newTournament);
                  });
                  _saveTournaments();
                  Navigator.pop(context);
                  _navigateToTournamentDetails(newTournament);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTournament(Tournament tournament) {
    setState(() {
      _tournaments.remove(tournament);
    });
    _saveTournaments();
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailsPage(
          tournament: tournament,
          onDeleteTournament: () => _deleteTournament(tournament),
          onUpdate: _loadTournaments,
        ),
      ),
    );
  }

  void _exportTournaments() {
    final String json = jsonEncode(
      _tournaments.map((t) => t.toJson()).toList(),
    );
    Sample.exportToFile(
      Jni.androidActivity(PlatformDispatcher.instance.engineId!),
      JString.fromString(json),
      JString.fromString("tournaments.json"),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('"tournaments.json" exported to Downloads')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportTournaments();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt),
                      SizedBox(width: 8),
                      Text('Export'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _tournaments.isEmpty
          ? const Center(child: Text('No tournaments yet.'))
          : ListView.builder(
              itemCount: _tournaments.length,
              itemBuilder: (context, index) {
                final tournament = _tournaments[index];
                var state = 'not started';
                if (tournament.rounds.isNotEmpty) {
                  if (tournament.isFinished()) {
                    state =
                        'finished (${tournament.rounds.length}/${tournament.numberOfRounds})';
                  } else {
                    state =
                        'in Progress (${tournament.rounds.length}/${tournament.numberOfRounds})';
                  }
                }
                return ListTile(
                  title: Text(tournament.title),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text('Rounds: ${tournament.numberOfRounds}'),
                      ),
                      Text(
                        state,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  leading: const Icon(Icons.emoji_events),
                  onTap: () => _navigateToTournamentDetails(tournament),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTournament,
        tooltip: 'Add Tournament',
        child: const Icon(Icons.add),
      ),
    );
  }
}
