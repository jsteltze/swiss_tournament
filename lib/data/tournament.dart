import 'player.dart';
import 'round.dart';

class TournamentSettings {
  String tiebreak1;
  String tiebreak2;

  static const tiebreakListTech = [
    'buchholz09',
    'buchholz24',
    'soberg09',
    'soberg24',
    'direct',
    'no',
  ];

  TournamentSettings({
    this.tiebreak1 = 'buchholz09',
    this.tiebreak2 = 'soberg09',
  });

  Map<String, dynamic> toJson() => {
    'tiebreak1': tiebreak1,
    'tiebreak2': tiebreak2,
  };

  factory TournamentSettings.fromJson(Map<String, dynamic> json) {
    return TournamentSettings(
      tiebreak1: json['tiebreak1'] ?? 'buchholz09',
      tiebreak2: json['tiebreak2'] ?? 'soberg09',
    );
  }
}

class Tournament {
  int? id;
  String title;
  int numberOfRounds;
  final List<Player> players;
  final List<Round> rounds;
  DateTime createdAt;
  TournamentSettings settings;
  Function update;

  Tournament({
    this.id,
    required this.title,
    required this.numberOfRounds,
    List<Player>? players,
    List<Round>? rounds,
    DateTime? createdAt,
    TournamentSettings? settings,
    Function? update,
  }) : players = players ?? [],
       rounds = rounds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       settings = settings ?? TournamentSettings(),
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
    'settings': settings.toJson(),
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
      settings: json['settings'] != null
          ? TournamentSettings.fromJson(json['settings'])
          : TournamentSettings(),
    );
  }
}
