import 'package:flutter/material.dart';
import 'package:swiss_tournament/utils/globals.dart';
import 'package:swiss_tournament/utils/timestampx.dart';

import '../data/player.dart';
import '../data/player_ratings.dart';
import '../data/round.dart';
import '../data/tiebreak.dart';
import '../data/tournament.dart';
import 'colorx.dart';

String toHtmlRound(Tournament tournament, Round r, BuildContext? ctx) {
  var html =
      '<tr><th>Table</th><th class="secondary" style="text-align: right;">#</th><th>White</th><th class="secondary" style="text-align: right;">Score</th><th></th><th class="secondary" style="text-align: right;">#</th><th>Black</th><th class="secondary" style="text-align: right;">Score</th><th>Result</th></tr></thead><tbody>';
  int roundNum = tournament.rounds.indexOf(r);
  List<Player> players = tournament.players;
  for (int i = 0; i < r.encounters.length; i++) {
    var nameW = r.encounters[i].playerIdW == -1
        ? "<i class='secondary'>Bye</i>"
        : players[r.encounters[i].playerIdW].name;
    var nameB = r.encounters[i].playerIdB == -1
        ? "<i class='secondary'>Bye</i>"
        : players[r.encounters[i].playerIdB].name;
    var pointsW = PlayerRatings.getPoints(
      tournament.rounds,
      r.encounters[i].playerIdW,
      roundNum,
    );
    var pointsB = PlayerRatings.getPoints(
      tournament.rounds,
      r.encounters[i].playerIdB,
      roundNum,
    );
    html +=
        '<tr><td class="highlighted">${i + 1}</td><td class="secondary" style="text-align: right;">${r.encounters[i].playerIdW == -1 ? '' : r.encounters[i].playerIdW + 1}</td><td>$nameW</td><td class="secondary" style="text-align: right;">${r.encounters[i].playerIdW == -1 ? '' : '(${pointsW.toStringAsFixed(1)})'}</td><td class="highlighted">-</td><td class="secondary" style="text-align: right;">${r.encounters[i].playerIdB == -1 ? '' : r.encounters[i].playerIdB + 1}</td><td>$nameB</td><td class="secondary" style="text-align: right;">${r.encounters[i].playerIdB == -1 ? '' : '(${pointsB.toStringAsFixed(1)})'}</td><td class="highlighted" style="text-align: center; font-weight: bold;">${r.encounters[i].result.replaceAll('0.5', '\u{00BD}')}</td></tr>';
  }
  return _toHtml(html, "Pairings Round ${roundNum + 1}", 9, ctx);
}

String toHtmlRanking(
  Tournament tournament,
  List<PlayerRatings> ratings,
  BuildContext? ctx,
) {
  var html =
      '<tr><th style="text-align: right">#</th><th style="text-align: right;">Name</th><th style="writing-mode: sideways-lr;">Startrank</th><th>Rating</th><th style="text-align: right;">Perf.</th><th style="writing-mode: sideways-lr;">Games</th><th>W/D/L</th><th>Score</th><th>TB 1:<br>${tournament.settings.tb1.shortName}</th>${tournament.settings.tb2 != Tiebreak.no ? '<th>TB 2:<br>${tournament.settings.tb2.shortName}</th>' : ''}</tr></thead><tbody>';
  int roundNum = tournament.rounds.length;
  for (var r in ratings) {
    String performanceArrow = "";
    if (r.player.rating > 0 && r.performance! > 0) {
      final diff = r.player.rating - r.performance!;
      if (diff >= 10) {
        performanceArrow = '<i class="arrow-up1"></i><i class="arrow-up2"></i>';
      } else if (diff <= -10) {
        performanceArrow =
            '<i class="arrow-down1"></i><i class="arrow-down2"></i>';
      } else {
        performanceArrow =
            '<i class="arrow-neutral1"></i><i class="arrow-neutral2"></i>';
      }
    }
    html +=
        '<tr><td class="highlighted" style="text-align: right;">${r.rank}</td><td class="highlighted" style="font-weight: bold; text-align: right;">${r.player.name}</td><td class="secondary" style="text-align: right;">${r.playerId + 1}</td><td class="secondary" style="text-align: right;">${r.player.rating == 0 ? 'N/A' : r.player.rating.toString()}</td><td style="text-align: right; white-space: nowrap;">$performanceArrow ${r.performance.toString()}</td><td class="secondary" style="text-align: right;">${(r.wins! + r.losses! + r.draws!).toString()}</td><td class="secondary" style="text-align: right;">${r.wins}/${r.draws}/${r.losses}</td><td class="highlighted" style="text-align: right; font-weight: bold;">${r.points!.toStringAsFixed(1)}</td><td style="text-align: right;">${tournament.settings.tb1.formatScore(r.tiebreak1!)}</td>${tournament.settings.tb2 != Tiebreak.no ? '<td style="text-align: right;">${tournament.settings.tb2.formatScore(r.tiebreak2!)}</td>' : ''}</tr>';
  }
  return _toHtml(html, "Ranking after Round $roundNum", 10, ctx);
}

String _toHtml(String innerHtml, String title, int cols, BuildContext? ctx) {
  final scheme = ctx != null
      ? Theme.of(ctx).colorScheme
      : ColorScheme.fromSeed(seedColor: Colors.deepPurple);
  final bgColor = scheme.inversePrimary.toHexTriplet();
  final bgColor2 = scheme.surface.toHexTriplet();
  final bgColor3 = scheme.secondaryContainer.toHexTriplet();
  final secondary = scheme.secondary.toHexTriplet();
  String html =
      '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>$title</title><style>.secondary {color: $secondary; } .highlighted { background-color: $bgColor2; } th {padding: 5px; text-align: left; vertical-align: bottom; background-color: $bgColor3; font-weight: initial; border-bottom: 1px solid $bgColor;} td {padding: 5px;} .arrow-up2 { border: solid green; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-80deg); -webkit-transform: rotate(-80deg); margin-bottom: 2px; } .arrow-down2 { border: solid red; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-10deg); -webkit-transform: rotate(-10deg); margin-bottom: 2px; } .arrow-up1 { right: -7px; top: -7px; position: absolute; height: 2px; box-shadow: inset 0 0 0 32px; transform: rotate(-32deg); width: 12px; transform-origin: right top; display: inline-block; position: relative; color: green; } .arrow-down1 { right: -7px; top: -3px; position: absolute; height: 2px; box-shadow: inset 0 0 0 32px; transform: rotate(37deg); width: 12px; transform-origin: right top; display: inline-block; position: relative; color: red; } .arrow-neutral1 { right: -7px; top: -5px; position: absolute; height: 2px; box-shadow: inset 0 0 0 32px; width: 12px; display: inline-block; position: relative; color: gray; } .arrow-neutral2 { border: solid gray; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-45deg); -webkit-transform: rotate(-45deg); margin-bottom: 2px; }</style></head><body><div style="display: inline-block;"><table style="border: 1px solid black; border-collapse: separate; font-family: sans-serif; border-radius: 10px; border-spacing: 0px; background-color: $bgColor2;"><thead><tr><th colspan="$cols" style="text-align: center; border-radius: 10px 10px 0px 0px; border-bottom: 1px solid black; background-color: $bgColor;"><strong>$title</strong></th></tr>';
  html += innerHtml;
  final createdBy =
      '<span style="font-style: italic; text-align: right; font-family: sans-serif; font-size: x-small; color: $secondary; display: block;">${Globals.packageInfo.appName} App v${Globals.packageInfo.version}<br>${DateTime.now().toHumanString()}</span>';
  html +=
      '</tbody><tfoot><tr><td colspan="$cols" style="border-top: 1px solid $bgColor; background-color: $bgColor3; border-radius: 0px 0px 10px 10px;"></td></tr></tfoot></table>$createdBy</div></body></html>';
  return html;
}
