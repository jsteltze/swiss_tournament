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
    var compareSoBerg = b.soBerg!.compareTo(a.soBerg!);
    if (compareSoBerg != 0) {
      return compareSoBerg;
    }

    a.sharedPlace =
        a.points!.toString() + a.buchholz!.toString() + a.soBerg!.toString();
    b.sharedPlace = a.sharedPlace;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    print('ranking view');
    final lastRoundNum = tournament.rounds.length;
    final headerHeight = 75.0;
    if (lastRoundNum == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              'Tournament has not started yet.',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    final lastRoundFinished = tournament.rounds.last.encounters.every(
      (e) => e.result.isNotEmpty,
    );
    final ratings = tournament.players
        .map(
          (p) =>
              PlayerRatings(player: p, playerId: tournament.players.indexOf(p)),
        )
        .toList();
    for (int r = 0; r < ratings.length; r++) {
      ratings[r].calculateRatings(tournament.rounds);
    }
    ratings.sort(_comparePlayers);
    for (int r = 0; r < ratings.length; r++) {
      if (ratings[r].rank == null) {
        ratings[r].rank = r + 1;
      }
      if (ratings[r].sharedPlace.isNotEmpty) {
        final sharedPlaceInfo = ratings[r].sharedPlace;
        for (int i = r + 1; i < ratings.length; i++) {
          if (ratings[i].sharedPlace == sharedPlaceInfo) {
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
              headingRowHeight: headerHeight,
              columns: [
                DataColumn(
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomRight,
                    child: Text('#'),
                  ),
                  headingRowAlignment: MainAxisAlignment.end,
                ),
                DataColumn(
                  label: Container(
                    height: 75,
                    alignment: Alignment.bottomLeft,
                    child: Text('Name'),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomRight,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(' Startrank'),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomRight,
                    child: RotatedBox(quarterTurns: 3, child: Text(' Rating')),
                  ),
                  numeric: true,
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomRight,
                    child: RotatedBox(quarterTurns: 3, child: Text(' Games')),
                  ),
                  numeric: true,
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomCenter,
                    child: Text('W/D/L'),
                  ),
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  numeric: true,
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomRight,
                    child: RotatedBox(quarterTurns: 3, child: Text(' Points')),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Container(
                    height: headerHeight,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        ' Tiebreak 1\n Buchholz',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomRight,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        ' Tiebreak 2\n SoBerg',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            r.player.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              '${r.playerId + 1}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              r.player.rating == 0
                                  ? 'N/A'
                                  : r.player.rating.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              (r.wins! + r.losses! + r.draws!).toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${r.wins}/${r.draws}/${r.losses}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              r.points!.toStringAsFixed(1),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              r.buchholz!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              r.soBerg!.toStringAsFixed(2),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
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
