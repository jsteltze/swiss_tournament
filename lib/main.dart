import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swiss_tournament/components/no_data_tile.dart';
import 'package:swiss_tournament/dialogs/main_dialogs.dart';
import 'package:swiss_tournament/dialogs/tournament_dialogs.dart';
import 'package:swiss_tournament/dialogs/tournament_popup_menu.dart';
import 'package:swiss_tournament/utils/globals.dart';
import 'package:swiss_tournament/utils/logger.dart';
import 'package:swiss_tournament/utils/snackbar_utils.dart';

import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'tournament_details_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FileLogger.init();
  final packageInfo = await PackageInfo.fromPlatform();
  Globals.packageInfo = packageInfo;
  FileLogger.log('Starting application...');

  //Jni.spawn(dylibDir: 'build/jni', classPath: ['java']);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Globals.packageInfo.appName,
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
      home: MyHomePage(title: Globals.packageInfo.appName),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkFirstTime(context);
    });
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
    });
    FileLogger.log('Loading tournaments...');
    final tournaments = await _storage.loadTournaments();
    setState(() {
      _tournaments = tournaments;
      _isLoading = false;
    });
    FileLogger.log('Loaded ${tournaments.length} tournaments');
  }

  Future<void> _saveTournaments() async {
    FileLogger.log('Saving all tournaments...');
    await _storage.saveTournaments(_tournaments);
  }

  void _addTournament() {
    showEditTournamentDialog(context, null, (tournament) {
      FileLogger.log('Adding tournament: ${tournament.title}');
      setState(() {
        _tournaments.add(tournament);
      });
      tournament.update = () => _storage.updateTournament(tournament);
      tournament.update();
      _navigateToTournamentDetails(tournament);
    });
  }

  void _deleteTournament(Tournament tournament) {
    FileLogger.log('Deleting tournament: ${tournament.title}');
    setState(() {
      _tournaments.remove(tournament);
    });
    _saveTournaments();
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    FileLogger.log('Navigating to tournament details: ${tournament.title}');
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

  Future<void> _importTournaments() async {
    try {
      FileLogger.log('Picking file for import...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        FileLogger.log('Importing from file: $path');
        final file = File(path);
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

        FileLogger.log(
          'Parsed ${parsedTournaments.length} tournaments from import',
        );

        if (parsedTournaments.isNotEmpty && mounted) {
          showImportConfirmationDialog(
            context,
            file.path.split('/').last,
            parsedTournaments,
            _storage,
            _loadTournaments,
          );
        }
      } else {
        FileLogger.log('Import cancelled by user');
      }
    } catch (e) {
      FileLogger.log('Error importing: $e');
      if (mounted) {
        showSnackbar(context, 'Error importing: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/rook_new.png'),
        ),
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                FileLogger.log('Export triggered');
                showExportDialog(context, _tournaments);
              } else if (value == 'import') {
                _importTournaments();
              } else if (value == 'info') {
                FileLogger.log('App info dialog requested');
                showAppInfoDialog(context);
              } else if (value == 'logs') {
                showLogsDialog(context);
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
                  value: 'logs',
                  child: Row(
                    children: [
                      Icon(Icons.list_alt),
                      SizedBox(width: 8),
                      Text('View Logs'),
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
                    leading: Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onTap: () => _navigateToTournamentDetails(tournament),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTournament,
        tooltip: 'Add Tournament',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
