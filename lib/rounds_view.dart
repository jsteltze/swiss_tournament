import 'package:flutter/material.dart';
import 'package:swiss_tournament/encounters_view.dart';

import 'data/encounter.dart';
import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'javafo_utils.dart';

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
    ),
    isExpanded: index == numberOfItems - 1,
  );
}

class RoundsView extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback? onTournamentFinished;

  const RoundsView({
    super.key,
    required this.tournament,
    this.onTournamentFinished,
  });

  @override
  State<RoundsView> createState() => _RoundsViewState();
}

class _RoundsViewState extends State<RoundsView> {
  final List<RoundsPanel> _data = [];
  final TournamentStorage _storage = TournamentStorage();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.tournament.rounds.length; i++) {
      _data.add(generateItem(widget.tournament, i, _finishLastRound));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Container(child: _buildPanel()));
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
        if (_data.length < widget.tournament.rounds.length)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(
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
              onPressed: _startNewRound,
            ),
          ),
      ],
    );
  }

  void notifyUnfinishedEncounters(List<Encounter> encounters) {
    var unfinished = encounters.where((e) => e.result.isEmpty).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Missing results'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Cannot proceed to the next round because there are missing results:',
                ),
                const SizedBox(height: 10),
                ...unfinished.map(
                  (e) => Text(
                    '${widget.tournament.players[e.playerIdW].name} vs ${widget.tournament.players[e.playerIdB].name}',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void notifyTournamentFinished() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tournament finished'),
          content: const Text(
            'Congratulations!\nThe tournament is finished.\n\nYou can now view the ranking.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => {
                Navigator.pop(context),
                widget.onTournamentFinished?.call(),
              },
              child: const Text('Go to ranking'),
            ),
          ],
        );
      },
    );
  }

  void _startNewRound() async {
    var currentDbState = await _storage.getTournament(widget.tournament.id!);
    if (currentDbState == null) {
      print('no such tournament found!');
      return;
    }
    if (currentDbState.rounds.isNotEmpty &&
        currentDbState.rounds.last.encounters.any((e) => e.result.isEmpty)) {
      notifyUnfinishedEncounters(currentDbState.rounds.last.encounters);
      return;
    }

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
        ),
      );
    });
  }

  void _finishLastRound() {
    setState(() {
      _data.last.headerIcon = Icon(Icons.check_circle);
      widget.tournament.rounds.last.finishedAt = DateTime.now();
      widget.tournament.update();
    });
    if (widget.tournament.rounds.length == widget.tournament.numberOfRounds) {
      Future.delayed(const Duration(seconds: 1), () {
        notifyTournamentFinished();
      });
    }
  }
}
