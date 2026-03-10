import 'dart:ui';

import 'package:jni/jni.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/utils/logger.dart';

import '../data/encounter.dart';
import '../data/round.dart';
import '../generated/java.g.dart';

Round callJavaFo(Tournament tournament) {
  bool bakuMode = tournament.settings.baku > 0;
  FileLogger.log('Starting JaVaFo pairing. bakuMode=$bakuMode');

  var trfFileContent = "";
  trfFileContent += "012 ${tournament.title}\n";
  trfFileContent += "022 City\n";
  trfFileContent += "032 GER\n";
  trfFileContent += "102 Arbiter\n";
  trfFileContent += "XXR ${tournament.numberOfRounds}\n";
  trfFileContent += "${tournament.settings.firstRoundPairing.javaFoCode}\n";
  final absentPlayers = tournament.players.where((p) => p.leftAt != null);
  if (absentPlayers.isNotEmpty) {
    final absentIds = absentPlayers
        .map((p) => tournament.players.indexOf(p) + 1)
        .map((id) => id.toString())
        .toList();
    trfFileContent += "XXZ ${absentIds.join(' ')}\n";
  }

  FileLogger.log('TRF Header generated');
  FileLogger.log(trfFileContent);

  for (int i = 1; i <= tournament.players.length; i++) {
    final player = tournament.players[i - 1];
    final padId = i.toString().padLeft(4, ' ');
    final padRating = player.rating.toString().padLeft(4, ' ');
    var points = 0.0;
    var roundInfoAll = "";
    for (int r = 0; r < tournament.rounds.length; r++) {
      var roundInfo = "";
      for (int e = 0; e < tournament.rounds[r].encounters.length; e++) {
        final encounter = tournament.rounds[r].encounters[e];
        if (encounter.playerIdW == i - 1 && encounter.result == "1-0") {
          // win (white)
          points += 1;
          roundInfo = "${encounter.playerIdB + 1} w 1";
        } else if (encounter.playerIdW == i - 1 && encounter.result == "+ -") {
          // opponent missing (white)
          points += 1;
          roundInfo = "${encounter.playerIdB + 1} w +";
        } else if (encounter.playerIdW == i - 1 && encounter.result == "0-1") {
          // lose (white)
          roundInfo = "${encounter.playerIdB + 1} w 0";
        } else if (encounter.playerIdW == i - 1 && encounter.result == "- +") {
          // self missing (white)
          roundInfo = "${encounter.playerIdB + 1} w -";
        } else if (encounter.playerIdB == i - 1 && encounter.result == "0-1") {
          // win (black)
          points += 1;
          roundInfo = "${encounter.playerIdW + 1} b 1";
        } else if (encounter.playerIdB == i - 1 && encounter.result == "- +") {
          // opponent missing (black)
          points += 1;
          roundInfo = "${encounter.playerIdW + 1} b +";
        } else if (encounter.playerIdB == i - 1 && encounter.result == "1-0") {
          // lose (black)
          roundInfo = "${encounter.playerIdW + 1} b 0";
        } else if (encounter.playerIdB == i - 1 && encounter.result == "+ -") {
          // self missing (black)
          roundInfo = "${encounter.playerIdW + 1} b -";
        } else if (encounter.playerIdW == i - 1 &&
            encounter.result == "0.5-0.5") {
          // draw (white)
          points += 0.5;
          roundInfo = "${encounter.playerIdB + 1} w =";
        } else if (encounter.playerIdB == i - 1 &&
            encounter.result == "0.5-0.5") {
          // draw (black)
          points += 0.5;
          roundInfo = "${encounter.playerIdW + 1} b =";
        }
      }
      roundInfo = roundInfo.padLeft(10, ' ');
      roundInfoAll += roundInfo;
    }
    final padPoints = points.toStringAsFixed(1).padLeft(4, ' ');
    var line =
        "001 $padId m    Playername                        $padRating GER     2212072 1981       $padPoints $padId$roundInfoAll";
    trfFileContent += '$line\n';
    FileLogger.log(line);
  }

  double virtualPointsForThisRound = 0.0;
  if (bakuMode) {
    int numberOfAcceleratedRounds = (tournament.numberOfRounds + 1) ~/ 2;
    int numberOfVirtualPointsFull = (numberOfAcceleratedRounds + 1) ~/ 2;
    int numberOfVirtualPointsHalf =
        numberOfAcceleratedRounds - numberOfVirtualPointsFull;
    if (tournament.rounds.length < numberOfVirtualPointsFull) {
      virtualPointsForThisRound = 1.0;
    } else if (tournament.rounds.length < numberOfAcceleratedRounds) {
      virtualPointsForThisRound = 0.5;
    }
    int playersGA = (2 * tournament.players.length) ~/ 4;
    int playerId = 1;
    for (; playerId <= playersGA; playerId++) {
      final padId = playerId.toString().padLeft(4, ' ');
      var line = "XXA $padId";
      for (int r = 0; r < numberOfVirtualPointsFull; r++) {
        line += "  1.0";
      }
      for (int r = 0; r < numberOfVirtualPointsHalf; r++) {
        line += "  0.5";
      }
      line += "\n";
      FileLogger.log(line);
      trfFileContent += line;
    }
    for (; playerId <= tournament.players.length; playerId++) {
      final padId = playerId.toString().padLeft(4, ' ');
      var line = "XXA $padId";
      for (int r = 0; r < numberOfAcceleratedRounds; r++) {
        line += "  0.0";
      }
      line += "\n";
      FileLogger.log(line);
      trfFileContent += line;
    }
  }

  FileLogger.log('Calling JaVaFo API...');
  var response = SwissChessAndroid.jaVaFoApi(
    Jni.androidActivity(PlatformDispatcher.instance.engineId!),
    bakuMode ? 1001 : 1000,
    JString.fromString(trfFileContent),
  );

  var respStr = response!.toDartString();
  FileLogger.log('JaVaFo Response received: $respStr');
  var lines = respStr.split('\n');
  var round = Round(acceleratedRoundVirtualPoints: virtualPointsForThisRound);
  for (var i = 1; i < lines.length; i++) {
    var line = lines[i];
    if (line.isEmpty) {
      continue;
    }
    FileLogger.log('line=$line');
    var parts = line.split(' ');
    var encounter = Encounter(
      playerIdW: int.parse(parts[0]) - 1,
      playerIdB: int.parse(parts[1]) - 1,
    );
    if (encounter.playerIdW == -1) {
      encounter.result = "- +";
    }
    if (encounter.playerIdB == -1) {
      encounter.result = "+ -";
    }
    round.encounters.add(encounter);
  }
  response.release();
  FileLogger.log(
    'Round pairing completed with ${round.encounters.length} encounters',
  );
  return round;
}
