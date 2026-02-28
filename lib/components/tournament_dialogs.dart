import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jni/jni.dart';
import 'package:swiss_tournament/components/warning.dart';

import '../data/first_round_pairing.dart';
import '../data/tournament.dart';
import '../data/tournament_storage.dart';
import '../java.g.dart';
import 'description.dart';
import 'input_title.dart';

void showEditTournamentDialog(
  BuildContext context,
  Tournament? tournament,
  Function(Tournament) onSave,
) {
  final TextEditingController titleController = TextEditingController(
    text: tournament?.title,
  );
  final TextEditingController roundsController = TextEditingController(
    text: tournament?.numberOfRounds.toString(),
  );
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('${tournament == null ? 'New' : 'Edit'} Tournament'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a tournament title';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Tournament title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: roundsController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number of rounds';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (tournament != null &&
                      (int.parse(value) < tournament!.rounds.length)) {
                    return 'Must not be smaller than ${tournament!.rounds.length}';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Number of rounds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (tournament != null && tournament!.rounds.isNotEmpty) ...[
                const SizedBox(height: 20.0),
                Text(
                  "The tournament has started and is currently on round ${tournament!.rounds.length}. Thus the number of rounds cannot be changed to a value smaller than ${tournament!.rounds.length}!",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
                tournament ??= Tournament();
                tournament!.title = titleController.text;
                tournament!.numberOfRounds = int.parse(roundsController.text);
                tournament!.update();
                Navigator.pop(context);
                onSave(tournament!);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

void confirmDeleteTournament(
  BuildContext context,
  Tournament tournament,
  VoidCallback onDelete,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Tournament'),
        content: Text('Are you sure you want to delete "${tournament.title}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onDelete();
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

void showExportTournamentDialog(BuildContext context, Tournament tournament) {
  final TextEditingController filenameController = TextEditingController(
    text: 'tournament-${tournament.id ?? 'new'}',
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
                  'Export to Downloads folder. The saved file can serve as a backup or can be shared and imported on other devices.',
                ),
                const SizedBox(height: 16),
                const InputTitle(text: 'Type:'),
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
                const InputTitle(text: 'Filename:'),
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
              ElevatedButton(
                onPressed: () {
                  String filename = filenameController.text;
                  if (filename.isEmpty) return;
                  if (!filename.toLowerCase().endsWith('.json')) {
                    filename += '.json';
                  }

                  Map<String, dynamic> data;
                  if (exportType == 'Full Tournament') {
                    data = tournament.toJson();
                  } else {
                    data = {
                      'title': tournament.title,
                      'createdAt': tournament.createdAt.toIso8601String(),
                      'numberOfRounds': tournament.numberOfRounds,
                      'players': tournament.players
                          .map((p) => p.toJson())
                          .toList(),
                    };
                  }

                  final String jsonContent = jsonEncode(data);
                  SwissChessAndroid.exportToFile(
                    Jni.androidActivity(PlatformDispatcher.instance.engineId!),
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

void showDuplicateTournamentDialog(
  BuildContext context,
  Tournament tournament,
  TournamentStorage storage,
  VoidCallback onDuplicate,
) {
  final TextEditingController titleController = TextEditingController(
    text: '${tournament.title} (Copy)',
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
                const InputTitle(text: 'Type:'),
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
                const InputTitle(text: 'New Title:'),
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
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    Map<String, dynamic> json;
                    if (duplicateType == 'Full Tournament') {
                      json = tournament.toJson();
                      json['createdAt'] = DateTime.now().toIso8601String();
                    } else {
                      json = {
                        'title': titleController.text,
                        'createdAt': DateTime.now().toIso8601String(),
                        'numberOfRounds': tournament.numberOfRounds,
                        'players': tournament.players
                            .map((p) => p.toJson())
                            .toList(),
                        'rounds': [],
                        'settings': tournament.settings.toJson(),
                      };
                    }

                    json.remove('id'); // Ensure it's treated as a new entry
                    json['title'] = titleController.text;

                    final newTournament = Tournament.fromJson(json);
                    await storage.updateTournament(newTournament);

                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      onDuplicate();
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

void showAdvancedSettingsDialog(BuildContext context, Tournament tournament) {
  FirstRoundPairing currentPairing = tournament.settings.firstRoundPairing;
  int currentBaku = tournament.settings.baku;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Advanced Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InputTitle(text: 'First Round Pairing (Top Player):'),
                  DropdownButton<FirstRoundPairing>(
                    value: currentPairing,
                    isExpanded: true,
                    items: FirstRoundPairing.values.map((val) {
                      return DropdownMenuItem(
                        value: val,
                        child: Text(
                          val == FirstRoundPairing.white1
                              ? 'White'
                              : val == FirstRoundPairing.black1
                              ? 'Black'
                              : 'Random',
                        ),
                      );
                    }).toList(),
                    onChanged: tournament.rounds.isNotEmpty
                        ? null
                        : (newValue) {
                            setDialogState(() => currentPairing = newValue!);
                          },
                  ),
                  Description(currentPairing.description, isExpandable: true),
                  const SizedBox(height: 16.0),
                  const InputTitle(text: 'Accelerated Swiss (Baku):'),
                  DropdownButton<int>(
                    value: currentBaku,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 0, child: Text('Off')),
                      DropdownMenuItem(value: 1, child: Text('On')),
                    ],
                    onChanged: tournament.rounds.isNotEmpty
                        ? null
                        : (newValue) {
                            setDialogState(() => currentBaku = newValue!);
                          },
                  ),
                  Description(
                    'The Baku Acceleration Method (BAM) is a FIDE-approved pairing system for large Swiss-system chess tournaments designed to accelerate pairings between top-seeded players. It splits participants into two groups, adding virtual points to the top half to force matchups earlier, preventing high-ranked players from having low-scoring opponents in initial rounds.\nIn detail the systems works as follows: the first half of the rounds (rounded up) are accelerated. For the first half of the accelerated rounds (rounded up) the upper half of players receives a virtual point. For the second half of the accelerated rounds (rounded down) half a virtual point is granted to the upper half of players. The lower half of the players does not receive virtual points. After the accelerated rounds are played, the rest of the tournament will proceed normal.',
                    isExpandable: true,
                  ),
                  if (tournament.rounds.isNotEmpty) ...[
                    const SizedBox(height: 16.0),
                    Warning(
                      "This settings cannot be changed after the tournament has started!",
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: tournament.rounds.isNotEmpty
                    ? null
                    : () {
                        tournament.settings.firstRoundPairing = currentPairing;
                        tournament.settings.baku = currentBaku;
                        tournament.update();
                        Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
