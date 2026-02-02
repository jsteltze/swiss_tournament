import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jni/jni.dart';
import 'package:swiss_tournament/components/description.dart';
import 'package:swiss_tournament/components/input_title.dart';
import 'package:swiss_tournament/ranking_view.dart';

import 'data/tournament.dart';
import 'data/tournament_storage.dart';
import 'java.g.dart';
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
    showAddPlayerDialog(context, widget.tournament, _onUpdatePlayers);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputTitle(text: 'Name:'),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter tournament name',
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              InputTitle(text: 'Rounds:'),
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
                  widget.tournament.update();
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

  void _onRoundUpdate() {
    widget.onUpdate?.call();
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

  void _exportTournament() {
    final TextEditingController filenameController = TextEditingController(
      text: 'tournament-${widget.tournament.id ?? 'new'}',
    );
    String exportType = 'Full Tournament';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Export Tournament'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Description(
                    text:
                        'Export to Downloads folder. The saved file can serve as a backup or can be shared and imported on other devices.',
                  ),
                  const SizedBox(height: 16),
                  InputTitle(text: 'Type:'),
                  DropdownButton<String>(
                    value: exportType,
                    isExpanded: true,
                    items: <String>['Full Tournament', 'Players only']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        exportType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputTitle(text: 'Filename:'),
                  TextField(
                    controller: filenameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter filename',
                      suffixText: '.json',
                    ),
                    autofocus: true,
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
                    String filename = filenameController.text;
                    if (filename.isEmpty) return;
                    if (!filename.toLowerCase().endsWith('.json')) {
                      filename += '.json';
                    }

                    Map<String, dynamic> data;
                    if (exportType == 'Full Tournament') {
                      data = widget.tournament.toJson();
                    } else {
                      data = {
                        'title': widget.tournament.title,
                        'createdAt': widget.tournament.createdAt,
                        'numberOfRounds': widget.tournament.numberOfRounds,
                        'players': widget.tournament.players
                            .map((p) => p.toJson())
                            .toList(),
                      };
                    }

                    final String jsonContent = jsonEncode(data);
                    SwissChessAndroid.exportToFile(
                      Jni.androidActivity(
                        PlatformDispatcher.instance.engineId!,
                      ),
                      JString.fromString(jsonContent),
                      JString.fromString(filename),
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$filename" exported to Downloads'),
                      ),
                    );
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _duplicateTournament() {
    final TextEditingController titleController = TextEditingController(
      text: '${widget.tournament.title} (Copy)',
    );
    String duplicateType = 'Full Tournament';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Duplicate Tournament'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputTitle(text: 'Type:'),
                  DropdownButton<String>(
                    value: duplicateType,
                    isExpanded: true,
                    items: <String>['Full Tournament', 'Players only']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        duplicateType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputTitle(text: 'New Title:'),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter new tournament name',
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      Map<String, dynamic> json;
                      if (duplicateType == 'Full Tournament') {
                        json = widget.tournament.toJson();
                        json.update('createdAt', (value) => DateTime.now());
                      } else {
                        json = {
                          'title': titleController.text,
                          'createdAt': DateTime.now(),
                          'numberOfRounds': widget.tournament.numberOfRounds,
                          'players': widget.tournament.players
                              .map((p) => p.toJson())
                              .toList(),
                          'rounds': [],
                        };
                      }

                      json.remove('id'); // Ensure it's treated as a new entry
                      json['title'] = titleController.text;

                      final newTournament = Tournament.fromJson(json);
                      await _storage.updateTournament(newTournament);

                      if (mounted) {
                        Navigator.pop(context);
                        widget.onUpdate?.call(); // Refresh the home page list
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${newTournament.title}" created'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Duplicate'),
                ),
              ],
            );
          },
        );
      },
    );
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editTournament();
              } else if (value == 'delete') {
                _confirmDeleteTournament();
              } else if (value == 'export') {
                _exportTournament();
              } else if (value == 'duplicate') {
                _duplicateTournament();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 8),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Export'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
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
