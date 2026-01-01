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

  static double getPoints(
    List<Round> rounds,
    int playerId, [
    int roundIndex = 99,
  ]) {
    double points = 0.0;
    for (int r = 0; r < rounds.length && r < roundIndex; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId &&
            (encounter.result == "1-0" || encounter.result == "+ -")) {
          // win (white)
          points += 1;
        } else if (encounter.playerIdW == playerId &&
            encounter.result == "0.5-0.5") {
          // draw (white)
          points += 0.5;
        } else if (encounter.playerIdB == playerId &&
            encounter.result == "0.5-0.5") {
          // draw (black)
          points += 0.5;
        } else if (encounter.playerIdB == playerId &&
            (encounter.result == "0-1" || encounter.result == "- +")) {
          // win (black)
          points += 1;
        }
      }
    }
    return points;
  }

  double _getBuchholz(List<Round> rounds) {
    var enemies = [];
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId && encounter.playerIdB != -1) {
          enemies.add(encounter.playerIdB);
        } else if (encounter.playerIdB == playerId &&
            encounter.playerIdW != -1) {
          enemies.add(encounter.playerIdW);
        }
      }
    }
    final buchholz = enemies
        .map((e) => getPoints(rounds, e))
        .fold(0.0, (a, b) => a + b);
    return buchholz;
  }

  double _getSoBerg(List<Round> rounds) {
    double soBerg = 0.0;
    var enemiesWin = [];
    var enemiesDraw = [];
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId && encounter.playerIdB != -1) {
          if (encounter.result == "1-0") {
            enemiesWin.add(encounter.playerIdB);
          }
          if (encounter.result == "0.5-0.5") {
            enemiesDraw.add(encounter.playerIdB);
          }
        } else if (encounter.playerIdB == playerId &&
            encounter.playerIdW != -1) {
          if (encounter.result == "0-1") {
            enemiesWin.add(encounter.playerIdW);
          }
          if (encounter.result == "0.5-0.5") {
            enemiesDraw.add(encounter.playerIdW);
          }
        }
      }
    }
    soBerg += enemiesWin
        .map((e) => getPoints(rounds, e))
        .fold(0.0, (a, b) => a + b);
    soBerg += enemiesDraw
        .map((e) => getPoints(rounds, e) / 2.0)
        .fold(0.0, (a, b) => a + b);
    return soBerg;
  }

  int _getWins(List<Round> rounds) {
    int wins = 0;
    for (int r = 0; r < rounds.length; r++) {
      for (int e = 0; e < rounds[r].encounters.length; e++) {
        final encounter = rounds[r].encounters[e];
        if (encounter.playerIdW == playerId &&
            (encounter.result == "1-0" || encounter.result == "+ -")) {
          wins++;
        } else if (encounter.playerIdB == playerId &&
            (encounter.result == "0-1" || encounter.result == "- +")) {
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
            (encounter.result == "0-1" || encounter.result == "- +")) {
          losses++;
        } else if (encounter.playerIdB == playerId &&
            (encounter.result == "1-0" || encounter.result == "+ -")) {
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
