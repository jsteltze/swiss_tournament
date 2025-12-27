import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/tournament.dart';

import 'single_encounter_view.dart';

class EncountersView extends StatelessWidget {
  final Tournament tournament;
  final int roundIndex;

  const EncountersView({
    super.key,
    required this.tournament,
    required this.roundIndex,
  });

  @override
  Widget build(BuildContext context) {
    var encounters = tournament.rounds[roundIndex].encounters;
    var pairings = encounters.length;
    var open = encounters.where((e) => e.result == "").length;

    return Column(
      children: [
        Text("Pairings: ${pairings - open}/$pairings"),
        ...encounters.map(
          (encounter) =>
              SingleEncounterView(encounter: encounter, tournament: tournament),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.play_arrow),
          label: Text('Start Round ${roundIndex + 2}'),
          onPressed: encounters.every((e) => e.result.isNotEmpty)
              ? () => {}
              : null,
        ),
      ],
    );
  }
}
