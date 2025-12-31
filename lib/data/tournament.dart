import 'player.dart';
import 'round.dart';

class Tournament {
  int? id;
  String title;
  int numberOfRounds;
  final List<Player> players;
  final List<Round> rounds;
  Function update;

  Tournament({
    this.id,
    required this.title,
    required this.numberOfRounds,
    List<Player>? players,
    List<Round>? rounds,
    Function? update,
  }) : players = players ?? [],
       rounds = rounds ?? [],
       update = update ?? (() {}) {
    sortPlayers();
  }

  void addPlayer(Player player) {
    players.add(player);
    if (rounds.isEmpty) sortPlayers();
  }

  void sortPlayers() {
    players.sort((a, b) => b.rating.compareTo(a.rating));
  }

  double getPoints(int playerId, int roundIndex) {
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

  double getBuchholz(int playerId) {
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
        .map((e) => getPoints(e, 99))
        .reduce((a, b) => a + b);
    return buchholz;
  }

  int getWins(int playerId) {
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

  int getLosses(int playerId) {
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

  int getDraws(int playerId) {
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'numberOfRounds': numberOfRounds,
    'players': players.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
  };

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      title: json['title'],
      numberOfRounds: json['numberOfRounds'],
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e))
          .toList(),
      rounds: (json['rounds'] as List<dynamic>?)
          ?.map((e) => Round.fromJson(e))
          .toList(),
    );
  }
}
