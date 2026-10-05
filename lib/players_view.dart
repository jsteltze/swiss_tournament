import 'package:flutter/material.dart';
import 'package:js_flutter/components/no_data_tile.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:swiss_tournament/components/player_tile.dart';

import 'data/tournament.dart';
import 'dialogs/player_dialogs.dart';

class PlayersView extends StatelessWidget {
  final Tournament tournament;
  final String filter;
  final VoidCallback? onPlayersChanged;

  const PlayersView({
    super.key,
    required this.tournament,
    required this.filter,
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

    final filteredPlayers = filter.isEmpty
        ? tournament.players.toList()
        : tournament.players
              .where((p) => p.name.toLowerCase().contains(filter.toLowerCase()))
              .toList();

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
                    Text(
                      'o',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontFamily: 'RobotoMono',
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    Text(
                      '/',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontFamily: 'RobotoMono',
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
          child: filteredPlayers.isEmpty
              ? NoDataTile(
                  text: filter.isEmpty
                      ? 'No players added yet.'
                      : 'No players "$filter".',
                  icon: Icons.people,
                )
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
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    final popupItems = [
                      DialogAction(
                        title: 'Edit',
                        icon: editIcon,
                        onPressed: () => showEditPlayerDialog(
                          context,
                          tournament,
                          player,
                          onPlayersChanged,
                        ),
                      ),
                      if (player.leftAt == null)
                        DialogAction(
                          title: 'Withdraw',
                          icon: Icons.person_off,
                          onPressed: () => confirmDisablePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          ),
                        )
                      else
                        DialogAction(
                          title: 'Re-enable',
                          icon: Icons.person,
                          onPressed: () => confirmReenablePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          ),
                        ),
                      DialogAction(
                        title: 'Delete',
                        icon: deleteIcon,
                        isDestructive: true,
                        onPressed: tournament.rounds.isEmpty
                            ? () => confirmDeletePlayer(
                                context,
                                tournament,
                                player,
                                onPlayersChanged,
                              )
                            : null,
                      ),
                    ];
                    final playerIndex = tournament.players.indexOf(player);

                    return PlayerTile(
                      player: player,
                      index: playerIndex,
                      detailed: true,
                      popup: createPopupMenu(popupItems),
                      onTap: () => showPlayerDetailsDialog(
                        context,
                        playerIndex,
                        tournament,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
