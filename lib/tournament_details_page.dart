import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/tournament.dart';
import 'players_view.dart';
import 'rounds_view.dart';

class TournamentDetailsPage extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback? onTournamentChanged;
  final VoidCallback? onDeleteTournament;

  const TournamentDetailsPage({
    super.key,
    required this.tournament,
    this.onTournamentChanged,
    this.onDeleteTournament,
  });

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addPlayer() {
    showAddPlayerDialog(context, widget.tournament, () {
      setState(() {});
      widget.onTournamentChanged?.call();
    });
  }

  void _editTournament() {
    final TextEditingController titleController = TextEditingController(
      text: widget.tournament.title,
    );
    final TextEditingController roundsController = TextEditingController(
      text: widget.tournament.numberOfRounds.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Tournament'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter tournament name',
                ),
                autofocus: true,
              ),
              TextField(
                controller: roundsController,
                decoration: const InputDecoration(hintText: 'Number of rounds'),
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
                if (titleController.text.isNotEmpty &&
                    roundsController.text.isNotEmpty) {
                  setState(() {
                    widget.tournament.title = titleController.text;
                    widget.tournament.numberOfRounds = int.parse(
                      roundsController.text,
                    );
                  });
                  widget.onTournamentChanged?.call();
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

  void _confirmDeleteTournament() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tournament'),
          content: Text(
            'Are you sure you want to delete "${widget.tournament.title}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                widget.onDeleteTournament?.call();
                Navigator.pop(context); // Go back to list
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_selectedIndex) {
      case 1:
        bodyContent = RoundsView(tournament: widget.tournament);
        break;
      case 2:
        bodyContent = const Center(
          child: Text('Ranking will be displayed here'),
        );
        break;
      case 0:
      default:
        bodyContent = PlayersView(tournament: widget.tournament);
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTournament,
            tooltip: 'Edit Tournament',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteTournament,
            tooltip: 'Delete Tournament',
          ),
        ],
      ),
      body: bodyContent,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addPlayer,
              tooltip: 'Add Player',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
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
        onTap: _onItemTapped,
      ),
    );
  }
}
