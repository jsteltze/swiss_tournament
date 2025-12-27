import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/tournament.dart';

class EncountersView extends StatefulWidget {
  final Tournament tournament;
  final int roundIndex;

  const EncountersView({
    super.key,
    required this.tournament,
    required this.roundIndex,
  });

  @override
  State<EncountersView> createState() => _EncountersViewState();
}

class _EncountersViewState extends State<EncountersView> {
  @override
  Widget build(BuildContext context) {
    var encounters = widget.tournament.rounds[widget.roundIndex].encounters;
    var pairings = encounters.length;
    var open = encounters.where((e) => e.result == "").length;

    return Column(
      children: [
        Text("Pairings: ${pairings - open}/$pairings"),
        ...encounters.map(
          (encounter) => Material(
            color: encounter.result.isNotEmpty
                ? Theme.of(context).colorScheme.primary.withAlpha(10)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _showResultDialog(encounter),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      title: Text(
                        widget.tournament.players[encounter.playerIdW].name,
                      ),
                      subtitle: Text(
                        '#${encounter.playerIdW + 1} Rating: ${widget.tournament.players[encounter.playerIdW].rating}',
                      ),
                      leading: const Icon(Icons.person),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        encounter.result.isEmpty ? 'vs' : encounter.result,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        widget.tournament.players[encounter.playerIdB].name,
                      ),
                      subtitle: Text(
                        '#${encounter.playerIdB + 1} Rating: ${widget.tournament.players[encounter.playerIdB].rating}',
                      ),
                      trailing: const Icon(Icons.person),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (encounters.every((e) => e.result.isNotEmpty))
          ElevatedButton.icon(
            icon: Icon(Icons.play_arrow),
            label: Text('Start Round ${widget.roundIndex + 2}'),
            onPressed: () {},
          ),
      ],
    );
  }

  void _showResultDialog(Encounter encounter) {
    String? selectedResult =
        ["1-0", "0-1", "0.5-0.5"].contains(encounter.result)
        ? encounter.result
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Result'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter result for ${widget.tournament.players[encounter.playerIdW].name} vs ${widget.tournament.players[encounter.playerIdB].name}",
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedResult,
                    hint: const Text("Select result"),
                    items: const [
                      DropdownMenuItem(value: "1-0", child: Text("1-0")),
                      DropdownMenuItem(value: "0-1", child: Text("0-1")),
                      DropdownMenuItem(
                        value: "0.5-0.5",
                        child: Text("0.5-0.5"),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedResult = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (selectedResult != null) {
                      setState(() {
                        encounter.result = selectedResult!;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
