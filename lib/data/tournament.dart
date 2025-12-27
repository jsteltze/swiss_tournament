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
    _sortPlayers();
  }

  void addPlayer(Player player) {
    players.add(player);
    _sortPlayers();
  }

  void _sortPlayers() {
    players.sort((a, b) => b.rating.compareTo(a.rating));
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
