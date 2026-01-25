import 'package:flutter_test/flutter_test.dart';
import 'package:swiss_tournament/data/encounter.dart';
import 'package:swiss_tournament/data/player.dart';
import 'package:swiss_tournament/data/player_ratings.dart';
import 'package:swiss_tournament/data/round.dart';
import 'package:swiss_tournament/data/tiebreak.dart';
import 'package:swiss_tournament/data/tournament.dart';

void main() {
  group('PlayerRatings Tests', () {
    final p0 = Player(name: 'TWL', rating: 1836);
    final p1 = Player(name: 'TS', rating: 1786);
    final p2 = Player(name: 'BS', rating: 1775);
    final p3 = Player(name: 'DB', rating: 1559);
    final p4 = Player(name: 'TH', rating: 1513);
    final p5 = Player(name: 'RP', rating: 1498);
    final p6 = Player(name: 'PD', rating: 1479);
    final p7 = Player(name: 'JV', rating: 1322);
    final p8 = Player(name: 'CJ', rating: 1217);
    final players = [p0, p1, p2, p3, p4, p5, p6, p7, p8];

    final rounds = [
      Round(
        encounters: [
          Encounter(playerIdW: 0, playerIdB: 4, result: '1-0'),
          Encounter(playerIdW: 5, playerIdB: 1, result: '0-1'),
          Encounter(playerIdW: 2, playerIdB: 6, result: '1-0'),
          Encounter(playerIdW: 7, playerIdB: 3, result: '0-1'),
          Encounter(playerIdW: 8, playerIdB: -1, result: '+ -'),
        ],
      ),
      Round(
        encounters: [
          Encounter(playerIdW: 3, playerIdB: 0, result: '0-1'),
          Encounter(playerIdW: 1, playerIdB: 8, result: '1-0'),
          Encounter(playerIdW: 4, playerIdB: 2, result: '0-1'),
          Encounter(playerIdW: 6, playerIdB: 5, result: '1-0'),
          Encounter(playerIdW: 7, playerIdB: -1, result: '+ -'),
        ],
      ),
      Round(
        encounters: [
          Encounter(playerIdW: 2, playerIdB: 1, result: '0-1'),
          Encounter(playerIdW: 0, playerIdB: 6, result: '1-0'),
          Encounter(playerIdW: 8, playerIdB: 7, result: '0-1'),
          Encounter(playerIdW: 5, playerIdB: 3, result: '0-1'),
          Encounter(playerIdW: 4, playerIdB: -1, result: '+ -'),
        ],
      ),
      Round(
        encounters: [
          Encounter(playerIdW: 1, playerIdB: 0, result: '0-1'),
          Encounter(playerIdW: 3, playerIdB: 2, result: '0-1'),
          Encounter(playerIdW: 7, playerIdB: 4, result: '0-1'),
          Encounter(playerIdW: 6, playerIdB: 8, result: '0.5-0.5'),
          Encounter(playerIdW: 5, playerIdB: -1, result: '+ -'),
        ],
      ),
      Round(
        encounters: [
          Encounter(playerIdW: 0, playerIdB: 2, result: '1-0'),
          Encounter(playerIdW: 1, playerIdB: 7, result: '1-0'),
          Encounter(playerIdW: 4, playerIdB: 3, result: '0.5-0.5'),
          Encounter(playerIdW: 8, playerIdB: 5, result: '1-0'),
          Encounter(playerIdW: 6, playerIdB: -1, result: '+ -'),
        ],
      ),
    ];

    test('calculateRatings', () {
      final expected = [
        [5.0, 5, 0, 0, 13.5, 13.5],
        [4.0, 4, 0, 1, 12.0, 7.0],
        [3.0, 3, 0, 2, 15.5, 6.5],
        [2.5, 2, 1, 2, 12.0, 3.0],
        [2.5, 1, 1, 2, 13.0, 3.75],
        [1.0, 0, 0, 4, 11.0, 0.5],
        [2.5, 1, 1, 2, 12.0, 3.0],
        [2.0, 1, 0, 3, 12.0, 3.5],
        [2.5, 1, 1, 2, 10.0, 3.5],
      ];

      Tournament t = Tournament(
        players: players,
        rounds: rounds,
        title: 'Test',
        numberOfRounds: 5,
      );
      t.settings.tb1 = Tiebreak.buchholz09;
      t.settings.tb2 = Tiebreak.soberg09;

      for (int p = 0; p < players.length; p++) {
        final ratings = PlayerRatings(player: players[p], playerId: p);
        ratings.calculateRatings(t);
        expect(ratings.points, expected[p][0]);
        expect(ratings.wins, expected[p][1]);
        expect(ratings.losses, expected[p][3]);
        expect(ratings.draws, expected[p][2]);
        expect(ratings.tiebreak1, expected[p][4]);
        expect(ratings.tiebreak2, expected[p][5]);
      }
    });
  });
}
