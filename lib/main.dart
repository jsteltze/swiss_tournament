import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
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
      title: 'Chess Swiss Tournament',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Chess Swiss Tournament"),
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
    SwissChessAndroid.exportToFile(
      Jni.androidActivity(PlatformDispatcher.instance.engineId!),
      JString.fromString(json),
      JString.fromString("tournaments.json"),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('"tournaments.json" exported to Downloads')),
    );
  }

  Future<void> _importTournaments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final dynamic decoded = jsonDecode(content);

        List<Tournament> parsedTournaments = [];

        if (decoded is List) {
          // List of tournaments
          parsedTournaments = decoded
              .map((json) => Tournament.fromJson(json))
              .toList();
        } else if (decoded is Map<String, dynamic>) {
          // Single tournament
          parsedTournaments = [Tournament.fromJson(decoded)];
        }

        if (parsedTournaments.isNotEmpty && mounted) {
          _showImportConfirmationDialog(
            file.path.split('/').last,
            parsedTournaments,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing: $e')));
      }
    }
  }

  void _showImportConfirmationDialog(
    String filename,
    List<Tournament> tournaments,
  ) {
    //List<bool> selected = List.generate(tournaments.length, (index) => true);
    String importType = 'Full Tournament';

    showDialog(
      context: context,
      builder: (context) {
        List<bool> selected = List.generate(
          tournaments.length,
          (index) => true,
        );
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Import'),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$filename: contains ${tournaments.length} tournament(s) that can be imported.',
                  ),
                  SizedBox(height: 20),
                  const Text(
                    'Import type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: importType,
                    isExpanded: true,
                    items: <String>['Full Tournament', 'Players only']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        importType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select tournament(s) to import:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: tournaments.length,
                      itemBuilder: (context, index) {
                        final t = tournaments[index];
                        return CheckboxListTile(
                          title: Text(t.title),
                          subtitle: Text(
                            '${t.players.length} players${importType == 'Full Tournament' ? ', ${t.numberOfRounds} rounds' : ''}',
                          ),
                          value: selected[index],
                          onChanged: (val) {
                            setDialogState(() {
                              selected[index] = val!;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Text(
                    'Selected: ${selected.where((s) => s).length} / ${tournaments.length}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    int count = 0;
                    for (int i = 0; i < tournaments.length; i++) {
                      if (selected[i]) {
                        final t = tournaments[i];
                        t.id = null; // Save as new
                        if (importType == 'Players only') {
                          t.rounds.removeRange(0, t.rounds.length);
                        }
                        await _storage.updateTournament(t);
                        count++;
                      }
                    }
                    _loadTournaments();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Imported $count tournament(s)'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Import Selected (${selected.where((s) => s).length})',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Image.asset('assets/rook_new.png'),
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportTournaments();
              } else if (value == 'import') {
                _importTournaments();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload),
                      SizedBox(width: 8),
                      Text('Import'),
                    ],
                  ),
                ),
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
