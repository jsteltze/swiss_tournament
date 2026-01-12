import 'package:swiss_tournament/data/player.dart';
import 'package:swiss_tournament/data/round.dart';

class PlayerRatings {
  final Player player;
  final int playerId;
  int? rank;
  int? wins;
  int? losses;
  int? draws;
  double? points;
  double? buchholz;
  double? soBerg;
  String sharedPlace = "";

  PlayerRatings({required this.player, required this.playerId});

  void calculateRatings(List<Round> rounds) {
    points = getPoints(rounds, playerId);
    buchholz = _getBuchholz(rounds);
    soBerg = _getSoBerg(rounds);
    wins = _getWins(rounds);
    losses = _getLosses(rounds);
    draws = _getDraws(rounds);
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
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final game = rounds[r].encounters[e];
        if (game.playerIdW == playerId &&
            ["1-0", "+ -"].contains(game.result)) {
          // win (white)
          points += (game.playerIdB == -1 && treatForfeitAsDraw ? 0.5 : 1.0);
          break;
        } else if (game.playerIdW == playerId && game.result == "0.5-0.5") {
          // draw (white)
          points += 0.5;
          break;
        } else if (game.playerIdB == playerId && game.result == "0.5-0.5") {
          // draw (black)
          points += 0.5;
          break;
        } else if (game.playerIdB == playerId &&
            ["0-1", "- +"].contains(game.result)) {
          // win (black)
          points += (game.playerIdW == -1 && treatForfeitAsDraw ? 0.5 : 1.0);
          break;
        }
      }
    }
    return points;
  }

  double _getBuchholz(List<Round> rounds) {
    double buchholz = 0.0;
    for (int r = 0; r < rounds.length; r++) {
      bool playerOccurred = false;
      for (var game in rounds[r].encounters) {
        if (game.playerIdW == playerId) {
          if (game.playerIdB == -1) {
            buchholz += getPointsVirtualPlayer(
              getPoints(rounds, playerId, r - 1),
              rounds.length - 1 - r,
            );
          } else {
            buchholz += getPoints(rounds, game.playerIdB, 99, true);
          }
          playerOccurred = true;
          break;
        } else if (game.playerIdB == playerId) {
          if (game.playerIdW == -1) {
            buchholz += getPointsVirtualPlayer(
              getPoints(rounds, playerId, r - 1),
              rounds.length - 1 - r,
            );
          } else {
            buchholz += getPoints(rounds, game.playerIdW, 99, true);
          }
          playerOccurred = true;
          break;
        }
      }
      if (!playerOccurred) {
        buchholz += getPointsVirtualPlayer(
          getPoints(rounds, playerId, r - 1),
          rounds.length - 1 - r,
        );
      }
    }
    return buchholz;
  }

  double _getSoBerg(List<Round> rounds) {
    double soBerg = 0.0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId) {
          if (["1-0", "+ -"].contains(encounter.result)) {
            if (encounter.playerIdB == -1) {
              soBerg += getPointsVirtualPlayer(
                getPoints(rounds, playerId, r - 1),
                rounds.length - 1 - r,
              );
            } else {
              soBerg += getPoints(rounds, encounter.playerIdB);
            }
          } else if (encounter.result == "0.5-0.5") {
            if (encounter.playerIdB == -1) {
              soBerg +=
                  getPointsVirtualPlayer(
                    getPoints(rounds, playerId, r - 1),
                    rounds.length - 1 - r,
                  ) /
                  2;
            } else {
              soBerg += getPoints(rounds, encounter.playerIdB) / 2;
            }
          }
        } else if (encounter.playerIdB == playerId) {
          if (["0-1", "- +"].contains(encounter.result)) {
            if (encounter.playerIdW == -1) {
              soBerg += getPointsVirtualPlayer(
                getPoints(rounds, playerId, r - 1),
                rounds.length - 1 - r,
              );
            } else {
              soBerg += getPoints(rounds, encounter.playerIdW);
            }
          } else if (encounter.result == "0.5-0.5") {
            if (encounter.playerIdW == -1) {
              soBerg +=
                  getPointsVirtualPlayer(
                    getPoints(rounds, playerId, r - 1),
                    rounds.length - 1 - r,
                  ) /
                  2;
            } else {
              soBerg += getPoints(rounds, encounter.playerIdW) / 2;
            }
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
            ["1-0", "+ -"].contains(encounter.result)) {
          wins++;
        } else if (encounter.playerIdB == playerId &&
            ["0-1", "- +"].contains(encounter.result)) {
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
            ["0-1", "- +"].contains(encounter.result)) {
          losses++;
        } else if (encounter.playerIdB == playerId &&
            ["1-0", "+ -"].contains(encounter.result)) {
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
}
