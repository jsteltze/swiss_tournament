import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/player_ratings.dart';
import 'package:swiss_tournament/data/tiebreak.dart';

import 'data/tournament.dart';

class RankingView extends StatelessWidget {
  final Tournament tournament;
  final Function onSettingsUpdate;

  const RankingView({
    super.key,
    required this.tournament,
    required this.onSettingsUpdate,
  });

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

  void applyTiebreak(Tiebreak tb1, Tiebreak tb2) {
    TournamentSettings s = TournamentSettings(tb1: tb1, tb2: tb2);
    onSettingsUpdate(s);
  }

  void _showSettingsDialog(BuildContext context) {
    var selectedTiebreak1 = tournament.settings.tb1;
    var selectedTiebreak2 = tournament.settings.tb2;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ranking Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiebreak 1:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<Tiebreak>(
                    value: selectedTiebreak1,
                    isExpanded: true,
                    items: Tiebreak.values.map<DropdownMenuItem<Tiebreak>>((
                      Tiebreak value,
                    ) {
                      return DropdownMenuItem<Tiebreak>(
                        value: value,
                        child: Text(value.longName),
                      );
                    }).toList(),
                    onChanged: (Tiebreak? newValue) {
                      setDialogState(() {
                        selectedTiebreak1 = newValue!;
                        if (selectedTiebreak1 == Tiebreak.no) {
                          selectedTiebreak2 = Tiebreak.no;
                        }
                      });
                    },
                  ),
                  Text(selectedTiebreak1.description),
                  const SizedBox(height: 20),
                  if (selectedTiebreak1 != Tiebreak.no)
                    const Text(
                      'Tiebreak 2:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (selectedTiebreak1 != Tiebreak.no)
                    DropdownButton<Tiebreak>(
                      value: selectedTiebreak2,
                      isExpanded: true,
                      items: Tiebreak.values.map<DropdownMenuItem<Tiebreak>>((
                        Tiebreak value,
                      ) {
                        return DropdownMenuItem<Tiebreak>(
                          value: value,
                          child: Text(value.longName),
                        );
                      }).toList(),
                      onChanged: (Tiebreak? newValue) {
                        setDialogState(() {
                          selectedTiebreak2 = newValue!;
                        });
                      },
                    ),
                  if (selectedTiebreak1 != Tiebreak.no)
                    Text(selectedTiebreak2.description),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    applyTiebreak(selectedTiebreak1, selectedTiebreak2);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ranking view');
    final lastRoundNum = tournament.rounds.length;
    final selectedTiebreak1 = tournament.settings.tb1;
    final selectedTiebreak2 = tournament.settings.tb2;
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
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsDialog(context),
                color: Theme.of(context).colorScheme.primary,
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
                  label: SizedBox(
                    height: headerHeight,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(' Startrank'),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: headerHeight,
                    child: RotatedBox(quarterTurns: 3, child: Text(' Rating')),
                  ),
                  numeric: true,
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                DataColumn(
                  label: SizedBox(
                    height: headerHeight,
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
                  label: SizedBox(
                    height: headerHeight,
                    child: RotatedBox(quarterTurns: 3, child: Text(' Score')),
                  ),
                ),
                if (selectedTiebreak1 != Tiebreak.no)
                  DataColumn(
                    numeric: true,
                    label: SizedBox(
                      height: headerHeight,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          ' Tiebreak 1\n ${selectedTiebreak1.shortName}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (selectedTiebreak2 != Tiebreak.no)
                  DataColumn(
                    numeric: true,
                    label: SizedBox(
                      height: headerHeight,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          ' Tiebreak 2\n ${selectedTiebreak2.shortName}',
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
                        if (selectedTiebreak1 != Tiebreak.no)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.only(right: 5),
                              child: Text(
                                r.buchholz!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ),
                        if (selectedTiebreak2 != Tiebreak.no)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.only(right: 5),
                              child: Text(
                                r.soBerg!.toStringAsFixed(2),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
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
