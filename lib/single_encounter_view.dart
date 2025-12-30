import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/player_tile.dart';

import 'data/player.dart';
import 'data/round.dart';

class SingleEncounterView extends StatelessWidget {
  final Round round;
  final Encounter encounter;
  final Tournament tournament;
  final VoidCallback updateParent;

  const SingleEncounterView({
    super.key,
    required this.round,
    required this.encounter,
    required this.tournament,
    required this.updateParent,
  });

  @override
  Widget build(BuildContext context) {
    final index = round.encounters.indexOf(encounter);
    final playerW = encounter.playerIdW == -1
        ? Player.bye
        : tournament.players[encounter.playerIdW];
    final playerB = encounter.playerIdB == -1
        ? Player.bye
        : tournament.players[encounter.playerIdB];
    var pointsW = tournament.getPoints(
      encounter.playerIdW,
      tournament.rounds.indexOf(round),
    );
    var pointsB = tournament.getPoints(
      encounter.playerIdB,
      tournament.rounds.indexOf(round),
    );

    return Material(
      color: encounter.result.isNotEmpty
          ? Theme.of(context).colorScheme.primary.withAlpha(10)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _showResultDialog(encounter, context),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 30,
              child: Text(
                '#${index + 1}',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(160),
                ),
              ),
            ),
            Expanded(
              child: PlayerTile(
                player: playerW,
                points: pointsW,
                index: encounter.playerIdW,
              ),
            ),
            SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  encounter.result.isEmpty
                      ? 'vs'
                      : encounter.result.replaceAll('0.5', '\u{00BD}'),
                ),
              ),
            ),
            Expanded(
              child: PlayerTile(
                player: playerB,
                points: pointsB,
                index: encounter.playerIdB,
                alignLeft: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(Encounter encounter, BuildContext context) {
    String? selectedResult =
        ["1-0", "0-1", "0.5-0.5"].contains(encounter.result)
        ? encounter.result
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Result'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter result for ${tournament.players[encounter.playerIdW].name} vs ${tournament.players[encounter.playerIdB].name}",
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedResult,
                    hint: const Text("Select result"),
                    items: const [
                      DropdownMenuItem(value: "1-0", child: Text("1-0")),
                      DropdownMenuItem(value: "0-1", child: Text("0-1")),
                      DropdownMenuItem(
                        value: "0.5-0.5",
                        child: Text("0.5-0.5"),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedResult = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    encounter.result = selectedResult!;
                    tournament.update();
                    Navigator.of(context).pop();
                    updateParent();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
