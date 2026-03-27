import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiss_tournament/components/warning.dart';

import '../components/description.dart';
import '../components/input_title.dart';
import '../data/first_round_pairing.dart';
import '../data/tournament.dart';
import '../data/tournament_storage.dart';
import '../utils/export_handler.dart';
import '../utils/snackbar_utils.dart';
import 'dialog_utils.dart';

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

  openDialog(
    context,
    title: '${tournament == null ? 'New' : 'Edit'} Tournament',
    titleIcon: Icon(tournament == null ? Icons.new_label_outlined : Icons.edit),
    child: (ctx, setDialogState) => Form(
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
            Warning(
              "The tournament has started and is currently on round ${tournament!.rounds.length}. Thus the number of rounds cannot be changed to a value smaller than ${tournament!.rounds.length}!",
            ),
          ],
        ],
      ),
    ),
    mainAction: DialogAction(
      title: 'Save',
      onPressed: () {
        if (formKey.currentState!.validate()) {
          final isAdding = tournament == null;
          tournament ??= Tournament();
          tournament!.title = titleController.text;
          tournament!.numberOfRounds = int.parse(roundsController.text);
          tournament!.update();
          Navigator.pop(context);
          onSave(tournament!);
          showSnackbar(
            context,
            'Tournament "${tournament!.title}" ${isAdding ? 'added' : 'edited'}',
          );
        }
      },
    ),
  );
}

void confirmDeleteTournament(
  BuildContext context,
  Tournament tournament,
  VoidCallback onDelete,
) {
  openDialog(
    context,
    title: 'Delete Tournament',
    titleIcon: Icon(Icons.delete),
    child: (ctx, setDialogState) =>
        Text('Are you sure you want to delete "${tournament.title}"?'),
    mainAction: DialogAction(
      title: 'Delete',
      onPressed: () {
        Navigator.pop(context);
        onDelete();
        showSnackbar(context, 'Tournament "${tournament.title}" deleted');
      },
      isDestructive: true,
    ),
  );
}

void showExportTournamentDialog(BuildContext context, Tournament tournament) {
  final TextEditingController filenameController = TextEditingController(
    text: 'tournament-${tournament.id ?? 'new'}',
  );
  String exportType = 'Full Tournament';

  openDialog(
    context,
    title: 'Export Tournament',
    titleIcon: Icon(Icons.save_alt),
    child: (ctx, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Description(
          'Export to Downloads folder. The saved file can serve as a backup or can be shared and imported on other devices.',
        ),
        const SizedBox(height: 16),
        const InputTitle('Type:'),
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
        Description(
          exportType == 'Full Tournament'
              ? 'The exported file will contain all tournament data, including the rounds and the results. This is a good choice for a backup or to share the tournament.'
              : 'The exported file will only contain the players list. This is a good choice if you want to start a new tournament with the same players.',
        ),
        const SizedBox(height: 16),
        const InputTitle('Filename:'),
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
    mainAction: DialogAction(
      title: 'Export',
      onPressed: () async {
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
            'players': tournament.players.map((p) => p.toJson()).toList(),
          };
        }

        final String jsonContent = jsonEncode(data);

        await ExportHandler.exportToDownloads(
          context,
          filename,
          jsonContent,
          () => Navigator.pop(context),
        );
      },
    ),
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

  openDialog(
    context,
    title: 'Duplicate Tournament',
    titleIcon: Icon(Icons.copy),
    child: (ctx, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputTitle('Type:'),
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
        Description(
          duplicateType == 'Full Tournament'
              ? 'The duplicated tournament will contain all tournament data, including the rounds and the results.'
              : 'The duplicated tournament will only contain the players list. This is a good choice if you want to start a new tournament with the same players.',
        ),
        const SizedBox(height: 16),
        const InputTitle('New Title:'),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter new tournament name',
          ),
          autofocus: true,
        ),
      ],
    ),
    mainAction: DialogAction(
      title: 'Duplicate',
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
              'players': tournament.players.map((p) => p.toJson()).toList(),
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
            showSnackbar(context, 'Tournament "${newTournament.title}" added');
          }
        }
      },
    ),
  );
}

void showAdvancedSettingsDialog(BuildContext context, Tournament tournament) {
  FirstRoundPairing currentPairing = tournament.settings.firstRoundPairing;
  int currentBaku = tournament.settings.baku;
  int currentBye = tournament.settings.bye;

  openDialog(
    context,
    title: 'Advanced Settings',
    titleIcon: Icon(Icons.settings),
    child: (ctx, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputTitle('First Round Pairing (Top Player):'),
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
        const InputTitle('Accelerated Swiss (Baku):'),
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
        const SizedBox(height: 16.0),
        const InputTitle('Allow requesting byes:'),
        DropdownButton<int>(
          value: currentBye,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 0, child: Text('0 (disabled)')),
            DropdownMenuItem(value: 1, child: Text('1')),
            DropdownMenuItem(value: 2, child: Text('2')),
            DropdownMenuItem(value: 3, child: Text('3')),
          ],
          onChanged: tournament.rounds.isNotEmpty
              ? null
              : (newValue) {
                  setDialogState(() => currentBye = newValue!);
                },
        ),
        Description(
          'If enabled players can request the selected number of half-point byes. By doing so they skip the round and receive half a point (as if they played a draw). Using a bye must be announced BEFORE the pairing of a round (there will be a selection dialog). Taking byes might be useful for the players (personal/organizational reasons, avoid scheduling conflicts) or can be used as a tactical instrument.\nThe requested half-point bye is not to be confused with the automatic bye (full point) due to an odd number of players.',
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
    mainAction: DialogAction(
      title: 'Save',
      onPressed: tournament.rounds.isNotEmpty
          ? null
          : () {
              tournament.settings.firstRoundPairing = currentPairing;
              tournament.settings.baku = currentBaku;
              tournament.settings.bye = currentBye;
              tournament.update();
              Navigator.pop(context);
              showSnackbar(context, 'Tournament settings saved');
            },
    ),
  );
}
