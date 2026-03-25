import 'package:flutter/material.dart';
import 'package:swiss_tournament/components/info_panel.dart';
import 'package:swiss_tournament/components/player_tile.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/tournament.dart';

import 'data/player.dart';
import 'data/player_ratings.dart';
import 'data/round.dart';
import 'dialogs/dialog_utils.dart';

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
    var pointsW = PlayerRatings.getPoints(
      tournament.rounds,
      encounter.playerIdW,
      tournament.rounds.indexOf(round),
    );
    var pointsB = PlayerRatings.getPoints(
      tournament.rounds,
      encounter.playerIdB,
      tournament.rounds.indexOf(round),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(40),
        ),
        borderRadius: BorderRadius.circular(10),
        color: encounter.result.isNotEmpty
            ? Theme.of(context).colorScheme.primary.withAlpha(20)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: encounter.playerIdW == -1 || encounter.playerIdB == -1
            ? null
            : () => _showResultDialog(encounter, context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
                color: Theme.of(context).colorScheme.primary.withAlpha(
                  encounter.result.isEmpty ? 20 : 0,
                ),
              ),
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                '#${index + 1}',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(160),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: PlayerTile(
                    player: playerW,
                    points: pointsW,
                    index: encounter.playerIdW,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                    color: encounter.result.isEmpty
                        ? Colors.transparent
                        : Theme.of(context).focusColor,
                  ),

                  child: Center(
                    child: Text(
                      encounter.result.isEmpty
                          ? 'vs'
                          : encounter.result.replaceAll('0.5', '\u{00BD}'),
                      style: TextStyle(
                        fontSize: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.fontSize,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
          ],
        ),
      ),
    );
  }

  void _showResultDialog(Encounter encounter, BuildContext context) {
    String? selectedResult =
        ["1-0", "0-1", "0.5-0.5", "+ -", "- +"].contains(encounter.result)
        ? encounter.result
        : null;

    openDialog(
      context,
      title: 'Select Result',
      titleIcon: Icon(Icons.safety_divider),
      child: (ctx, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter result for:"),
          InfoPanel(
            Text(
              "${tournament.players[encounter.playerIdW].name} vs ${tournament.players[encounter.playerIdB].name}",
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            isExpanded: true,
            value: selectedResult,
            hint: const Text("Select result"),
            items: [
              DropdownMenuItem(
                value: "1-0",
                child: Row(
                  children: [
                    Expanded(child: Text("1-0")),
                    Text(
                      "(white win)",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "0-1",
                child: Row(
                  children: [
                    Expanded(child: Text("0-1")),
                    Text(
                      "(black win)",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "0.5-0.5",
                child: Row(
                  children: [
                    Expanded(child: Text("\u{00BD}-\u{00BD}")),
                    Text(
                      "(draw)",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "+ -",
                child: Row(
                  children: [
                    Expanded(child: Text("+ -")),
                    Text(
                      "(uncontested white)",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "- +",
                child: Row(
                  children: [
                    Expanded(child: Text("- +")),
                    Text(
                      "(uncontested black)",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
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
      mainAction: DialogAction(
        title: 'Save',
        onPressed: () {
          encounter.result = selectedResult!;
          tournament.update();
          Navigator.of(context).pop();
          updateParent();
        },
      ),
    );
  }
}
