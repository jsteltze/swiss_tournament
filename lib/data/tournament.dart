import 'player.dart';

class Tournament {
  String title;
  int numberOfRounds;
  final List<Player> players;

  Tournament({
    required this.title,
    required this.numberOfRounds,
    List<Player>? players,
  }) : players = players ?? [] {
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
    'title': title,
    'numberOfRounds': numberOfRounds,
    'players': players.map((p) => p.toJson()).toList(),
  };

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      title: json['title'],
      numberOfRounds: json['numberOfRounds'],
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e))
          .toList(),
    );
  }
}
