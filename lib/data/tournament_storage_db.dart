import 'dart:convert';

import 'package:js_flutter/utils/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:swiss_tournament/data/tournament_storage.dart';

import 'tournament.dart';

class TournamentDB extends TournamentStorage {
  static Database? _database;
  static String? dbPath;
  static const String _tableName = 'tournaments';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    dbPath = await getDatabasesPath();
    final path = join(dbPath!, 'tournament_database.db');
    FileLogger.log('Initializing database at $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        FileLogger.log('Creating tournaments table');
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            createdAt TEXT,
            numberOfRounds INTEGER,
            players TEXT,
            rounds TEXT,
            settings TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<List<Tournament>> loadTournaments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    final list = List.generate(maps.length, (i) {
      return parseTournament(maps[i]);
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
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
          'settings': jsonEncode(t.settings.toJson()),
        });
      }
    });
  }

  @override
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

  @override
  Future<void> updateTournament(Tournament tournament) async {
    FileLogger.log(
      'Updating tournament: ${tournament.title} (ID: ${tournament.id})',
    );
    final db = await database;
    final values = {
      'title': tournament.title,
      'createdAt': tournament.createdAt.toIso8601String(),
      'numberOfRounds': tournament.numberOfRounds,
      'players': jsonEncode(tournament.players.map((e) => e.toJson()).toList()),
      'rounds': jsonEncode(tournament.rounds.map((e) => e.toJson()).toList()),
      'settings': jsonEncode(tournament.settings.toJson()),
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
      FileLogger.log('Inserted new tournament with ID: ${tournament.id}');
    }
  }

  @override
  String get storagePath => dbPath ?? '';
}
