import 'package:swiss_tournament/data/encounter.dart';

class Round {
  int roundNum;
  final List<Encounter> encounters;

  Round({required this.roundNum, List<Encounter>? encounters})
    : encounters = encounters ?? [];

  Map<String, dynamic> toJson() => {
    'roundNum': roundNum,
    'encounters': encounters.map((e) => e.toJson()).toList(),
  };

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      roundNum: json['roundNum'],
      encounters: (json['encounters'] as List<dynamic>?)
          ?.map((e) => Encounter.fromJson(e))
          .toList(),
    );
  }
}
