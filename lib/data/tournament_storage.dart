import 'package:swiss_tournament/data/tournament.dart';

abstract class TournamentStorage {
  Future<List<Tournament>> loadTournaments();

  Future<void> saveTournaments(List<Tournament> tournaments);

  Future<Tournament?> getTournament(int id);

  Future<void> updateTournament(Tournament tournament);

  String get storagePath;
}
