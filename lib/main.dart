import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:js_flutter/components/app_layout.dart';
import 'package:js_flutter/components/floating_action_button.dart';
import 'package:js_flutter/components/no_data_tile.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:js_flutter/utils/first_time.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:js_flutter/utils/snackbar_utils.dart';
import 'package:swiss_tournament/components/tournaments_view_header.dart';
import 'package:swiss_tournament/dialogs/main_dialogs.dart';
import 'package:swiss_tournament/dialogs/tournament_dialogs.dart';

import 'components/tournament_card.dart';
import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'data/tournament_storage_db.dart';
import 'tournament_details_page.dart';

void main() async {
  initApp(ChessTournamentApp());
}

class ChessTournamentApp extends StatefulWidget {
  final TournamentStorage _storage;

  ChessTournamentApp({TournamentStorage? storage, super.key})
    : _storage = storage ?? TournamentDB();

  @override
  State<ChessTournamentApp> createState() => _ChessTournamentAppState();
}

class _ChessTournamentAppState extends State<ChessTournamentApp> {
  List<Tournament> _tournaments = [];
  List<Tournament> _filteredTournaments = [];
  bool _isLoading = true;
  bool _filterNotFinished = false;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkFirstTime(
        () => showWelcomeDialog(
          context,
          Icons.emoji_events_outlined,
          'Thank you for using the Chess Swiss Tournament App!\n\nThis app helps you manage chess tournaments using the Swiss system. All data is stored locally on your device.\n\nPlease note that this is not FIDE-approved software.',
        ),
      );
    });
  }

  void _doFiltering() {
    if (_filterNotFinished) {
      _filteredTournaments = _tournaments
          .where((t) => !t.isFinished())
          .toList();
    } else {
      _filteredTournaments = _tournaments;
    }
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
    });
    FileLogger.log('Loading tournaments...');
    final tournaments = await widget._storage.loadTournaments();
    setState(() {
      _tournaments = tournaments;
      _isLoading = false;
      _doFiltering();
    });
    FileLogger.log('Loaded ${tournaments.length} tournaments');
  }

  Future<void> _saveTournaments() async {
    FileLogger.log('Saving all tournaments...');
    await widget._storage.saveTournaments(_tournaments);
  }

  void _addTournament() {
    showEditTournamentDialog(context, null, (tournament) {
      FileLogger.log('Adding tournament: ${tournament.title}');
      setState(() {
        _tournaments.insert(0, tournament);
        _doFiltering();
      });
      tournament.update = () => widget._storage.updateTournament(tournament);
      tournament.update();
      _navigateToTournamentDetails(tournament);
    });
  }

  void _deleteTournament(Tournament tournament) {
    FileLogger.log('Deleting tournament: ${tournament.title}');
    setState(() {
      _tournaments.remove(tournament);
      _doFiltering();
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
          storage: widget._storage,
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
            widget._storage,
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
            onPressed: () => showAppInfoDialog(context, widget._storage),
          ),
        ]),
      ],
      child: _tournaments.isEmpty
          ? NoDataTile(
              text: 'No tournaments added yet.',
              icon: Icons.emoji_events_outlined,
            )
          : Column(
              crossAxisAlignment: .start,
              children: [
                TournamentsViewHeader(_tournaments, _filterNotFinished, (
                  selected,
                ) {
                  setState(() {
                    _filterNotFinished = selected;
                    _doFiltering();
                  });
                }),
                Expanded(
                  child: _filteredTournaments.isEmpty
                      ? NoDataTile(
                          text: 'No tournaments in progress or started.',
                          icon: Icons.filter_alt_outlined,
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).textScaler.scale(80),
                          ),
                          itemCount: _filteredTournaments.length,
                          itemBuilder: (context, index) => TournamentCard(
                            tournament: _filteredTournaments[index],
                            storage: widget._storage,
                            onEdit: (tournament) {
                              _loadTournaments();
                            },
                            onDelete: () {
                              _deleteTournament(_filteredTournaments[index]);
                            },
                            onUpdate: _loadTournaments,
                            onTap: _navigateToTournamentDetails,
                          ),
                        ),
                ),
              ],
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
