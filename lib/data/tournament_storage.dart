import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tournament.dart';
import 'player.dart';
import 'round.dart';

class TournamentStorage {
  static Database? _database;
  static const String _tableName = 'tournaments';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tournament_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            numberOfRounds INTEGER,
            players TEXT,
            rounds TEXT
          )
        ''');
      },
    );
  }

  Future<List<Tournament>> loadTournaments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (i) {
      return Tournament(
        title: maps[i]['title'],
        numberOfRounds: maps[i]['numberOfRounds'],
        players: (jsonDecode(maps[i]['players']) as List)
            .map((e) => Player.fromJson(e))
            .toList(),
        rounds: maps[i]['rounds'] != null
            ? (jsonDecode(maps[i]['rounds']) as List)
                .map((e) => Round.fromJson(e))
                .toList()
            : [],
      );
    });
  }

  Future<void> saveTournaments(List<Tournament> tournaments) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableName);
      for (var t in tournaments) {
        await txn.insert(_tableName, {
          'title': t.title,
          'numberOfRounds': t.numberOfRounds,
          'players': jsonEncode(t.players.map((e) => e.toJson()).toList()),
          'rounds': jsonEncode(t.rounds.map((e) => e.toJson()).toList()),
        });
      }
    });
  }
}
