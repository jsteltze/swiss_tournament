import 'package:swiss_tournament/data/tiebreak.dart';

import 'player.dart';
import 'round.dart';

class TournamentSettings {
  static const DEFAULT_TB1 = Tiebreak.buchholz09;
  static const DEFAULT_TB2 = Tiebreak.soberg09;

  Tiebreak tb1;
  Tiebreak tb2;

  TournamentSettings({this.tb1 = DEFAULT_TB1, this.tb2 = DEFAULT_TB2});

  Map<String, dynamic> toJson() => {
    if (tb1 != DEFAULT_TB1) 'tb1': tb1.name,
    if (tb2 != DEFAULT_TB2) 'tb2': tb2.name,
  };

  factory TournamentSettings.fromJson(Map<String, dynamic> json) {
    return TournamentSettings(
      tb1: json['tb1'] ?? DEFAULT_TB1,
      tb2: json['tb2'] ?? DEFAULT_TB2,
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
