import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _filterOpen = false;

  @override
  Widget build(BuildContext context) {
    var round = widget.tournament.rounds[widget.roundIndex];
    var encounters = round.encounters;
    var pairings = encounters.length;
    var open = encounters.where((e) => e.result == "").length;

    return Column(
      children: [
        Text(
          "Pairings: ${pairings - open}/$pairings",
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        LinearProgressIndicator(value: 1.0 - open / pairings, minHeight: 5),
        const SizedBox(height: 10),
        Text(
          "Started at: ${DateFormat().format(round.startedAt)}",
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          value: _filterOpen,
          title: Text('filter open ($open)'),
          onChanged: (checked) => {
            setState(() {
              _filterOpen = checked!;
            }),
          },
        ),
        ...encounters
            .where((e) => _filterOpen ? e.result == "" : true)
            .map(
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
