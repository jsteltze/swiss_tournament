import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/player.dart';
import 'package:swiss_tournament/data/player_ratings.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/utils/colorx.dart';

class Round {
  final DateTime startedAt;
  DateTime? finishedAt;
  final List<Encounter> encounters;

  Round({List<Encounter>? encounters, DateTime? startedAt, this.finishedAt})
    : encounters = encounters ?? [],
      startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'encounters': encounters.map((e) => e.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
  };

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      encounters: (json['encounters'] as List<dynamic>?)
          ?.map((e) => Encounter.fromJson(e))
          .toList(),
      startedAt: DateTime.parse(json['startedAt']),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
    );
  }

  String toHtml(Tournament tournament, BuildContext ctx) {
    final bgColor = Theme.of(ctx).colorScheme.inversePrimary.toHexTriplet();
    final bgColor2 = Theme.of(ctx).colorScheme.surface.toHexTriplet();
    final secondary = Theme.of(ctx).colorScheme.secondary.toHexTriplet();
    int roundNum = tournament.rounds.indexOf(this);
    List<Player> players = tournament.players;
    String html =
        '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Pairings Round ${roundNum + 1}</title><style>th {padding: 5px; text-align: left; background-color: $bgColor; font-weight: initial;} td {padding: 5px;}</style></head><body><table style="border: 1px solid black; border-collapse: separate; font-family: sans-serif; border-radius: 10px; border-spacing: 0px;"><thead><tr><th colspan="10" style="text-align: center; border-radius: 10px 10px 0px 0px;"><strong>Pairings Round $roundNum</strong></th></tr><tr><th>Table</th><th style="text-align: right; color: $secondary;">#</th><th>White</th><th style="text-align: right; color: $secondary;">Score</th><th></th><th style="text-align: right; color: $secondary;">#</th><th>Black</th><th style="text-align: right; color: $secondary;">Score</th><th>Result</th></tr></thead><tbody>';
    for (int i = 0; i < encounters.length; i++) {
      var nameW = encounters[i].playerIdW == -1
          ? "<i style='color: $secondary;'>Bye</i>"
          : players[encounters[i].playerIdW].name;
      var nameB = encounters[i].playerIdB == -1
          ? "<i style='color: $secondary;'>Bye</i>"
          : players[encounters[i].playerIdB].name;
      var pointsW = PlayerRatings.getPoints(
        tournament.rounds,
        encounters[i].playerIdW,
        roundNum,
      );
      var pointsB = PlayerRatings.getPoints(
        tournament.rounds,
        encounters[i].playerIdB,
        roundNum,
      );
      html +=
          '<tr><td style="background-color: $bgColor2">${i + 1}</td><td style="color: $secondary; text-align: right;">${encounters[i].playerIdW == -1 ? '' : encounters[i].playerIdW + 1}</td><td>$nameW</td><td style="color: $secondary; text-align: right;">${encounters[i].playerIdW == -1 ? '' : '(${pointsW.toStringAsFixed(1)})'}</td><td style="background-color: $bgColor2">-</td><td style="color: $secondary; text-align: right;">${encounters[i].playerIdB == -1 ? '' : encounters[i].playerIdB + 1}</td><td>$nameB</td><td style="color: $secondary; text-align: right;">${encounters[i].playerIdB == -1 ? '' : '(${pointsB.toStringAsFixed(1)})'}</td><td style="background-color: $bgColor2; text-align: center; font-weight: bold;">${encounters[i].result.replaceAll('0.5', '\u{00BD}')}</td></tr>';
    }
    html += '</tbody></table></body></html>';
    return html;
  }
}
