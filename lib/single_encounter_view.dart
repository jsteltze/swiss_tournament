import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/tournament.dart';

class SingleEncounterView extends StatefulWidget {
  final Encounter encounter;
  final Tournament tournament;

  const SingleEncounterView({
    super.key,
    required this.encounter,
    required this.tournament,
  });

  @override
  State<SingleEncounterView> createState() => _SingleEncounterViewState();
}

class _SingleEncounterViewState extends State<SingleEncounterView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.encounter.result.isNotEmpty
          ? Theme.of(context).colorScheme.primary.withAlpha(10)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _showResultDialog(widget.encounter),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ListTile(
                title: Text(
                  widget.tournament.players[widget.encounter.playerIdW].name,
                ),
                subtitle: Text(
                  '#${widget.encounter.playerIdW + 1} Rating: ${widget.tournament.players[widget.encounter.playerIdW].rating}',
                ),
                leading: const Icon(Icons.person),
              ),
            ),
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  widget.encounter.result.isEmpty
                      ? 'vs'
                      : widget.encounter.result,
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text(
                  widget.tournament.players[widget.encounter.playerIdB].name,
                ),
                subtitle: Text(
                  '#${widget.encounter.playerIdB + 1} Rating: ${widget.tournament.players[widget.encounter.playerIdB].rating}',
                ),
                trailing: const Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
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
