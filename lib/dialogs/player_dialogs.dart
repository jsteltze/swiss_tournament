import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/utils/logger.dart';

import '../components/description.dart';
import '../components/info_panel.dart';
import '../components/info_table_row.dart';
import '../components/input_field.dart';
import '../components/input_title.dart';
import '../components/search_field.dart';
import '../components/warning.dart';
import '../data/encounter.dart';
import '../data/player.dart';
import '../data/player_ratings.dart';
import '../utils/snackbar_utils.dart';
import 'dialog_utils.dart';

void showPlayerDetailsDialog(
  BuildContext context,
  int index,
  Tournament tournament,
) {
  final rowWidth = 110.0;
  final tableDeco = BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainer,
    border: BoxBorder.all(
      color: Theme.of(context).colorScheme.secondary.withAlpha(50),
    ),
  );
  // map to PlayerRatings class
  final ratings = tournament.players
      .map(
        (p) =>
            PlayerRatings(player: p, playerId: tournament.players.indexOf(p)),
      )
      .toList();
  PlayerRatings.calculateRanks(ratings, tournament);
  final r = ratings.firstWhere((r) => r.playerId == index);

  openDialog(
    context,
    title: r.player.name,
    titleIcon: Icon(Icons.person),
    child: (ctx, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoPanel(
          Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: rowWidth,
                    child: Text(
                      'Score',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '(Win/Draw/Lose)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: rowWidth,
                    child: Text(
                      r.points!.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge!
                          .copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '(${r.wins}/${r.draws}/${r.losses})',
                      style: Theme.of(context).textTheme.headlineLarge!
                          .copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InfoRow(
                '${tournament.isFinished() ? 'Final' : 'Current'} Rank:',
                '#${r.rank} ${r.sharedPlace.isNotEmpty ? '(shared)' : ''}',
                titleWidth: rowWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        InfoRow(
          'Tiebreak:',
          '${tournament.settings.tb1.formatScore(r.tiebreak1!)} (${tournament.settings.tb1.shortName})',
          titleWidth: rowWidth,
        ),
        InfoRow('Start Rank:', '#${index + 1}', titleWidth: rowWidth),
        InfoRow(
          'Rating:',
          r.player.rating > 0 ? r.player.rating.toString() : 'N/A',
          titleWidth: rowWidth,
        ),
        InfoRow(
          'Performance:',
          '',
          titleWidth: rowWidth,
          contentWidget: Row(
            children: [
              if (r.player.rating > 0 && r.performance! > 0)
                Transform.rotate(
                  angle: (r.player.rating - r.performance!).sign * 0.8,
                  child: Icon(
                    size: 12,
                    Icons.arrow_forward,
                    color: r.performance! > r.player.rating
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              Text(r.performance == 0 ? '-' : r.performance.toString()),
            ],
          ),
        ),
        InfoRow(
          'Status:',
          r.player.leftAt == null ? 'Active' : 'Withdrawn',
          titleWidth: rowWidth,
        ),
        if (r.player.joinedAt > 0)
          InfoRow(
            'Joined at:',
            'Round ${r.player.joinedAt}',
            titleWidth: rowWidth,
          ),
        if (r.player.leftAt != null)
          InfoRow('Left at:', 'Round ${r.player.leftAt}', titleWidth: rowWidth),
        if (tournament.rounds.isNotEmpty) ...[
          SizedBox(height: 10),
          InfoRow('Results:', ''),
          ...tournament.rounds.map((r) {
            final encounter = r.encounters.firstWhere(
              (e) => e.playerIdB == index || e.playerIdW == index,
              orElse: () => Encounter(playerIdW: -1, playerIdB: -1),
            );
            String opponentName = '-';
            String opponentRating = '';
            String result = encounter.result;
            if (encounter.playerIdW >= 0 || encounter.playerIdB >= 0) {
              final isWhite = encounter.playerIdW == index;
              if (isWhite) {
                if (result == '0.5-0.5') result = '½ (w)';
                if (result == '1-0') result = '1 (w)';
                if (result == '0-1') result = '0 (w)';
                if (result == '+ -') result = '+ (w)';
                if (result == '- +') result = '- (w)';
              } else {
                if (result == '0.5-0.5') result = '½ (b)';
                if (result == '1-0') result = '0 (b)';
                if (result == '0-1') result = '1 (b)';
                if (result == '+ -') result = '- (b)';
                if (result == '- +') result = '+ (b)';
              }

              final opponentId = isWhite
                  ? encounter.playerIdB
                  : encounter.playerIdW;
              opponentName = opponentId < 0
                  ? 'Bye'
                  : tournament.players[opponentId].name;
              opponentRating = opponentId < 0
                  ? ''
                  : tournament.players[opponentId].rating.toString();
              if (opponentRating == '0') {
                opponentRating = 'N/A';
              }
            }
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: tableDeco,
                    child: Text(
                      opponentName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  decoration: tableDeco,
                  child: Text(
                    opponentRating,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  decoration: tableDeco,
                  child: Text(result),
                ),
              ],
            );
          }),
        ],
      ],
    ),
    closeButtonTitle: 'Close',
  );
}

void confirmDeletePlayer(
  BuildContext context,
  Tournament tournament,
  Player player,
  VoidCallback? onPlayersChanged,
) {
  openDialog(
    context,
    title: 'Delete Player',
    titleIcon: Icon(Icons.delete),
    child: (ctx, setDialogState) => Text(
      'Are you sure you want to delete "${player.name}"?\n\nYou can also withdraw the player. In this case the player is just disabled and can be re-enabled in future rounds.',
    ),
    mainAction: DialogAction(
      title: 'Delete',
      isDestructive: true,
      onPressed: () {
        FileLogger.log(
          'Deleting player "${player.name}" from tournament ID: ${tournament.id}',
        );
        tournament.players.remove(player);
        onPlayersChanged?.call();
        Navigator.pop(context);
        showSnackbar(context, 'Player "${player.name}" deleted');
      },
    ),
  );
}

void confirmDisablePlayer(
  BuildContext context,
  Tournament tournament,
  Player player,
  VoidCallback? onPlayersChanged,
) {
  openDialog(
    context,
    title: 'Withdraw Player',
    titleIcon: Icon(Icons.person_off),
    child: (ctx, setDialogState) => Text(
      'Are you sure you want to withdraw (disable) "${player.name}"?\nDisabled players will not be paired in future rounds but can be re-enabled.',
    ),
    mainAction: DialogAction(
      title: 'Disable',
      onPressed: () {
        FileLogger.log(
          'Withdrawing player "${player.name}" (left at round ${tournament.rounds.length})',
        );
        player.leftAt = tournament.rounds.length;
        onPlayersChanged?.call();
        Navigator.pop(context);
        showSnackbar(context, 'Player "${player.name}" disabled');
      },
      isDestructive: true,
    ),
  );
}

void confirmReenablePlayer(
  BuildContext context,
  Tournament tournament,
  Player player,
  VoidCallback? onPlayersChanged,
) {
  openDialog(
    context,
    title: 'Re-enable Player',
    titleIcon: Icon(Icons.person),
    child: (ctx, setDialogState) => Text(
      'Are you sure you want to re-enable "${player.name}"?\nThis player will be paired again in future rounds.',
    ),
    mainAction: DialogAction(
      title: 'Re-enable',
      onPressed: () {
        FileLogger.log('Re-enabling player "${player.name}"');
        player.leftAt = null;
        onPlayersChanged?.call();
        Navigator.pop(context);
        showSnackbar(context, 'Player "${player.name}" re-enabled');
      },
    ),
  );
}

void showEditPlayerDialog(
  BuildContext context,
  Tournament tournament,
  Player? player,
  VoidCallback? onPlayersChanged,
) {
  final TextEditingController nameController = TextEditingController(
    text: player?.name,
  );
  final TextEditingController ratingController = TextEditingController(
    text: player?.rating.toString(),
  );
  final formKey = GlobalKey<FormState>();
  final isLateJoin = player == null && tournament.rounds.isNotEmpty;

  openDialog(
    context,
    title:
        '${player == null ? 'New' : 'Edit'} Player${isLateJoin ? ' (Late Join)' : ''}',
    titleIcon: Icon(player == null ? Icons.person_add_alt_1 : Icons.edit),
    child: (ctx, setDialogState) => Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLateJoin) ...[
            const Warning(
              'The tournament has already started!\nLate join players will be paired in future rounds. The existing order of players will not be affected (added to the bottom of the list).',
            ),
            const SizedBox(height: 25),
          ],
          InputField('Player name', nameController, autoFocus: !isLateJoin),
          const SizedBox(height: 25),
          InputField(
            'Player rating',
            ratingController,
            isOptional: true,
            inputType: TextInputType.number,
          ),
          if (player == null) ...[
            const SizedBox(height: 25),
            Description(
              'The Players form is intended to be as simple as possible. No need for titles or other attributes that have no effect. All that is needed is the player name to identify the player and the rating. The rating is needed for the order. Players are sorted automatically by their rating (descending). The order is very important for the Swiss pairing algorithm. The rating is optional. If left empty a rating of 0 will be used (sorted at the bottom of the list).',
              isExpandable: true,
            ),
          ],
        ],
      ),
    ),
    mainAction: DialogAction(
      title: 'Save',
      onPressed: () {
        if (formKey.currentState!.validate()) {
          final isAdding = player == null;
          player ??= Player(joinedAt: tournament.rounds.length);
          player!.name = nameController.text.trim();
          player!.rating = int.parse(
            ratingController.text.isEmpty ? '0' : ratingController.text,
          );
          if (isAdding) {
            FileLogger.log(
              'Adding new player: ${player!.name} (Rating: ${player!.rating})',
            );
            tournament.addPlayer(player!);
          } else {
            FileLogger.log(
              'Edited player: ${player!.name} (Rating: ${player!.rating})',
            );
            tournament.sortPlayers();
          }
          onPlayersChanged?.call();
          Navigator.pop(context);
          showSnackbar(
            context,
            'Player "${player!.name}" ${isAdding ? 'added' : 'edited'}',
          );
        }
      },
    ),
  );
}

void selectByePlayersDialog(
  BuildContext context,
  Tournament tournament,
  Function(List<int>) onByesSelected,
) {
  List<bool> selected = List.generate(
    tournament.players.length,
    (index) => false,
  );
  List<Player> filteredPlayers = tournament.players.toList();

  openDialog(
    context,
    title: 'Requested byes',
    titleIcon: Icon(Icons.person_off),
    child: (ctx, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoPanel(
          Text(
            'Select the players who requested a bye for the upcoming round ${tournament.rounds.length + 1}.',
          ),
        ),
        InputTitle(
          'Players using a bye get half a point and will not be paired in the next round.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SearchField(
              onSearch: (value) {
                setDialogState(() {
                  filteredPlayers = value.isEmpty
                      ? tournament.players.toList()
                      : tournament.players
                            .where(
                              (p) => p.name.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                });
              },
            ),
          ],
        ),
        SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: filteredPlayers.length,
            itemBuilder: (context, index) {
              final player = filteredPlayers[index];
              final realIndex = tournament.players.indexOf(player);
              final byesUsed = tournament.rounds
                  .where(
                    (r) => r.encounters.any(
                      (e) => e.playerIdW == realIndex && e.playerIdB == -2,
                    ),
                  )
                  .length;
              return CheckboxListTile(
                title: Text(player.name),
                enabled: byesUsed < tournament.settings.bye,
                subtitle: Text(
                  'Byes used: $byesUsed / ${tournament.settings.bye}',
                ),
                value: selected[realIndex],
                onChanged: (val) {
                  setDialogState(() {
                    selected[realIndex] = val!;
                  });
                },
              );
            },
          ),
        ),
        InputTitle(
          'Selected: ${selected.where((s) => s).length} / ${tournament.players.length}',
        ),
      ],
    ),
    mainAction: DialogAction(
      title: 'Continue',
      onPressed: () {
        final List<int> playerIds = [];
        for (final (index, s) in selected.indexed) {
          if (s) playerIds.add(index);
        }
        Navigator.pop(context);
        onByesSelected.call(playerIds);
      },
    ),
  );
}
