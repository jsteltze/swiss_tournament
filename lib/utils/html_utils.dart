import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/player.dart';
import '../data/player_ratings.dart';
import '../data/round.dart';
import '../data/tiebreak.dart';
import '../data/tournament.dart';
import 'colorx.dart';

String toHtmlRound(
  Tournament tournament,
  Round r,
  BuildContext? ctx,
  PackageInfo info,
) {
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
  return _toHtml(html, "Pairings Round ${roundNum + 1}", 9, ctx, info);
}

String toHtmlRanking(
  Tournament tournament,
  List<PlayerRatings> ratings,
  BuildContext? ctx,
  PackageInfo info,
) {
  var html =
      '<tr><th style="text-align: right">#</th><th style="text-align: right;">Name</th><th style="writing-mode: sideways-lr;">Startrank</th><th>Rating</th><th style="text-align: right;">Perf.</th><th style="writing-mode: sideways-lr;">Games</th><th>W/D/L</th><th>Score</th><th>TB 1:<br>${tournament.settings.tb1.shortName}</th>${tournament.settings.tb2 != Tiebreak.no ? '<th>TB 2:<br>${tournament.settings.tb2.shortName}</th>' : ''}</tr></thead><tbody>';
  int roundNum = tournament.rounds.length;
  for (var r in ratings) {
    html +=
        '<tr><td class="highlighted" style="text-align: right;">${r.rank}</td><td class="highlighted" style="font-weight: bold; text-align: right;">${r.player.name}</td><td class="secondary" style="text-align: right;">${r.playerId + 1}</td><td class="secondary" style="text-align: right;">${r.player.rating == 0 ? 'N/A' : r.player.rating.toString()}</td><td style="text-align: right;">${r.player.rating > 0 && r.performance! > 0 ? '<i class="arrow-${r.player.rating < r.performance! ? 'up' : 'down'}"></i>' : ''} ${r.performance.toString()}</td><td class="secondary" style="text-align: right;">${(r.wins! + r.losses! + r.draws!).toString()}</td><td class="secondary" style="text-align: right;">${r.wins}/${r.draws}/${r.losses}</td><td class="highlighted" style="text-align: right; font-weight: bold;">${r.points!.toStringAsFixed(1)}</td><td style="text-align: right;">${tournament.settings.tb1.formatScore(r.tiebreak1!)}</td>${tournament.settings.tb2 != Tiebreak.no ? '<td style="text-align: right;">${tournament.settings.tb2.formatScore(r.tiebreak2!)}</td>' : ''}</tr>';
  }
  return _toHtml(html, "Ranking after Round $roundNum", 10, ctx, info);
}

String _toHtml(
  String innerHtml,
  String title,
  int cols,
  BuildContext? ctx,
  PackageInfo info,
) {
  final scheme = ctx != null
      ? Theme.of(ctx).colorScheme
      : ColorScheme.fromSeed(seedColor: Colors.deepPurple);
  final bgColor = scheme.inversePrimary.toHexTriplet();
  final bgColor2 = scheme.surface.toHexTriplet();
  final secondary = scheme.secondary.toHexTriplet();
  String html =
      '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>$title</title><style>.secondary {color: $secondary; } .highlighted { background-color: $bgColor2; } th {padding: 5px; text-align: left; vertical-align: bottom; background-color: $bgColor; font-weight: initial;} td {padding: 5px;} .arrow-up { border: solid green; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-80deg); -webkit-transform: rotate(-80deg); margin-bottom: 2px; } .arrow-down { border: solid red; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-10deg); -webkit-transform: rotate(-10deg); margin-bottom: 2px; }</style></head><body><div style="display: inline-block;"><table style="border: 1px solid black; border-collapse: separate; font-family: sans-serif; border-radius: 10px; border-spacing: 0px;"><thead><tr><th colspan="$cols" style="text-align: center; border-radius: 10px 10px 0px 0px;"><strong>$title</strong></th></tr>';
  html += innerHtml;
  final createdBy =
      '<span style="font-style: italic; text-align: right; font-family: sans-serif; font-size: x-small; color: $secondary; display: block;">${info.appName} App v${info.version}<br>${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}</span>';
  html += '</tbody></table>$createdBy</div></body></html>';
  return html;
}
