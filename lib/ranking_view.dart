import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/player_ratings.dart';

import 'data/tournament.dart';

class RankingView extends StatelessWidget {
  final Tournament tournament;

  const RankingView({super.key, required this.tournament});

  int _comparePlayers(PlayerRatings a, PlayerRatings b) {
    var comparePoints = b.points!.compareTo(a.points!);
    if (comparePoints != 0) {
      return comparePoints;
    }
    var compareBuchholz = b.buchholz!.compareTo(a.buchholz!);
    if (compareBuchholz != 0) {
      return compareBuchholz;
    }

    a.sharedPlace = true;
    b.sharedPlace = true;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final lastRoundNum = tournament.rounds.length;
    final lastRoundFinished = tournament.rounds.last.encounters.every(
      (e) => e.result.isNotEmpty,
    );
    final ratings = tournament.players
        .map(
          (p) => PlayerRatings(
            player: p,
            startIndex: tournament.players.indexOf(p),
          ),
        )
        .toList();
    for (int r = 0; r < ratings.length; r++) {
      ratings[r].points = tournament.getPoints(ratings[r].startIndex, 99);
      ratings[r].buchholz = tournament.getBuchholz(ratings[r].startIndex);
      ratings[r].wins = tournament.getWins(ratings[r].startIndex);
      ratings[r].losses = tournament.getLosses(ratings[r].startIndex);
      ratings[r].draws = tournament.getDraws(ratings[r].startIndex);
    }
    ratings.sort(_comparePlayers);
    for (int r = 0; r < ratings.length; r++) {
      if (ratings[r].rank == null) {
        ratings[r].rank = r + 1;
      }
      if (ratings[r].sharedPlace) {
        for (int i = r + 1; i < ratings.length; i++) {
          if (ratings[i].sharedPlace) {
            ratings[i].rank = ratings[r].rank;
          } else {
            break;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          color: Theme.of(context).colorScheme.secondaryContainer,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            spacing: 15,
            children: [
              Icon(
                Icons.leaderboard,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ranking',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '(${lastRoundFinished ? 'after' : 'currently running'} round $lastRoundNum)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            child: DataTable(
              columnSpacing: 8.0,
              horizontalMargin: 2,
              columns: [
                DataColumn(
                  label: Text('#'),
                  headingRowAlignment: MainAxisAlignment.end,
                ),
                DataColumn(label: Text('Name')),
                DataColumn(
                  numeric: true,
                  label: RotatedBox(quarterTurns: 3, child: Text('Startrank')),
                ),
                DataColumn(
                  label: RotatedBox(quarterTurns: 3, child: Text('Rating')),
                  numeric: true,
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  label: RotatedBox(quarterTurns: 3, child: Text('Games')),
                  numeric: true,
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  label: Text('W/D/L'),
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  numeric: true,
                  label: RotatedBox(quarterTurns: 3, child: Text('Points')),
                ),
                DataColumn(
                  numeric: true,
                  label: RotatedBox(quarterTurns: 3, child: Text('Buchholz')),
                ),
              ],
              rows: ratings
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              if (r.rank == 1)
                                Icon(Icons.emoji_events, color: Colors.yellow),
                              if (r.rank == 2)
                                Icon(Icons.emoji_events, color: Colors.black12),
                              if (r.rank == 3)
                                Icon(Icons.emoji_events, color: Colors.amber),
                              Expanded(
                                child: Text(
                                  r.rank.toString(),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(r.player.name)),
                        DataCell(
                          Text('${r.startIndex + 1}', textAlign: TextAlign.end),
                        ),
                        DataCell(
                          Text(
                            r.player.rating == 0
                                ? 'N/A'
                                : r.player.rating.toString(),
                          ),
                        ),
                        DataCell(
                          Text((r.wins! + r.losses! + r.draws!).toString()),
                        ),
                        DataCell(Text('${r.wins}/${r.draws}/${r.losses}')),
                        DataCell(Text(r.points!.toStringAsFixed(1))),
                        DataCell(Text(r.buchholz!.toStringAsFixed(1))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
