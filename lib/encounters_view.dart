import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/utils/export_handler.dart';
import 'package:swiss_tournament/utils/html_utils.dart';

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

  void _exportRound() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) async {
      final round = widget.tournament.rounds[widget.roundIndex];
      final String htmlContent = toHtmlRound(
        widget.tournament,
        round,
        context.mounted ? context : null,
        packageInfo,
      );
      final String filename =
          '${widget.tournament.title.replaceAll(' ', '_')}_round_${widget.roundIndex + 1}.html';

      await ExportHandler.exportToDownloads(context, filename, htmlContent);
    });
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
        if (round.acceleratedRoundVirtualPoints > 0.0)
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  "Baku Info:",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary.withAlpha(160),
                  ),
                ),
              ),
              Text(
                "This is an accelerated round.\nPlayers #1-#${(2 * widget.tournament.players.length) ~/ 4} have received ${round.acceleratedRoundVirtualPoints} virtual points.",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(160),
                ),
              ),
            ],
          ),
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
                  _exportRound();
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
                        Text('Export Round (HTML)'),
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
