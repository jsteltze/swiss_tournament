import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:js_flutter/components/app_layout.dart';
import 'package:js_flutter/components/floating_action_button.dart';
import 'package:js_flutter/components/no_data_tile.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:js_flutter/utils/snackbar_utils.dart';
import 'package:swiss_tournament/dialogs/main_dialogs.dart';
import 'package:swiss_tournament/dialogs/tournament_dialogs.dart';
import 'package:swiss_tournament/dialogs/tournament_popup_menu.dart';

import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'tournament_details_page.dart';

void main() async {
  initApp(MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
      PlatformFile? result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.path != null) {
        FileLogger.log('Importing from file: ${result.path}');
        final uint8List = await result.readAsBytes();
        final content = String.fromCharCodes(uint8List);
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
            result.path!.split('/').last,
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
    return createScaffold(
      context: context,
      actions: [
        createPopupMenu([
          DialogAction(
            title: 'Import',
            icon: Icons.file_upload,
            onPressed: _importTournaments,
          ),
          DialogAction(
            title: 'Export',
            icon: exportIcon,
            onPressed: () => showExportDialog(context, _tournaments),
          ),
          DialogAction(
            title: 'View Logs',
            icon: Icons.list_alt,
            onPressed: () => showLogsDialog(context),
          ),
          DialogAction(
            title: 'App Info',
            icon: Icons.info_outline,
            onPressed: () => showAppInfoDialog(context),
          ),
        ]),
      ],
      child: _tournaments.isEmpty
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
      floatingActionButton: createFAB(
        context,
        'Add Tournament',
        addIcon,
        _addTournament,
      ),
      isLoading: _isLoading,
    );
  }
}
