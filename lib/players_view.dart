import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final int playersWithRating =
        tournament.players.where((p) => p.rating > 0).length;
    double averageRating = 0;
    if (playerCount > 0) {
      averageRating =
          tournament.players
              .where((p) => p.rating > 0)
              .map((p) => p.rating)
              .fold(0, (a, b) => a + b) /
          playersWithRating;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tournament.players.isNotEmpty)
          Container(
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Players: $playerCount',
                    style: Theme.of(context).textTheme.titleLarge,
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        Expanded(
          child:
              tournament.players.isEmpty
                  ? const Center(child: Text('No players added yet.'))
                  : ListView.builder(
                    itemCount: tournament.players.length,
                    itemBuilder: (context, index) {
                      final player = tournament.players[index];
                      return ListTile(
                        title: Text(player.name),
                        subtitle: Text(
                          '#${index + 1} Rating: ${player.rating > 0 ? player.rating : 'N/A'}',
                        ),
                        leading: const Icon(Icons.person),
                        trailing: PopupMenuButton<String>(
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
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ];
                          },
                        ),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
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

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add Player'),
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
                tournament.addPlayer(
                  Player(
                    name: nameController.text,
                    rating: int.parse(
                      ratingController.text.isEmpty
                          ? '0'
                          : ratingController.text,
                    ),
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
