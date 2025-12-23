import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tournament.dart';

class TournamentStorage {
  static const _key = 'tournaments';

  Future<List<Tournament>> loadTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Tournament.fromJson(e)).toList();
  }

  Future<void> saveTournaments(List<Tournament> tournaments) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(tournaments.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
