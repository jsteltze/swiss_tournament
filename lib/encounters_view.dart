import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/tournament.dart';

import 'single_encounter_view.dart';

class EncountersView extends StatefulWidget {
  final Tournament tournament;
  final int roundIndex;

  const EncountersView({
    super.key,
    required this.tournament,
    required this.roundIndex,
  });

  @override
  State<EncountersView> createState() => _EncountersViewState();
}

class _EncountersViewState extends State<EncountersView> {
  @override
  Widget build(BuildContext context) {
    var encounters = widget.tournament.rounds[widget.roundIndex].encounters;
    var pairings = encounters.length;
    var open = encounters.where((e) => e.result == "").length;

    return Column(
      children: [
        Text("Pairings: ${pairings - open}/$pairings"),
        ...encounters.map(
          (encounter) => SingleEncounterView(
            encounter: encounter,
            tournament: widget.tournament,
            updateParent: () => setState(() {}),
          ),
        ),
      ],
    );
  }
}
