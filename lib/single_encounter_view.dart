import 'package:flutter/material.dart';
import 'package:swiss_tournament/components/info_panel.dart';
import 'package:swiss_tournament/components/player_tile.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/dialogs/main_dialogs.dart';

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
    final playerW = encounter.playerIdW < 0
        ? Player.bye
        : tournament.players[encounter.playerIdW];
    final playerB = encounter.playerIdB < 0
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
        color: encounter.result.isNotEmpty
            ? Theme.of(context).colorScheme.primary.withAlpha(20)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: () => _showResultDialog(encounter, context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
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
                  width: MediaQuery.of(context).textScaler.scale(50.0),
                  height: MediaQuery.of(context).textScaler.scale(50.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        MediaQuery.of(context).textScaler.scale(50.0),
                      ),
                    ),
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
    final possibleResults1 = ["1-0", "0.5-0.5", "0-1"];
    final possibleResults2 = ["+ -", "- +"];
    if (encounter.playerIdW < 0 || encounter.playerIdB < 0) {
      String reason = encounter.playerIdW == -1 || encounter.playerIdB == -1
          ? 'Reason: The player (currently last place in the standings) is granted a full point due to an odd number of players in this round.'
          : 'Reason: The player has chosen to request a voluntary half-point bye.';
      openDialog(
        context,
        title: 'Bye information',
        titleIcon: Icon(Icons.safety_divider),
        child: (ctx, setDialogState, toggleMainAction) => Column(
          children: [
            InfoPanel(
              Text('This is an automatic result that cannot be changed.'),
            ),
            Text(reason),
          ],
        ),
        closeButtonTitle: 'Close',
      );
      return;
    }

    String? selectedResult = encounter.result;
    final selectedResultsBool1 = possibleResults1
        .map((p) => p == encounter.result)
        .toList();
    final selectedResultsBool2 = possibleResults2
        .map((p) => p == encounter.result)
        .toList();

    openDialog(
      context,
      title: 'Select Result',
      titleIcon: Icon(Icons.safety_divider),
      child: (ctx, setDialogState, toggleMainAction) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints.expand(),
                        padding: EdgeInsets.only(
                          left: 10,
                          top: 10,
                          bottom: 10,
                          right: 25,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(40),
                          ),
                          color: Theme.of(context).colorScheme.surfaceBright,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tournament.players[encounter.playerIdW].name,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints.expand(),
                        padding: EdgeInsets.only(
                          left: 25,
                          top: 10,
                          bottom: 10,
                          right: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(40),
                          ),
                          color: Theme.of(context).colorScheme.surfaceDim,
                        ),
                        alignment: Alignment.centerRight,
                        child: Text(
                          tournament.players[encounter.playerIdB].name,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(40),
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'vs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 1,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 1),
                      padding: EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minHeight: 50.0,
                        minWidth: 80.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                        color: Theme.of(context).colorScheme.surfaceBright,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '1-0',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.transparent,
                                ),
                          ),
                          Text(
                            'white win',
                            style: TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 1),
                      padding: EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minHeight: 50.0,
                        minWidth: 80.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surfaceBright,
                            Theme.of(context).colorScheme.surfaceDim,
                          ],
                          begin: const FractionalOffset(0.2, 0.0),
                          end: const FractionalOffset(0.8, 0.0),
                          stops: [0.0, 1.0],
                          tileMode: TileMode.clamp,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '\u{00BD} - \u{00BD}',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.transparent,
                                ),
                          ),
                          Text(
                            'draw',
                            style: TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 1),
                      padding: EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minHeight: 50.0,
                        minWidth: 80.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                        color: Theme.of(context).colorScheme.surfaceDim,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '0-1',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.transparent,
                                ),
                          ),
                          Text(
                            'black win',
                            style: TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ToggleButtons(
                  onPressed: (int? newValue) {
                    setDialogState(() {
                      // The button that is tapped is set to true, and the others to false.
                      for (int i = 0; i < selectedResultsBool1.length; i++) {
                        selectedResultsBool1[i] = i == newValue;
                      }
                      selectedResult = possibleResults1[newValue!];
                      selectedResultsBool2.fillRange(
                        0,
                        selectedResultsBool2.length,
                        false,
                      );
                      toggleMainAction(true);
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Theme.of(context).colorScheme.primary,
                  color: Theme.of(context).colorScheme.primary,
                  constraints: const BoxConstraints(
                    minHeight: 50.0,
                    minWidth: 80.0,
                  ),
                  isSelected: selectedResultsBool1,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        children: [
                          Text(
                            '1-0',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('white win'),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        children: [
                          Text(
                            '\u{00BD} - \u{00BD}',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('draw'),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        children: [
                          Text(
                            '0-1',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('black win'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 1,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 1),
                      padding: EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minHeight: 50.0,
                        minWidth: 120.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                        color: Theme.of(context).colorScheme.surfaceBright,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '+ -',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.transparent,
                                ),
                          ),
                          Text(
                            'black missing',
                            style: TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 1),
                      padding: EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minHeight: 50.0,
                        minWidth: 120.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                        color: Theme.of(context).colorScheme.surfaceDim,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '- +',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.transparent,
                                ),
                          ),
                          Text(
                            'white missing',
                            style: TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ToggleButtons(
                  onPressed: (int? newValue) {
                    setDialogState(() {
                      // The button that is tapped is set to true, and the others to false.
                      for (int i = 0; i < selectedResultsBool2.length; i++) {
                        selectedResultsBool2[i] = i == newValue;
                      }
                      selectedResult = possibleResults2[newValue!];
                      selectedResultsBool1.fillRange(
                        0,
                        selectedResultsBool1.length,
                        false,
                      );
                      toggleMainAction(true);
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Theme.of(context).colorScheme.primary,
                  color: Theme.of(context).colorScheme.primary,
                  constraints: const BoxConstraints(
                    minHeight: 50.0,
                    minWidth: 120.0,
                  ),
                  isSelected: selectedResultsBool2,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        children: [
                          Text(
                            '+ -',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('black missing'),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        children: [
                          Text(
                            '- +',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('white missing'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      mainActionEnabled: false,
      mainAction: DialogAction(
        title: 'Save',
        onPressed: () {
          if (selectedResult == null || selectedResult!.isEmpty) {
            showErrorDialog(context, 'No result selected!');
            return;
          }
          encounter.result = selectedResult!;
          tournament.update();
          Navigator.of(context).pop();
          updateParent();
        },
      ),
    );
  }
}
