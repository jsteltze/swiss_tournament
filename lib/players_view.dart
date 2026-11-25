import 'package:js_flutter/components/list.dart';
import 'package:js_flutter/components/no_data_tile.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swiss_tournament/components/player_tile.dart';
import 'package:swiss_tournament/components/players_view_header.dart';
import 'package:swiss_tournament/data/player.dart';

import 'data/tournament.dart';
import 'dialogs/player_dialogs.dart';

class PlayersView extends StatefulWidget {
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
  State<PlayersView> createState() => _PlayersViewState();
}

class _PlayersViewState extends State<PlayersView> {
  final GlobalKey<MyListState<Player>> list = GlobalKey<MyListState<Player>>();
  bool _filterActive = false;

  @override
  Widget build(BuildContext context) {
    final int firstLateJoiner = widget.tournament.players.indexWhere(
      (p) => p.joinedAt > 0,
    );

    final filteredPlayers1 = _filterActive
        ? widget.tournament.players.where((p) => p.leftAt == null).toList()
        : widget.tournament.players.toList();
    final filteredPlayers2 = widget.filter.isEmpty
        ? filteredPlayers1
        : filteredPlayers1
              .where(
                (p) =>
                    p.name.toLowerCase().contains(widget.filter.toLowerCase()),
              )
              .toList();
    list.currentState?.doFiltering(filteredPlayers2);

    final noDataTile = NoDataTile(
      text: 'No players named "${widget.filter}".',
      icon: Icons.people,
    );

    return Column(
      crossAxisAlignment: .start,
      children: [
        if (widget.tournament.players.isNotEmpty)
          PlayersViewHeader(
            widget.tournament,
            filterCallback: (x) => {
              setState(() {
                _filterActive = x;
              }),
            },
          ),
        Expanded(
          child: MyList<Player>(
            key: list,
            initialItems: widget.tournament.players,
            separatorBuilder: (index) => index == firstLateJoiner - 1
                ? Column(
                    children: [
                      Divider(
                        color: Theme.of(context).colorScheme.primary
                            .withAlpha(100),
                      ),
                      Text('Late Joiners:'),
                    ],
                  )
                : null,
            itemBuilder: (player) {
              final popupItems = [
                DialogAction(
                  title: 'Edit',
                  icon: editIcon,
                  onPressed: widget.tournament.isFinished()
                      ? null
                      : (_) => showEditPlayerDialog(
                          context,
                          widget.tournament,
                          player,
                          widget.onPlayersChanged,
                        ),
                ),
                if (player.leftAt == null)
                  DialogAction(
                    title: 'Withdraw',
                    icon: Icons.person_off,
                    onPressed: widget.tournament.isFinished()
                        ? null
                        : (_) => confirmDisablePlayer(
                            context,
                            widget.tournament,
                            player,
                            widget.onPlayersChanged,
                          ),
                  )
                else
                  DialogAction(
                    title: 'Re-enable',
                    icon: Icons.person,
                    onPressed: widget.tournament.isFinished()
                        ? null
                        : (_) => confirmReenablePlayer(
                            context,
                            widget.tournament,
                            player,
                            widget.onPlayersChanged,
                          ),
                  ),
                DialogAction(
                  title: 'Delete',
                  icon: deleteIcon,
                  isDestructive: true,
                  onPressed: widget.tournament.rounds.isEmpty
                      ? (_) => confirmDeletePlayer(
                          context,
                          widget.tournament,
                          player,
                          widget.onPlayersChanged,
                        )
                      : null,
                ),
              ];
              final playerIndex = widget.tournament.players.indexOf(player);

              return PlayerTile(
                player: player,
                index: playerIndex,
                detailed: true,
                popup: createPopupMenu(popupItems),
                onTap: () => showPlayerDetailsDialog(
                  context,
                  playerIndex,
                  widget.tournament,
                ),
              );
            },
            noDataTile: noDataTile,
          ),
        ),
      ],
    );
  }
}
