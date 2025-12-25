import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/round.dart';

import 'data/tournament.dart';
import 'encounters_view.dart';
import 'java.g.dart';

class SingleRound extends StatefulWidget {
  const SingleRound({
    super.key,
    required this.tournament,
    required this.roundIndex,
    this.onTournamentChanged,
  });

  final Tournament tournament;
  final int roundIndex;
  final VoidCallback? onTournamentChanged;

  @override
  State<SingleRound> createState() => _SingleRoundState();
}

class _SingleRoundState extends State<SingleRound> {
  bool _roundStarted = false;

  @override
  Widget build(BuildContext context) {
    setState(() {
      _roundStarted = widget.tournament.rounds.length > widget.roundIndex;
    });
    var playerRatings = widget.tournament.players
        .map((player) => player.rating)
        .toList();
    JIntArray arr = JIntArray(playerRatings.length);
    arr.setRange(0, playerRatings.length, playerRatings);

    return _roundStarted
        ? EncountersView(
            tournament: widget.tournament,
            roundIndex: widget.roundIndex,
          )
        : ElevatedButton.icon(
            onPressed: () {
              var response = Sample.initTournament(
                Jni.androidActivity(PlatformDispatcher.instance.engineId!),
                JString.fromString("xxx"),
                arr,
                widget.tournament.numberOfRounds,
              );
              parseResponse(response!);
              widget.onTournamentChanged?.call();
              setState(() {
                _roundStarted = true;
              });
            },
            icon: Icon(Icons.play_arrow),
            label: Text('Start Round ${widget.roundIndex + 1}'),
          );
  }

  void parseResponse(JString response) {
    var respStr = response.toDartString();
    print(respStr);
    var lines = respStr.split('\n');
    var round = Round(roundNum: widget.roundIndex + 1);
    for (var i = 1; i < lines.length; i++) {
      var line = lines[i];
      if (line.isEmpty) {
        continue;
      }
      print('line=$line');
      var parts = line.split(' ');
      round.encounters.add(
        Encounter(
          playerIdW: int.parse(parts[0]) - 1,
          playerIdB: int.parse(parts[1]) - 1,
        ),
      );
    }
    response.release();
    widget.tournament.rounds.add(round);
  }
}
