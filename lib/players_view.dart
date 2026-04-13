import 'package:flutter/material.dart';
import 'package:swiss_tournament/components/player_tile.dart';

import 'components/no_data_tile.dart';
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
                          confirmDeletePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          );
                        } else if (value == 'disable') {
                          confirmDisablePlayer(
                            context,
                            tournament,
                            player,
                            onPlayersChanged,
                          );
                        } else if (value == 're-enable') {
                          confirmReenablePlayer(
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
                    final playerIndex = tournament.players.indexOf(player);

                    return PlayerTile(
                      player: player,
                      index: playerIndex,
                      detailed: true,
                      popup: popup,
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
