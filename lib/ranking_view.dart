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

  int _comparePlayersAndSetSharedPlace(PlayerRatings a, PlayerRatings b) {
    var comparePoints = b.points!.compareTo(a.points!);
    if (comparePoints != 0) {
      return comparePoints;
    }
    var compareTb1 = b.tiebreak1!.compareTo(a.tiebreak1!);
    if (compareTb1 != 0) {
      return compareTb1;
    }
    var compareTb2 = b.tiebreak2!.compareTo(a.tiebreak2!);
    if (compareTb2 != 0) {
      return compareTb2;
    }

    a.sharedPlace =
        a.points!.toString() +
        a.tiebreak1!.toString() +
        a.tiebreak2!.toString();
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
                  child: const Text('Save'),
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
    final headerHeight = 90.0;
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

    // map to PlayerRatings class
    final ratings = tournament.players
        .map(
          (p) =>
              PlayerRatings(player: p, playerId: tournament.players.indexOf(p)),
        )
        .toList();

    // calculate the tiebreaks (other than 'direct')
    for (int r = 0; r < ratings.length; r++) {
      ratings[r].calculateRatings(tournament);
    }

    // sort by tiebreaks (other than 'direct')
    ratings.sort(_comparePlayersAndSetSharedPlace);

    // post-calculate 'direct' tiebreak
    if (tournament.settings.tb1 == Tiebreak.direct ||
        tournament.settings.tb2 == Tiebreak.direct) {
      for (int r = 0; r < ratings.length; r++) {
        if (ratings[r].sharedPlace.isNotEmpty) {
          final sharedPlaceInfo = ratings[r].sharedPlace;
          final playerId = ratings[r].playerId;
          var opponents = ratings
              .where((e) => e.sharedPlace == sharedPlaceInfo)
              .where((e) => e.playerId != playerId)
              .map((e) => e.playerId)
              .toList();
          var direct = 0.0;
          for (int i = 0; i < opponents.length; i++) {
            for (var round in tournament.rounds) {
              for (var encounter in round.encounters) {
                if (encounter.playerIdW == playerId &&
                    encounter.playerIdB == opponents[i]) {
                  if (["1-0", "+ -"].contains(encounter.result)) {
                    direct += 1.0;
                  } else if (encounter.result == "0.5-0.5") {
                    direct += 0.5;
                  }
                }
                if (encounter.playerIdB == playerId &&
                    encounter.playerIdW == opponents[i]) {
                  if (["0-1", "- +"].contains(encounter.result)) {
                    direct += 1.0;
                  } else if (encounter.result == "0.5-0.5") {
                    direct += 0.5;
                  }
                }
              }
            }
          }
          if (tournament.settings.tb1 == Tiebreak.direct) {
            ratings[r].tiebreak1 = direct;
          }
          if (tournament.settings.tb2 == Tiebreak.direct) {
            ratings[r].tiebreak2 = direct;
          }
        } else {
          if (tournament.settings.tb1 == Tiebreak.direct) {
            ratings[r].tiebreak1 = 0.0;
          }
          if (tournament.settings.tb2 == Tiebreak.direct) {
            ratings[r].tiebreak2 = 0.0;
          }
        }
      }

      // sort again, this time 'direct' tiebreaks are set
      ratings.sort(_comparePlayersAndSetSharedPlace);
    }

    // update rank according to the current order
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

    DataColumn rotatedNumericHeader(title, {String? headline}) => DataColumn(
      numeric: true,
      label: SizedBox(
        height: headerHeight,
        child: Padding(
          padding: EdgeInsetsGeometry.only(bottom: 3),
          child: RotatedBox(
            quarterTurns: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headline != null)
                  Text(
                    headline,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                Text(title),
              ],
            ),
          ),
        ),
      ),
    );

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
                    height: headerHeight,
                    alignment: Alignment.bottomLeft,
                    child: Text('Name'),
                  ),
                ),
                rotatedNumericHeader('Startrank'),
                rotatedNumericHeader('Rating'),
                rotatedNumericHeader('Performance'),
                rotatedNumericHeader('Games'),
                DataColumn(
                  label: Container(
                    height: headerHeight,
                    alignment: Alignment.bottomCenter,
                    child: Text('W/D/L'),
                  ),
                  headingRowAlignment: MainAxisAlignment.start,
                ),
                rotatedNumericHeader('Score'),
                if (selectedTiebreak1 != Tiebreak.no)
                  rotatedNumericHeader(
                    selectedTiebreak1.shortName,
                    headline: 'Tiebreak 1:',
                  ),
                if (selectedTiebreak2 != Tiebreak.no)
                  rotatedNumericHeader(
                    selectedTiebreak2.shortName,
                    headline: 'Tiebreak 2:',
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
                            child: Row(
                              children: [
                                if (r.player.rating > 0 && r.performance! > 0)
                                  Transform.rotate(
                                    angle:
                                        (r.player.rating - r.performance!)
                                            .sign *
                                        0.8,
                                    child: Icon(
                                      size: 12,
                                      Icons.arrow_forward,
                                      color: r.performance! > r.player.rating
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                Text(
                                  r.performance.toString(),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ],
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
                                tournament.settings.tb1.formatScore(
                                  r.tiebreak1!,
                                ),
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
                                tournament.settings.tb2.formatScore(
                                  r.tiebreak2!,
                                ),
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
