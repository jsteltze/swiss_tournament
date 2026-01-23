import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'player.dart';
import 'round.dart';
import 'tournament.dart';

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
            createdAt TEXT,
            numberOfRounds INTEGER,
            players TEXT,
            rounds TEXT
          )
        ''');
      },
    );
  }

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
    );
    t.update = () => updateTournament(t);
    return t;
  }

  Future<List<Tournament>> loadTournaments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (i) {
      return parseTournament(maps[i]);
    });
  }

  Future<void> saveTournaments(List<Tournament> tournaments) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableName);
      for (var t in tournaments) {
        await txn.insert(_tableName, {
          'title': t.title,
          'createdAt': t.createdAt.toIso8601String(),
          'numberOfRounds': t.numberOfRounds,
          'players': jsonEncode(t.players.map((e) => e.toJson()).toList()),
          'rounds': jsonEncode(t.rounds.map((e) => e.toJson()).toList()),
        });
      }
    });
  }

  Future<Tournament?> getTournament(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return parseTournament(maps[0]);
    }
    return null;
  }

  Future<void> updateTournament(Tournament tournament) async {
    print('updateTournament');
    final db = await database;
    final values = {
      'title': tournament.title,
      'createdAt': tournament.createdAt.toIso8601String(),
      'numberOfRounds': tournament.numberOfRounds,
      'players': jsonEncode(tournament.players.map((e) => e.toJson()).toList()),
      'rounds': jsonEncode(tournament.rounds.map((e) => e.toJson()).toList()),
    };

    if (tournament.id != null) {
      await db.update(
        _tableName,
        values,
        where: 'id = ?',
        whereArgs: [tournament.id],
      );
    } else {
      tournament.id = await db.insert(_tableName, values);
    }
  }
}
