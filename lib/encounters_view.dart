import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/tournament.dart';

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
    var pairings = tournament.rounds[roundIndex].encounters.length;
    var open = tournament.rounds[roundIndex].encounters
        .where((e) => e.result == "")
        .toList()
        .length;
    return Column(
      children: [
        Text("Pairings: ${pairings - open}/$pairings"),
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(),
            1: FixedColumnWidth(50),
            2: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: tournament.rounds[roundIndex].encounters
              .map<TableRow>(
                (encounter) => TableRow(
                  children: <Widget>[
                    ListTile(
                      title: Text(tournament.players[encounter.playerIdW].name),
                      subtitle: Text(
                        '#${encounter.playerIdW + 1} Rating: ${tournament.players[encounter.playerIdW].rating}',
                      ),
                      leading: const Icon(Icons.person),
                    ),
                    Center(child: Text('vs')),
                    ListTile(
                      title: Text(tournament.players[encounter.playerIdB].name),
                      subtitle: Text(
                        '#${encounter.playerIdB + 1} Rating: ${tournament.players[encounter.playerIdB].rating}',
                      ),
                      trailing: const Icon(Icons.person),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
