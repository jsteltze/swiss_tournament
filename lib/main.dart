import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:js_flutter/components/app_layout.dart';
import 'package:js_flutter/components/floating_action_button.dart';
import 'package:js_flutter/components/list.dart';
import 'package:js_flutter/components/no_data_tile.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:js_flutter/utils/first_time.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:js_flutter/utils/snackbar_utils.dart';
import 'package:material_ui/material_ui.dart' hide DismissAction;
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
  bool _isLoading = true;
  TournamentFilter _filter = .all;
  final GlobalKey<MyListState<Tournament>> list =
      GlobalKey<MyListState<Tournament>>();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkFirstTime(
        () => showWelcomeDialog(
          context,
          'Thank you for using the Chess Swiss Tournament App!\n\nThis app helps you manage chess tournaments using the Swiss system. All data is stored locally on your device.\n\nPlease note that this is not FIDE-approved software.',
        ),
      );
    });
  }

  List<Tournament> get _filtered {
    if (_filter == .inProgress) {
      return _tournaments.where((t) => !t.isFinished()).toList();
    } else if (_filter == .finished) {
      return _tournaments.where((t) => t.isFinished()).toList();
    } else {
      return _tournaments.toList();
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
        list.currentState?.insert(tournament);
        _tournaments.insert(0, tournament);
      });
      tournament.update = () => widget._storage.updateTournament(tournament);
      tournament.update();
      _navigateToTournamentDetails(tournament);
    });
  }

  void _deleteTournament(Tournament tournament, {DismissDirection? dismiss}) {
    FileLogger.log('Deleting tournament: ${tournament.title}');

    list.currentState?.remove(tournament, dismiss: dismiss);
    setState(() {
      _tournaments.remove(tournament);
      _saveTournaments();
    });
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
    final noDataFiltered = NoDataTile(
      text: 'No tournaments match the selected filters.',
      icon: Icons.filter_alt_off,
      actionButton: DialogAction(
        title: 'Clear Filters',
        onPressed: (_) {
          setState(() {
            _filter = .all;
            list.currentState?.doFiltering(_filtered);
          });
        },
      ),
    );

    return createScaffold(
      context: context,
      actions: [
        createPopupMenu([
          DialogAction(
            title: 'Import',
            icon: Icons.file_upload,
            onPressed: (_) => _importTournaments(),
          ),
          DialogAction(
            title: 'Export',
            icon: exportIcon,
            onPressed: (_) => showExportDialog(context, _tournaments),
          ),
          DialogAction(
            title: 'View Logs',
            icon: Icons.list_alt,
            onPressed: (_) => showLogsDialog(context),
          ),
          DialogAction(
            title: 'App Info',
            icon: Icons.info_outline,
            onPressed: (_) => showAppInfoDialog(context, widget._storage),
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
                TournamentsViewHeader(_tournaments, _filter, (filter) {
                  setState(() {
                    _filter = filter;
                    list.currentState?.doFiltering(_filtered);
                  });
                }),
                Expanded(
                  child: MyList<Tournament>(
                    key: list,
                    initialItems: _tournaments,
                    itemBuilder: (t, animation) => TournamentCard(
                      animation: animation,
                      tournament: t,
                      storage: widget._storage,
                      onEdit: (_) {
                        _loadTournaments();
                      },
                      onDelete: () {
                        _deleteTournament(t);
                      },
                      onUpdate: _loadTournaments,
                      onTap: _navigateToTournamentDetails,
                    ),
                    onDismissedPrimary: DismissAction(
                      title: 'delete',
                      isDestructive: true,
                      icon: deleteIcon,
                      confirmDismiss: (item) =>
                          confirmDeleteTournament(context, item),
                      onDismissed: (item) =>
                          _deleteTournament(item, dismiss: .startToEnd),
                    ),
                    noDataTile: noDataFiltered,
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
