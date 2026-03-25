import 'package:flutter/material.dart';
import 'package:swiss_tournament/components/description.dart';
import 'package:swiss_tournament/components/info_panel.dart';
import 'package:swiss_tournament/components/info_table_row.dart';
import 'package:swiss_tournament/components/input_field.dart';
import 'package:swiss_tournament/components/player_tile.dart';
import 'package:swiss_tournament/components/warning.dart';
import 'package:swiss_tournament/data/player_ratings.dart';
import 'package:swiss_tournament/utils/logger.dart';

import 'components/no_data_tile.dart';
import 'data/player.dart';
import 'data/tournament.dart';
import 'dialogs/dialog_utils.dart';

class PlayersView extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onPlayersChanged;

  const PlayersView({
    super.key,
    required this.tournament,
    this.onPlayersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int playerCount = tournament.players.length;
    final int playersWithRating = tournament.players
        .where((p) => p.rating > 0)
        .length;
    double averageRating = 0;
    if (playerCount > 0) {
      averageRating =
          tournament.players
              .where((p) => p.rating > 0)
              .map((p) => p.rating)
              .fold(0, (a, b) => a + b) /
          playersWithRating;
    }
    final int firstLateJoiner = tournament.players.indexWhere(
      (p) => p.joinedAt > 0,
    );
    // FileLogger.log('firstLateJoiner=$firstLateJoiner');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tournament.players.isNotEmpty)
          Container(
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              spacing: 15,
              children: [
                Icon(
                  Icons.people,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Players: $playerCount',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '(active: ${tournament.players.where((p) => p.leftAt == null).length})',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Icon(
                      Icons.circle_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    Text(
                      ' / ',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    Text(
                      '     ${averageRating.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: tournament.players.isEmpty
              ? NoDataTile(text: 'No players added yet.', icon: Icons.people)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  separatorBuilder: (context, index) =>
                      index == firstLateJoiner - 1
                      ? Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(100),
                        )
                      : const Divider(color: Colors.transparent),
                  itemCount: tournament.players.length,
                  itemBuilder: (context, index) {
                    final player = tournament.players[index];
                    var popup = PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showEditPlayerDialog(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          );
                        } else if (value == 'delete') {
                          _confirmDeletePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          );
                        } else if (value == 'disable') {
                          _confirmDisablePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          );
                        } else if (value == 're-enable') {
                          _confirmReenablePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (player.leftAt == null)
                            PopupMenuItem(
                              value: 'disable',
                              child: Row(
                                children: [
                                  Icon(Icons.person_off, size: 20),
                                  SizedBox(width: 8),
                                  Text('Withdraw'),
                                ],
                              ),
                            ),
                          if (player.leftAt != null)
                            PopupMenuItem(
                              value: 're-enable',
                              child: Row(
                                children: [
                                  Icon(Icons.person, size: 20),
                                  SizedBox(width: 8),
                                  Text('Re-enable'),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            enabled: tournament.rounds.isEmpty,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error
                                        .withAlpha(
                                          tournament.rounds.isEmpty ? 255 : 150,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    );
                    return PlayerTile(
                      player: player,
                      index: index,
                      detailed: true,
                      popup: popup,
                      onTap: () => _showPlayerDetailsDialog(context, index),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPlayerDetailsDialog(BuildContext context, int index) {
    final rowWidth = 110.0;
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
                  'Current Rank:',
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
            InfoRow(
              'Left at:',
              'Round ${r.player.leftAt}',
              titleWidth: rowWidth,
            ),
        ],
      ),
      closeButtonTitle: 'Close',
    );
  }

  void _confirmDeletePlayer(
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
        },
      ),
    );
  }

  void _confirmDisablePlayer(
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
        },
        isDestructive: true,
      ),
    );
  }

  void _confirmReenablePlayer(
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
        },
      ),
    );
  }
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
        }
      },
    ),
    closeButtonTitle: 'Cancel',
  );
}
