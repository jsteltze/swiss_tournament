import 'package:flutter/material.dart';
import 'package:swiss_tournament/dialogs/tournament_popup_menu.dart';
import 'package:swiss_tournament/ranking_view.dart';

import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'players_view.dart';
import 'rounds_view.dart';

class TournamentDetailsPage extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback? onDeleteTournament;
  final VoidCallback? onUpdate;

  const TournamentDetailsPage({
    super.key,
    required this.tournament,
    this.onDeleteTournament,
    this.onUpdate,
  });

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  int _selectedIndex = 0;
  final TournamentStorage _storage = TournamentStorage();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onUpdatePlayers() {
    setState(() {});
    widget.tournament.update();
  }

  void _addPlayer() {
    showEditPlayerDialog(context, widget.tournament, null, _onUpdatePlayers);
  }

  void _onRoundUpdate() {
    widget.onUpdate?.call();
  }

  void _applyNewSettings(TournamentSettings settings) {
    widget.tournament.settings = settings;
    widget.tournament.update();
    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_selectedIndex) {
      case 1:
        bodyContent = RoundsView(
          tournament: widget.tournament,
          onTournamentFinished: () => setState(() {
            _selectedIndex = 2;
          }),
          onRoundUpdate: _onRoundUpdate,
        );
        break;
      case 2:
        bodyContent = RankingView(
          tournament: widget.tournament,
          onSettingsUpdate: _applyNewSettings,
        );
        break;
      case 0:
      default:
        bodyContent = PlayersView(
          tournament: widget.tournament,
          onPlayersChanged: _onUpdatePlayers,
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tournament.title),
            Text(
              'Rounds: ${widget.tournament.numberOfRounds}',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TournamentPopupMenu(
            tournament: widget.tournament,
            storage: _storage,
            onEdit: (tournament) {
              setState(() {});
              widget.onUpdate?.call();
            },
            onDelete: () {
              widget.onDeleteTournament?.call();
              Navigator.pop(context);
            },
            onUpdate: () {
              widget.onUpdate?.call();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: bodyContent,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addPlayer,
              tooltip: 'Add Player',
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Players'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Rounds'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        onTap: _onItemTapped,
      ),
    );
  }
}
