import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiss_tournament/player_tile.dart';

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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(
                        'No players added yet.',
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  separatorBuilder: (context, index) =>
                      index == firstLateJoiner - 1
                      ? Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(100),
                        )
                      : Divider(color: Colors.transparent),
                  itemCount: tournament.players.length,
                  itemBuilder: (context, index) {
                    final player = tournament.players[index];
                    var popup = PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditPlayerDialog(
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
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            enabled: tournament.rounds.isEmpty,
                            child: const Text('Delete'),
                          ),
                          if (player.leftAt == null)
                            PopupMenuItem(
                              value: 'disable',
                              child: const Text('Withdraw'),
                            ),
                          if (player.leftAt != null)
                            PopupMenuItem(
                              value: 're-enable',
                              child: const Text('Re-enable'),
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

  void _showEditPlayerDialog(
    BuildContext context,
    Tournament tournament,
    Player player,
    VoidCallback? onPlayersChanged,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: player.name,
    );
    final TextEditingController ratingController = TextEditingController(
      text: player.rating.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Player Name'),
                autofocus: true,
              ),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(hintText: 'Rating'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  player.name = nameController.text;
                  player.rating = int.parse(
                    ratingController.text.isEmpty ? '0' : ratingController.text,
                  );
                  tournament.sortPlayers();
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
}

void showAddPlayerDialog(
  BuildContext context,
  Tournament tournament,
  VoidCallback onPlayerAdded,
) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();

  final isLateJoin = tournament.rounds.isNotEmpty;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add Player${isLateJoin ? ' (Late Join)' : ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLateJoin)
              Text(
                'The tournament has already started!\nLate join players will be paired in future rounds. The existing order of players will not be affected (added to the bottom of the list).',
              ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Player Name'),
              autofocus: true,
            ),
            TextField(
              controller: ratingController,
              decoration: const InputDecoration(hintText: 'Rating'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                tournament.addPlayer(
                  Player(
                    name: nameController.text,
                    rating: int.parse(
                      ratingController.text.isEmpty
                          ? '0'
                          : ratingController.text,
                    ),
                    joinedAt: tournament.rounds.length,
                  ),
                );
                onPlayerAdded();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}
