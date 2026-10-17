import 'dart:convert';

import 'package:swiss_tournament/data/player.dart';
import 'package:swiss_tournament/data/round.dart';
import 'package:swiss_tournament/data/tournament.dart';

abstract class TournamentStorage {
  Future<List<Tournament>> loadTournaments();

  Future<void> saveTournaments(List<Tournament> tournaments);

  Future<Tournament?> getTournament(int id);

  Future<void> updateTournament(Tournament tournament);

  String get storagePath;

  Tournament parseTournament(Map<String, dynamic> json) {
    var t = Tournament(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      numberOfRounds: json['numberOfRounds'],
      players: (jsonDecode(json['players']) as List)
          .map((e) => Player.fromJson(e))
          .toList(),
      rounds: json['rounds'] != null
          ? (jsonDecode(json['rounds']) as List)
                .map((e) => Round.fromJson(e))
                .toList()
          : [],
      settings: json['settings'] != null
          ? (TournamentSettings.fromJson(jsonDecode(json['settings'])))
          : TournamentSettings(),
    );
    t.update = () => updateTournament(t);

    if (t.settings.baku > 0) {
      for (var r in t.rounds) {
        r.acceleratedRoundVirtualPoints = Round.calculateVirtualPoints(
          t.numberOfRounds,
          t.rounds.indexOf(r),
        );
      }
    }

    return t;
  }
}
