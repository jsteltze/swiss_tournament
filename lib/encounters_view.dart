import 'dart:ui';

import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jni/jni.dart';
import 'package:swiss_tournament/data/tournament.dart';

import 'java.g.dart';
import 'single_encounter_view.dart';

class EncountersView extends StatefulWidget {
  final Tournament tournament;
  final int roundIndex;
  final VoidCallback? notifyRoundFinished;
  final VoidCallback? deleteRound;

  const EncountersView({
    super.key,
    required this.tournament,
    required this.roundIndex,
    this.notifyRoundFinished,
    this.deleteRound,
  });

  @override
  State<EncountersView> createState() => _EncountersViewState();
}

class _EncountersViewState extends State<EncountersView> {
  bool _filterOpen = false;

  void _exportRound(BuildContext ctx) {
    final round = widget.tournament.rounds[widget.roundIndex];
    final String htmlContent = round.toHtml(widget.tournament, ctx);
    final String filename =
        '${widget.tournament.title.replaceAll(' ', '_')}_round_${widget.roundIndex + 1}.html';

    Sample.exportToFile(
      Jni.androidActivity(PlatformDispatcher.instance.engineId!),
      JString.fromString(htmlContent),
      JString.fromString(filename),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$filename" exported to Downloads')),
    );
  }

  @override
  Widget build(BuildContext context) {
    var round = widget.tournament.rounds[widget.roundIndex];
    var encounters = round.encounters;
    var pairings = encounters.length;
    var open = encounters.where((e) => e.result == "").length;
    var duration = round.finishedAt?.difference(round.startedAt);

    return Column(
      children: [
        Text(
          "Pairings: ${pairings - open}/$pairings",
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        LinearProgressIndicator(value: 1.0 - open / pairings, minHeight: 5),
        const SizedBox(height: 10),
        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          value: _filterOpen,
          title: Text('filter open ($open)'),
          onChanged: (checked) => {
            setState(() {
              _filterOpen = checked!;
            }),
          },
        ),
        ...encounters
            .where((e) => _filterOpen ? e.result == "" : true)
            .map(
              (encounter) => SingleEncounterView(
                round: round,
                encounter: encounter,
                tournament: widget.tournament,
                updateParent: _update,
              ),
            ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                "Started at:",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(160),
                ),
              ),
            ),
            Text(
              "${DateFormat.yMMMd().format(round.startedAt)}, ${DateFormat.Hm().format(round.startedAt)}",
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.primary.withAlpha(160),
              ),
            ),
          ],
        ),
        if (round.finishedAt != null)
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  "Finished at:",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary.withAlpha(160),
                  ),
                ),
              ),
              Text(
                "${DateFormat.yMMMd().format(round.finishedAt!)}, ${DateFormat.Hm().format(round.finishedAt!)} (",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(160),
                ),
              ),
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.primary.withAlpha(160),
              ),
              Text(
                " ${duration?.pretty(tersity: DurationTersity.minute)})",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(160),
                ),
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  widget.deleteRound?.call();
                } else if (value == 'export') {
                  _exportRound(context);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.save_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Export Round'),
                      ],
                    ),
                  ),
                  if (widget.roundIndex == widget.tournament.rounds.length - 1)
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete Round',
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
        const SizedBox(height: 10),
      ],
    );
  }

  void _update() {
    setState(() {});
    if (widget.tournament.rounds[widget.roundIndex].encounters.every(
      (e) => e.result.isNotEmpty,
    )) {
      widget.notifyRoundFinished?.call();
    }
  }
}
