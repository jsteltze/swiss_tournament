import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiss_tournament/components/player_tile.dart';

import 'components/no_data_tile.dart';
import 'data/player.dart';
import 'data/tournament.dart';

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
    print('firstLateJoiner=$firstLateJoiner');

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
                                    color: Theme.of(context).colorScheme.error,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeletePlayer(
    BuildContext context,
    Tournament tournament,
    Player player,
    VoidCallback? onPlayersChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Player'),
          content: Text('Are you sure you want to delete "${player.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                tournament.players.remove(player);
                onPlayersChanged?.call();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDisablePlayer(
    BuildContext context,
    Tournament tournament,
    Player player,
    VoidCallback? onPlayersChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Withdraw Player'),
          content: Text(
            'Are you sure you want to withdraw (disable) "${player.name}"?\nDisabled players will not be paired in future rounds.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                player.leftAt = tournament.rounds.length;
                onPlayersChanged?.call();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Disable'),
            ),
          ],
        );
      },
    );
  }

  void _confirmReenablePlayer(
    BuildContext context,
    Tournament tournament,
    Player player,
    VoidCallback? onPlayersChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Re-enable Player'),
          content: Text(
            'Are you sure you want to re-enable "${player.name}"?\nThis player will be paired again in future rounds.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                player.leftAt = null;
                onPlayersChanged?.call();
                Navigator.pop(context);
              },
              child: const Text('Re-enable'),
            ),
          ],
        );
      },
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
  final isLateJoin = player != null && tournament.rounds.isNotEmpty;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '${player == null ? 'New' : 'Edit'} Player${isLateJoin ? ' (Late Join)' : ''}',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLateJoin)
                const Text(
                  'The tournament has already started!\nLate join players will be paired in future rounds. The existing order of players will not be affected (added to the bottom of the list).',
                ),
              TextFormField(
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a player name';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Player name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: ratingController,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      int.tryParse(value) != null) {
                    return null;
                  }
                  return 'Please enter a valid rating (integer)';
                },
                decoration: const InputDecoration(
                  labelText: 'Player rating',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final isAdding = player == null;
                player ??= Player(joinedAt: tournament.rounds.length);
                player!.name = nameController.text;
                player!.rating = int.parse(
                  ratingController.text.isEmpty ? '0' : ratingController.text,
                );
                if (isAdding) {
                  tournament.addPlayer(player!);
                } else {
                  tournament.sortPlayers();
                }
                onPlayersChanged?.call();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
