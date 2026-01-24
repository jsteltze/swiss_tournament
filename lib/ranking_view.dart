import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/player_ratings.dart';

import 'data/tournament.dart';

class RankingView extends StatelessWidget {
  final Tournament tournament;
  final Function onSettingsUpdate;

  static const tiebreakList = [
    'Buchholz (FIDE 2009)',
    'Buchholz (FIDE 2024)',
    'Sonneborn-Berger (FIDE 2009)',
    'Sonneborn-Berger (FIDE 2024)',
    'Direct Encounter',
    'No Tiebreak',
  ];
  static const tiebreakListShort = [
    'Buchholz',
    'Buchholz',
    'SoBerg',
    'SoBerg',
    'Direct',
    'No Tiebreak',
  ];

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

  void applyTiebreak(int tiebreak1, int tiebreak2) {
    TournamentSettings s = TournamentSettings(
      tiebreak1: TournamentSettings.tiebreakListTech[tiebreak1],
      tiebreak2: TournamentSettings.tiebreakListTech[tiebreak2],
    );
    onSettingsUpdate(s);
  }

  void _showSettingsDialog(BuildContext context) {
    var tiebreakExplanationList = [
      'Buchholz tiebreak: this is the sum of all opponent scores (independent from the result). FIDE 2009 rule: if an opponent has unplayed rounds the forfeit win only counts 0.5 points. If the player self has unplayed round, a virtual opponent is introduced, which has an equal score.',
      'Buchholz tiebreak: this is the sum of all opponent scores (independent from the result). FIDE 2024 rule: if an opponent has unplayed rounds the forfeit win counts as 1 regular point. If the player self has unplayed round, for each of them the own score is used.',
      'Sonneborn-Berger tiebreak: calculated the same way as Buchholz, but the opponents score is weighted with the result (factor 1.0 if won, factor 0.5 if draw, factor 0 if lost).',
      'Sonneborn-Berger tiebreak: calculated the same way as Buchholz, but the opponents score is weighted with the result (factor 1.0 if won, factor 0.5 if draw, factor 0 if lost).',
      'Direct Encounter tiebreak: for players sharing the same rank, this is the result of their direct encounter (if possible). If multiple players share the same rank the direct encounter score can be >1. If the players did not have a direct encounter the value remains 0.',
      'No Tiebreak: no tiebreak is used. Shared ranks are possible.',
    ];
    int selectedTiebreak1 = TournamentSettings.tiebreakListTech.indexOf(
      tournament.settings.tiebreak1,
    );
    ;
    int selectedTiebreak2 = TournamentSettings.tiebreakListTech.indexOf(
      tournament.settings.tiebreak2,
    );
    ;

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
                  DropdownButton<String>(
                    value: tiebreakList[selectedTiebreak1],
                    isExpanded: true,
                    items: tiebreakList.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedTiebreak1 = tiebreakList.indexOf(newValue!);
                        if (selectedTiebreak1 == tiebreakList.length - 1) {
                          selectedTiebreak2 = tiebreakList.length - 1;
                        }
                      });
                    },
                  ),
                  Text(tiebreakExplanationList[selectedTiebreak1]),
                  const SizedBox(height: 20),
                  if (selectedTiebreak1 != tiebreakList.length - 1)
                    const Text(
                      'Tiebreak 2:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (selectedTiebreak1 != tiebreakList.length - 1)
                    DropdownButton<String>(
                      value: tiebreakList[selectedTiebreak2],
                      isExpanded: true,
                      items: tiebreakList.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedTiebreak2 = tiebreakList.indexOf(newValue!);
                        });
                      },
                    ),
                  if (selectedTiebreak1 != tiebreakList.length - 1)
                    Text(tiebreakExplanationList[selectedTiebreak2]),
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
    final selectedTiebreak1 = TournamentSettings.tiebreakListTech.indexOf(
      tournament.settings.tiebreak1,
    );
    final selectedTiebreak2 = TournamentSettings.tiebreakListTech.indexOf(
      tournament.settings.tiebreak2,
    );
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
                if (selectedTiebreak1 != tiebreakList.length - 1)
                  DataColumn(
                    numeric: true,
                    label: SizedBox(
                      height: headerHeight,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          ' Tiebreak 1\n ${tiebreakListShort[selectedTiebreak1]}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (selectedTiebreak2 != tiebreakList.length - 1)
                  DataColumn(
                    numeric: true,
                    label: SizedBox(
                      height: headerHeight,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          ' Tiebreak 2\n ${tiebreakListShort[selectedTiebreak2]}',
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
                        if (selectedTiebreak1 != tiebreakList.length - 1)
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
                        if (selectedTiebreak2 != tiebreakList.length - 1)
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
