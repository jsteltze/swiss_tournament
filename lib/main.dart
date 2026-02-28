import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swiss_tournament/components/no_data_tile.dart';
import 'package:swiss_tournament/components/tournament_dialogs.dart';
import 'package:swiss_tournament/components/tournament_popup_menu.dart';
import 'package:url_launcher/url_launcher_string.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Swiss Tournament',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
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
  bool _isLoading = true;
  final TournamentStorage _storage = TournamentStorage();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
    });
    final tournaments = await _storage.loadTournaments();
    setState(() {
      _tournaments = tournaments;
      _isLoading = false;
    });
  }

  Future<void> _saveTournaments() async {
    await _storage.saveTournaments(_tournaments);
  }

  void _addTournament() {
    showEditTournamentDialog(context, null, (tournament) {
      setState(() {
        _tournaments.add(tournament);
      });
      tournament.update = () => _storage.updateTournament(tournament);
      tournament.update();
      _navigateToTournamentDetails(tournament);
    });
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

  void _showInfoDialog() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('App Info'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Welcome to ${packageInfo.appName}!\nThis is an Opensource, Free-to-use Android-App for organizing and managing chess tournaments in Swiss mode.\nAll data is stored locally on your device. No Internet connection required.',
                      ),
                      ExpansionTile(
                        title: Text('About'),
                        children: [
                          Text(
                            'I am familiar using the commercial program "Swiss Chess". However besides being costly, the program is running on Windows/PC only.\nMy goal was to create an easy to use and free App, since all the Apps I found so far were either commercial or simply bad. Also I wanted the App to have as little dependencies as possible. So everything is stored locally on your device. You are the owner of your tournament data!\nThis App will probably not support each and every advanced setting for Swiss tournaments. But I hope it will be suitable for the majority of tournaments.',
                          ),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                              text: 'Github Home',
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => launchUrlString(
                                  'https://github.com/jsteltze/swiss_tournament.git',
                                ),
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text('Version'),
                        children: [Text('Version: ${packageInfo.version}')],
                      ),
                      ExpansionTile(
                        title: Text('Technologies used'),
                        children: [
                          Text(
                            'This is my first programming with Flutter/Dart. Initially I did not intend to restrict the platform to Android. But I\'m using the pairing engine "JaVaFo", which is a Java library. I was only able to get this Java program running on Android.',
                          ),
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Language:')),
                              Text('Flutter/Dart'),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Database:')),
                              Text('sqflite'),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Package Info:')),
                              Text('package_info_plus'),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Design:')),
                              Text('Material v3'),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Icons:')),
                              Text('Cupertino Icons'),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Pairing:')),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                  text: 'JaVaFo library (Java)',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => launchUrlString(
                                      'https://www.rrweb.org/javafo/JaVaFo.htm',
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text('License Info'),
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 90, child: Text('Rook Icon:')),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                  text: 'Icon by Freepik',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => launchUrlString(
                                      'https://www.freepik.com/icon/rook_562880#fromView=search&page=1&position=36&uuid=c1e0d777-66db-4757-98d6-8a870ff59f43',
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Container(
          padding: EdgeInsets.all(8),
          child: Image.asset('assets/rook_new.png'),
        ),
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportTournaments();
              } else if (value == 'import') {
                _importTournaments();
              } else if (value == 'info') {
                _showInfoDialog();
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
                const PopupMenuItem<String>(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('App Info'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tournaments.isEmpty
          ? NoDataTile(
              text: 'No tournaments added yet.',
              icon: Icons.emoji_events_outlined,
            )
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
                return TournamentPopupMenu(
                  tournament: tournament,
                  storage: _storage,
                  onEdit: (tournament) => setState(() {}),
                  onDelete: () => _deleteTournament(tournament),
                  onUpdate: _loadTournaments,
                  child: ListTile(
                    title: Text(
                      tournament.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rounds: ${tournament.numberOfRounds}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        Text(
                          state,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.emoji_events),
                    onTap: () => _navigateToTournamentDetails(tournament),
                  ),
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
