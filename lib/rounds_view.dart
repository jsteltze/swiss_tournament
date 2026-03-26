import 'package:flutter/material.dart';
import 'package:swiss_tournament/components/warning.dart';
import 'package:swiss_tournament/dialogs/main_dialogs.dart';
import 'package:swiss_tournament/encounters_view.dart';
import 'package:swiss_tournament/utils/logger.dart';

import 'components/no_data_tile.dart';
import 'data/encounter.dart';
import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'dialogs/dialog_utils.dart';
import 'utils/javafo_utils.dart';

// stores ExpansionPanel state information
class RoundsPanel {
  RoundsPanel({
    required this.expandedValue,
    required this.headerValue,
    required this.headerIcon,
    this.isExpanded = false,
  });

  Widget expandedValue;
  String headerValue;
  Icon headerIcon;
  bool isExpanded;
}

RoundsPanel generateItem(
  Tournament tournament,
  int index,
  VoidCallback? updateParent,
  VoidCallback? deleteRound,
) {
  int numberOfItems = tournament.rounds.length;
  return RoundsPanel(
    headerValue: 'Round ${index + 1}',
    headerIcon:
        index == numberOfItems - 1 &&
            tournament.rounds[index].encounters.any((e) => e.result.isEmpty)
        ? const Icon(Icons.change_circle)
        : const Icon(Icons.check_circle),
    expandedValue: EncountersView(
      tournament: tournament,
      roundIndex: index,
      notifyRoundFinished: updateParent,
      deleteRound: deleteRound,
    ),
    isExpanded: index == numberOfItems - 1,
  );
}

class RoundsView extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback? onTournamentFinished;
  final VoidCallback? onRoundUpdate;

  const RoundsView({
    super.key,
    required this.tournament,
    this.onTournamentFinished,
    this.onRoundUpdate,
  });

  @override
  State<RoundsView> createState() => _RoundsViewState();
}

class _RoundsViewState extends State<RoundsView> {
  final List<RoundsPanel> _data = [];
  final TournamentStorage _storage = TournamentStorage();
  bool _isLoadingNewRound = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.tournament.rounds.length; i++) {
      _data.add(
        generateItem(
          widget.tournament,
          i,
          _finishLastRound,
          () => _deleteRound(i),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.tournament.players.isEmpty
        ? NoDataTile(
            text: 'First add some players to the tournament.',
            icon: Icons.list,
          )
        : SingleChildScrollView(child: Container(child: _buildPanel()));
  }

  Widget _buildPanel() {
    return Column(
      children: [
        ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _data[index].isExpanded = isExpanded;
            });
          },
          children: _data.map<ExpansionPanel>((RoundsPanel item) {
            return ExpansionPanel(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text(item.headerValue),
                  leading: item.headerIcon,
                  //tileColor: Theme.of(context).colorScheme.secondaryContainer,
                );
              },
              body: item.expandedValue,
              isExpanded: item.isExpanded,
            );
          }).toList(),
        ),
        if (_data.length < widget.tournament.numberOfRounds)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: _isLoadingNewRound
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'Start Round ${widget.tournament.rounds.length + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              onPressed: _isLoadingNewRound ? null : _startNewRound,
            ),
          ),
      ],
    );
  }

  void notifyUnfinishedEncounters(List<Encounter> encounters) {
    var unfinished = encounters.where((e) => e.result.isEmpty).toList();

    openDialog(
      context,
      title: 'Missing results',
      titleIcon: Icon(Icons.link_off_sharp),
      child: (ctx, setDialogState) => ListBody(
        children: <Widget>[
          const Warning(
            'Cannot proceed to the next round because there are missing results:',
          ),
          const SizedBox(height: 10),
          ...unfinished.map(
            (e) => Text(
              ' - ${widget.tournament.players[e.playerIdW].name} vs ${widget.tournament.players[e.playerIdB].name}',
            ),
          ),
        ],
      ),
      closeButtonTitle: 'OK',
    );
  }

  void notifyTournamentFinished() {
    openDialog(
      context,
      title: 'Tournament finished',
      titleIcon: Icon(Icons.emoji_events_outlined),
      child: (ctx, setDialogState) => const Text(
        'Congratulations!\nThe tournament is finished.\n\nYou can now view the ranking.',
      ),
      closeButtonTitle: 'Close',
      mainAction: DialogAction(
        title: 'Go to ranking',
        onPressed: () => {
          Navigator.pop(context),
          widget.onTournamentFinished?.call(),
        },
      ),
    );
  }

  void notifyNotEnoughPlayers() {
    openDialog(
      context,
      title: 'Not enough players',
      titleIcon: Icon(Icons.error_outline),
      child: (ctx, setDialogState) => const Warning(
        'The number of (active) players is less or equal than the number of rounds.\nA Swiss tournament is not advisable for this conditions.\n\nIf the number of players is relatively small think about different tournament modes (like Round-Robin). Otherwise add more players or reduce the number of rounds.',
      ),
      closeButtonTitle: 'Close',
    );
  }

  void _startNewRound() async {
    setState(() {
      _isLoadingNewRound = true;
    });
    var currentDbState = await _storage.getTournament(widget.tournament.id!);
    if (currentDbState == null) {
      FileLogger.log('Error: Tournament not found in database!');
      setState(() {
        _isLoadingNewRound = false;
      });
      return;
    }
    if (currentDbState.rounds.isNotEmpty &&
        currentDbState.rounds.last.encounters.any((e) => e.result.isEmpty)) {
      FileLogger.log('Cannot start new round: some encounters are unfinished.');
      notifyUnfinishedEncounters(currentDbState.rounds.last.encounters);
      setState(() {
        _isLoadingNewRound = false;
      });
      return;
    }
    if (currentDbState.numberOfRounds >= currentDbState.players.length) {
      FileLogger.log('notify: not enough players');
      notifyNotEnoughPlayers();
      setState(() {
        _isLoadingNewRound = false;
      });
      return;
    }
    FileLogger.log(
      'Starting new round for tournament ID: ${widget.tournament.id}',
    );
    try {
      var round = callJavaFo(widget.tournament);
      widget.tournament.rounds.add(round);
      widget.tournament.update();
      setState(() {
        for (var item in _data) {
          item.isExpanded = false;
        }
        _data.add(
          generateItem(
            widget.tournament,
            widget.tournament.rounds.length - 1,
            _finishLastRound,
            () => _deleteRound(widget.tournament.rounds.length - 1),
          ),
        );
      });
      widget.onRoundUpdate?.call();
    } catch (ex) {
      if (mounted) {
        showErrorDialog(context, ex.toString());
      }
    } finally {
      setState(() {
        _isLoadingNewRound = false;
      });
    }
  }

  void _deleteRound(int roundIndex) {
    openDialog(
      context,
      title: 'Delete round',
      titleIcon: Icon(Icons.delete),
      child: (ctx, setDialogState) =>
          roundIndex == widget.tournament.rounds.length - 1
          ? Text('Are you sure you want to delete round ${roundIndex + 1}?')
          : Warning('Only the last round can be deleted!'),
      mainAction: DialogAction(
        title: 'Delete',
        isDestructive: true,
        onPressed: roundIndex == widget.tournament.rounds.length - 1
            ? () {
                FileLogger.log(
                  'Deleting round ${roundIndex + 1} from tournament ${widget.tournament.id}',
                );
                widget.tournament.rounds.removeLast();
                widget.tournament.update();
                setState(() {
                  _data.removeLast();
                });
                Navigator.pop(context);
                widget.onRoundUpdate?.call();
              }
            : null,
      ),
    );
  }

  void _finishLastRound() {
    FileLogger.log(
      'Finishing last round of tournament ${widget.tournament.id}',
    );
    setState(() {
      _data.last.headerIcon = Icon(Icons.check_circle);
      widget.tournament.rounds.last.finishedAt = DateTime.now();
      widget.tournament.update();
    });
    if (widget.tournament.rounds.length == widget.tournament.numberOfRounds) {
      FileLogger.log('Tournament ${widget.tournament.id} finished!');
      Future.delayed(const Duration(seconds: 1), () {
        notifyTournamentFinished();
      });
    }
  }
}
