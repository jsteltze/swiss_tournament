import 'player.dart';
import 'round.dart';

class Tournament {
  int? id;
  String title;
  int numberOfRounds;
  final List<Player> players;
  final List<Round> rounds;
  DateTime createdAt;
  Function update;

  Tournament({
    this.id,
    required this.title,
    required this.numberOfRounds,
    List<Player>? players,
    List<Round>? rounds,
    DateTime? createdAt,
    Function? update,
  }) : players = players ?? [],
       rounds = rounds ?? [],
       createdAt = createdAt ?? DateTime.now(),
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

  bool isFinished() {
    return rounds.length == numberOfRounds && rounds.last.finishedAt != null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'numberOfRounds': numberOfRounds,
    'players': players.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
