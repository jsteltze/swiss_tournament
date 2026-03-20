import 'dart:math';

import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/player.dart';
import 'package:swiss_tournament/data/round.dart';
import 'package:swiss_tournament/data/tiebreak.dart';
import 'package:swiss_tournament/data/tournament.dart';

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
              (1.0 + pow(10.0, (y.toDouble() - ownRating.toDouble()) / 400.0)),
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

  static void calculateRanks(
    List<PlayerRatings> ratings,
    Tournament tournament,
  ) {
    int comparePlayersAndSetSharedPlace(PlayerRatings a, PlayerRatings b) {
      var comparePoints = b.points!.compareTo(a.points!);
      if (comparePoints != 0) {
        return comparePoints;
      }
      var compareTb1 = b.tiebreak1!.compareTo(a.tiebreak1!);
      if (compareTb1 != 0) {
        return compareTb1;
      }
      var compareTb2 = b.tiebreak2!.compareTo(a.tiebreak2!);
      if (compareTb2 != 0) {
        return compareTb2;
      }

      a.sharedPlace =
          a.points!.toString() +
          a.tiebreak1!.toString() +
          a.tiebreak2!.toString();
      b.sharedPlace = a.sharedPlace;
      return 0;
    }

    // calculate the tiebreaks (other than 'direct')
    for (int r = 0; r < ratings.length; r++) {
      ratings[r].calculateRatings(tournament);
    }

    // sort by tiebreaks (other than 'direct')
    ratings.sort(comparePlayersAndSetSharedPlace);

    // post-calculate 'direct' tiebreak
    if (tournament.settings.tb1 == Tiebreak.direct ||
        tournament.settings.tb2 == Tiebreak.direct) {
      for (int r = 0; r < ratings.length; r++) {
        if (ratings[r].sharedPlace.isNotEmpty) {
          final sharedPlaceInfo = ratings[r].sharedPlace;
          final playerId = ratings[r].playerId;
          var opponents = ratings
              .where((e) => e.sharedPlace == sharedPlaceInfo)
              .where((e) => e.playerId != playerId)
              .map((e) => e.playerId)
              .toList();
          var direct = 0.0;
          for (int i = 0; i < opponents.length; i++) {
            for (var round in tournament.rounds) {
              for (var encounter in round.encounters) {
                if (encounter.playerIdW == playerId &&
                    encounter.playerIdB == opponents[i]) {
                  if (["1-0", "+ -"].contains(encounter.result)) {
                    direct += 1.0;
                  } else if (encounter.result == "0.5-0.5") {
                    direct += 0.5;
                  }
                }
                if (encounter.playerIdB == playerId &&
                    encounter.playerIdW == opponents[i]) {
                  if (["0-1", "- +"].contains(encounter.result)) {
                    direct += 1.0;
                  } else if (encounter.result == "0.5-0.5") {
                    direct += 0.5;
                  }
                }
              }
            }
          }
          if (tournament.settings.tb1 == Tiebreak.direct) {
            ratings[r].tiebreak1 = direct;
          }
          if (tournament.settings.tb2 == Tiebreak.direct) {
            ratings[r].tiebreak2 = direct;
          }
        } else {
          if (tournament.settings.tb1 == Tiebreak.direct) {
            ratings[r].tiebreak1 = 0.0;
          }
          if (tournament.settings.tb2 == Tiebreak.direct) {
            ratings[r].tiebreak2 = 0.0;
          }
        }
      }

      // sort again, this time 'direct' tiebreaks are set
      ratings.sort(comparePlayersAndSetSharedPlace);
    }

    // update rank according to the current order
    for (int r = 0; r < ratings.length; r++) {
      if (ratings[r].rank == null) {
        ratings[r].rank = r + 1;
      }
      if (ratings[r].sharedPlace.isNotEmpty) {
        final sharedPlaceInfo = ratings[r].sharedPlace;
        for (int i = r + 1; i < ratings.length; i++) {
          if (ratings[i].sharedPlace == sharedPlaceInfo) {
            ratings[i].rank = ratings[r].rank;
          } else {
            break;
          }
        }
      }
    }
  }
}
