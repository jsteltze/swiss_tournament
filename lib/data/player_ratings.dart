import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/player.dart';
import 'package:swiss_tournament/data/round.dart';
import 'package:swiss_tournament/data/tiebreak.dart';
import 'package:swiss_tournament/data/tournament.dart';

import '../utils/colorx.dart';
import '../utils/fide_utils.dart';

class PlayerRatings {
  final Player player;
  final int playerId;
  int? rank;
  int? wins;
  int? losses;
  int? draws;
  int? performance;
  double? points;
  double? tiebreak1;
  double? tiebreak2;
  String sharedPlace = "";

  PlayerRatings({required this.player, required this.playerId});

  void calculateRatings(Tournament t) {
    points = getPoints(t.rounds, playerId);
    switch (t.settings.tb1) {
      case Tiebreak.buchholz09:
      case Tiebreak.buchholz24:
        tiebreak1 = _getBuchholz(t.rounds, t.settings.tb1);
        break;
      case Tiebreak.soberg09:
      case Tiebreak.soberg24:
        tiebreak1 = _getSoBerg(t.rounds, t.settings.tb1);
        break;
      case Tiebreak.direct:
      case Tiebreak.no:
        tiebreak1 = 0.0;
        break;
    }
    switch (t.settings.tb2) {
      case Tiebreak.buchholz09:
      case Tiebreak.buchholz24:
        tiebreak2 = _getBuchholz(t.rounds, t.settings.tb2);
        break;
      case Tiebreak.soberg09:
      case Tiebreak.soberg24:
        tiebreak2 = _getSoBerg(t.rounds, t.settings.tb2);
        break;
      case Tiebreak.direct:
      case Tiebreak.no:
        tiebreak2 = 0.0;
        break;
    }
    wins = _getWins(t.rounds);
    losses = _getLosses(t.rounds);
    draws = _getDraws(t.rounds);
    //performance = _getPerformance2(t.rounds, t.players);
    performance = calcPerformance(t.rounds, t.players, playerId);
  }

  static double getPointsVirtualPlayer(
    double baseFromRealPlayer,
    int numFutureRounds,
  ) {
    // virtual player
    double points = baseFromRealPlayer; // start with same points as real player
    points += 0.0; // grant one "win"
    for (int r = 0; r < numFutureRounds; r++) {
      points += 0.5; // treat all other games as "draw"
    }
    return points;
  }

  static double getPoints(
    List<Round> rounds,
    int playerId, [
    int roundIndex = 99,
    bool treatForfeitAsDraw = false,
  ]) {
    double points = 0.0;

    // regular player
    for (int r = 0; r < rounds.length && r < roundIndex; r++) {
      bool playerOccurred = false;
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final game = rounds[r].encounters[e];
        if (game.playerIdW == playerId &&
            ["1-0", "+ -"].contains(game.result)) {
          // win (white)
          points += (game.playerIdB == -1 && treatForfeitAsDraw ? 0.5 : 1.0);
          playerOccurred = true;
          break;
        } else if (game.playerIdW == playerId && game.result == "0.5-0.5") {
          // draw (white)
          points += 0.5;
          playerOccurred = true;
          break;
        } else if (game.playerIdB == playerId && game.result == "0.5-0.5") {
          // draw (black)
          points += 0.5;
          playerOccurred = true;
          break;
        } else if (game.playerIdB == playerId &&
            ["0-1", "- +"].contains(game.result)) {
          // win (black)
          points += (game.playerIdW == -1 && treatForfeitAsDraw ? 0.5 : 1.0);
          playerOccurred = true;
          break;
        } else if (game.playerIdB == playerId || game.playerIdW == playerId) {
          playerOccurred = true;
          break;
        }
      }

      if (!playerOccurred && treatForfeitAsDraw) {
        points += 0.5;
      }
    }
    return points;
  }

  bool isBye(Encounter g) => ["+ -", "- +"].contains(g.result);

  double _getBuchholz(List<Round> rounds, Tiebreak tb) {
    var unplayedRoundEval = tb == Tiebreak.buchholz09
        ? (rounds, playerId, roundIndex) => getPointsVirtualPlayer(
            getPoints(rounds, playerId, roundIndex),
            rounds.length - roundIndex - 1,
          )
        : (rounds, playerId, roundIndex) => getPoints(rounds, playerId);
    var normalEval = tb == Tiebreak.buchholz09
        ? (rounds, playerId) => getPoints(rounds, playerId, 99, true)
        : (rounds, playerId) => getPoints(rounds, playerId);
    double eval(playerId, opponentsId, isUnplayedRound, rounds, roundIndex) =>
        opponentsId == -1 || isUnplayedRound
        ? unplayedRoundEval(rounds, playerId, roundIndex)
        : normalEval(rounds, opponentsId);

    double buchholz = 0.0;
    for (int r = 0; r < rounds.length; r++) {
      bool playerOccurred = false;
      for (var game in rounds[r].encounters) {
        if (game.playerIdW == playerId) {
          buchholz += eval(playerId, game.playerIdB, isBye(game), rounds, r);
          playerOccurred = true;
          break;
        } else if (game.playerIdB == playerId) {
          buchholz += eval(playerId, game.playerIdW, isBye(game), rounds, r);
          playerOccurred = true;
          break;
        }
      }
      if (!playerOccurred) {
        buchholz += unplayedRoundEval(rounds, playerId, r);
      }
    }
    return buchholz;
  }

  double _getSoBerg(List<Round> rounds, Tiebreak tb) {
    var unplayedRoundEval = tb == Tiebreak.soberg09
        ? (rounds, playerId, roundIndex) => getPointsVirtualPlayer(
            getPoints(rounds, playerId, roundIndex),
            rounds.length - roundIndex - 1,
          )
        : (rounds, playerId, roundIndex) => getPoints(rounds, playerId);
    var normalEval = tb == Tiebreak.soberg09
        ? (rounds, playerId) => getPoints(rounds, playerId, 99, true)
        : (rounds, playerId) => getPoints(rounds, playerId);
    double eval(playerId, opponentsId, isUnplayedRound, rounds, roundIndex) =>
        opponentsId == -1 || isUnplayedRound
        ? unplayedRoundEval(rounds, playerId, roundIndex)
        : normalEval(rounds, opponentsId);

    double soBerg = 0.0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final game = rounds[r].encounters[e];
        if (game.playerIdW == playerId) {
          if (["1-0", "+ -"].contains(game.result)) {
            soBerg += eval(playerId, game.playerIdB, isBye(game), rounds, r);
          } else if (game.result == "0.5-0.5") {
            soBerg +=
                eval(playerId, game.playerIdB, isBye(game), rounds, r) / 2.0;
          }
        } else if (game.playerIdB == playerId) {
          if (["0-1", "- +"].contains(game.result)) {
            soBerg += eval(playerId, game.playerIdW, isBye(game), rounds, r);
          } else if (game.result == "0.5-0.5") {
            soBerg +=
                eval(playerId, game.playerIdW, isBye(game), rounds, r) / 2.0;
          }
        }
      }
    }
    return soBerg;
  }

  int _getWins(List<Round> rounds) {
    int wins = 0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId &&
            ["1-0"].contains(encounter.result)) {
          wins++;
        } else if (encounter.playerIdB == playerId &&
            ["0-1"].contains(encounter.result)) {
          wins++;
        }
      }
    }
    return wins;
  }

  int _getLosses(List<Round> rounds) {
    int losses = 0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId &&
            ["0-1"].contains(encounter.result)) {
          losses++;
        } else if (encounter.playerIdB == playerId &&
            ["1-0"].contains(encounter.result)) {
          losses++;
        }
      }
    }
    return losses;
  }

  int _getDraws(List<Round> rounds) {
    int draws = 0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId && encounter.result == "0.5-0.5") {
          draws++;
        } else if (encounter.playerIdB == playerId &&
            encounter.result == "0.5-0.5") {
          draws++;
        }
      }
    }
    return draws;
  }

  int _getPerformance(List<Round> rounds, List<Player> players) {
    List<Player> opponentsWithRatings = [];
    int ratedWins = 0;
    int ratedLosses = 0;
    int ratedGames = 0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId) {
          if (encounter.playerIdB == -1 ||
              players[encounter.playerIdB].rating == 0) {
            continue;
          }
          opponentsWithRatings.add(players[encounter.playerIdB]);
          if (encounter.result == "1-0") {
            ratedWins++;
          } else if (encounter.result == "0-1") {
            ratedLosses++;
          }
          ratedGames++;
          continue;
        } else if (encounter.playerIdB == playerId) {
          if (encounter.playerIdW == -1 ||
              players[encounter.playerIdW].rating == 0) {
            continue;
          }
          opponentsWithRatings.add(players[encounter.playerIdW]);
          if (encounter.result == "0-1") {
            ratedWins++;
          } else if (encounter.result == "1-0") {
            ratedLosses++;
          }
          ratedGames++;
          continue;
        }
      }
    }
    int sumOfRatings = opponentsWithRatings.fold(0, (x, p) => x + p.rating);
    int perf = ((sumOfRatings + 400 * (ratedWins - ratedLosses)) / ratedGames)
        .round();
    if (ratedWins == 0) {
      perf -= 400;
    } else if (ratedLosses == 0) {
      perf += 400;
    }
    return perf;
  }

  int _getPerformance2(List<Round> rounds, List<Player> players) {
    List<int> opponentsWithRatings = [];
    var ratedScore = 0.0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId) {
          if (encounter.playerIdB == -1 ||
              players[encounter.playerIdB].rating == 0) {
            continue;
          }
          opponentsWithRatings.add(players[encounter.playerIdB].rating);
          if (encounter.result == "1-0") {
            ratedScore += 1.0;
          } else if (encounter.result == "0.5-0.5") {
            ratedScore += 0.5;
          }
          continue;
        } else if (encounter.playerIdB == playerId) {
          if (encounter.playerIdW == -1 ||
              players[encounter.playerIdW].rating == 0) {
            continue;
          }
          opponentsWithRatings.add(players[encounter.playerIdW].rating);
          if (encounter.result == "0-1") {
            ratedScore += 1.0;
          } else if (encounter.result == "0.5-0.5") {
            ratedScore += 0.5;
          }
          continue;
        }
      }
    }

    expectedScore(opponentRatings, ownRating) => opponentRatings.fold(
      0.0,
      (x, y) =>
          x +
          1.0 /
              (1.0 +
                  Math.pow(
                    10.0,
                    (y.toDouble() - ownRating.toDouble()) / 400.0,
                  )),
    );

    var lo = 0.0;
    var hi = 4000.0;
    var mid = 0.0;
    while (hi - lo > 0.001) {
      mid = (lo + hi) / 2.0;
      if (expectedScore(opponentsWithRatings, mid) < ratedScore) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return mid.round();
  }

  static String toHtml(
    Tournament tournament,
    List<PlayerRatings> ratings,
    BuildContext ctx,
  ) {
    final bgColor = Theme.of(ctx).colorScheme.inversePrimary.toHexTriplet();
    final bgColor2 = Theme.of(ctx).colorScheme.surface.toHexTriplet();
    final secondary = Theme.of(ctx).colorScheme.secondary.toHexTriplet();
    int roundNum = tournament.rounds.length;
    String html =
        '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Ranking after Round $roundNum</title><style>th {padding: 5px; text-align: left; vertical-align: bottom; background-color: $bgColor; font-weight: initial;} td {padding: 5px;} .arrow-up { border: solid green; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-80deg); -webkit-transform: rotate(-80deg); margin-bottom: 2px; } .arrow-down { border: solid red; border-width: 0 2px 2px 0; display: inline-block; padding: 3px; transform: rotate(-10deg); -webkit-transform: rotate(-10deg); margin-bottom: 2px; }</style></head><body><table style="border: 1px solid black; border-collapse: separate; font-family: sans-serif; border-radius: 10px; border-spacing: 0px;"><thead><tr><th colspan="10" style="text-align: center; border-radius: 10px 10px 0px 0px;"><strong>Ranking after Round $roundNum</strong></th></tr><tr><th style="text-align: right">#</th><th style="text-align: right;">Name</th><th style="writing-mode: sideways-lr;">Startrank</th><th>Rating</th><th style="text-align: right;">Perf.</th><th style="writing-mode: sideways-lr;">Games</th><th>W/D/L</th><th>Score</th><th>TB 1:<br>${tournament.settings.tb1.shortName}</th>${tournament.settings.tb2 != Tiebreak.no ? '<th>TB 2:<br>${tournament.settings.tb2.shortName}</th>' : ''}</tr></thead><tbody>';
    for (var r in ratings) {
      html +=
          '<tr><td style="background-color: $bgColor2; text-align: right;">${r.rank}</td><td style="background-color: $bgColor2; font-weight: bold; text-align: right;">${r.player.name}</td><td style="color: $secondary; text-align: right;">${r.playerId + 1}</td><td style="color: $secondary; text-align: right;">${r.player.rating == 0 ? 'N/A' : r.player.rating.toString()}</td><td style="text-align: right;">${r.player.rating > 0 && r.performance! > 0 ? '<i class="arrow-${r.player.rating < r.performance! ? 'up' : 'down'}"></i>' : ''} ${r.performance.toString()}</td><td style="color: $secondary; text-align: right;">${(r.wins! + r.losses! + r.draws!).toString()}</td><td style="color: $secondary; text-align: right;">${r.wins}/${r.draws}/${r.losses}</td><td style="background-color: $bgColor2; text-align: right; font-weight: bold;">${r.points!.toStringAsFixed(1)}</td><td style="text-align: right;">${tournament.settings.tb1.formatScore(r.tiebreak1!)}</td>${tournament.settings.tb2 != Tiebreak.no ? '<td style="text-align: right;">${tournament.settings.tb2.formatScore(r.tiebreak2!)}</td>' : ''}</tr>';
    }
    html += '</tbody></table></body></html>';
    return html;
  }
}
