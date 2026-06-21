import 'package:flutter/material.dart';
import 'package:swiss_tournament/components/description.dart';
import 'package:swiss_tournament/components/input_title.dart';
import 'package:swiss_tournament/data/player_ratings.dart';
import 'package:swiss_tournament/data/tiebreak.dart';
import 'package:swiss_tournament/utils/export_handler.dart';
import 'package:swiss_tournament/utils/html_utils.dart';
import 'package:swiss_tournament/utils/logger.dart';
import 'package:swiss_tournament/utils/snackbar_utils.dart';

import 'components/no_data_tile.dart';
import 'data/tournament.dart';
import 'dialogs/dialog_utils.dart';

class RankingView extends StatelessWidget {
  final Tournament tournament;
  final Function onSettingsUpdate;

  const RankingView({
    super.key,
    required this.tournament,
    required this.onSettingsUpdate,
  });

  void applyTiebreak(Tiebreak tb1, Tiebreak tb2) {
    TournamentSettings s = TournamentSettings(tb1: tb1, tb2: tb2);
    onSettingsUpdate(s);
  }

  void _showSettingsDialog(BuildContext context, List<PlayerRatings> ratings) {
    var selectedTiebreak1 = tournament.settings.tb1;
    var selectedTiebreak2 = tournament.settings.tb2;

    openDialog(
      context,
      title: 'Ranking Settings',
      titleIcon: Icon(Icons.settings),
      child: (ctx, setDialogState, toggleMainAction) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputTitle('Tiebreak 1:'),
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
          Description(selectedTiebreak1.description),
          const SizedBox(height: 20),
          if (selectedTiebreak1 != Tiebreak.no) ...[
            InputTitle('Tiebreak 2:'),
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
            Description(selectedTiebreak2.description),
          ],
          const SizedBox(height: 20),
          InputTitle('Export:'),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final String htmlContent = toHtmlRanking(
                tournament,
                ratings,
                context.mounted ? context : null,
              );
              final String filename =
                  '${tournament.title.replaceAll(' ', '_')}_ranking_round_${tournament.rounds.length}.html';

              await ExportHandler.exportToDownloads(
                context,
                filename,
                htmlContent,
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_download_outlined),
                Text('Export current ranking as HTML'),
              ],
            ),
          ),
        ],
      ),
      mainAction: DialogAction(
        title: 'Save',
        onPressed: () {
          FileLogger.log(
            'Applying new tiebreak settings: TB1=$selectedTiebreak1, TB2=$selectedTiebreak2',
          );
          applyTiebreak(selectedTiebreak1, selectedTiebreak2);
          Navigator.pop(context);
          showSnackbar(context, 'Ranking settings saved');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastRoundNum = tournament.rounds.length;
    final selectedTiebreak1 = tournament.settings.tb1;
    final selectedTiebreak2 = tournament.settings.tb2;
    final headerHeight = 90.0;
    if (lastRoundNum == 0) {
      return NoDataTile(
        text: 'Tournament has not started yet.',
        icon: Icons.leaderboard,
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
    PlayerRatings.calculateRanks(ratings, tournament);

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
                onPressed: () => _showSettingsDialog(context, ratings),
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
                                Icon(
                                  Icons.emoji_events,
                                  color: Color.fromARGB(255, 255, 215, 0),
                                ),
                              if (r.rank == 2)
                                Icon(
                                  Icons.emoji_events,
                                  color: Color.fromARGB(255, 192, 192, 192),
                                ),
                              if (r.rank == 3)
                                Icon(
                                  Icons.emoji_events,
                                  color: Color.fromARGB(255, 205, 127, 50),
                                ),
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
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (r.player.rating > 0 && r.performance! > 0)
                                  Transform.rotate(
                                    angle:
                                        (r.player.rating - r.performance!)
                                            .sign *
                                        0.8,
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: r.performance! > r.player.rating
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                Text(
                                  r.performance == 0
                                      ? '-'
                                      : r.performance.toString(),
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
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${r.wins}/${r.draws}/${r.losses} (',
                                ),
                                TextSpan(
                                  text: r.winsLossesString,
                                  style:
                                      r.winsLossesString.startsWith(
                                        RegExp(r'\+|-'),
                                      )
                                      ? TextStyle(
                                          color:
                                              r.winsLossesString.startsWith('+')
                                              ? Colors.green
                                              : Colors.red,
                                        )
                                      : null,
                                ),
                                TextSpan(text: ')'),
                              ],
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
