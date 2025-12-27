import 'package:flutter/material.dart';

import 'data/tournament.dart';
import 'encounters_view.dart';

class SingleRound extends StatefulWidget {
  const SingleRound({
    super.key,
    required this.tournament,
    required this.roundIndex,
    required this.updateParent,
  });

  final Tournament tournament;
  final int roundIndex;
  final updateParent;

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

    return EncountersView(
      tournament: widget.tournament,
      roundIndex: widget.roundIndex,
    );
  }
}
