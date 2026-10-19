import 'package:flutter/material.dart';
import 'package:js_flutter/components/no_data_tile.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:swiss_tournament/components/player_tile.dart';
import 'package:swiss_tournament/components/players_view_header.dart';

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
    final int firstLateJoiner = tournament.players.indexWhere(
      (p) => p.joinedAt > 0,
    );

    final filteredPlayers = filter.isEmpty
        ? tournament.players.toList()
        : tournament.players
              .where((p) => p.name.toLowerCase().contains(filter.toLowerCase()))
              .toList();

    return Column(
      crossAxisAlignment: .start,
      children: [
        if (tournament.players.isNotEmpty) PlayersViewHeader(tournament),
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
                          color: Theme.of(context).colorScheme.primary
                              .withAlpha(100),
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
