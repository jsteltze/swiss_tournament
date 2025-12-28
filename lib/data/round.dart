import 'package:swiss_tournament/data/encounter.dart';

class Round {
  final int roundNum;
  final DateTime startedAt;
  DateTime? finishedAt;
  final List<Encounter> encounters;

  Round({
    required this.roundNum,
    List<Encounter>? encounters,
    DateTime? startedAt,
    this.finishedAt,
  }) : encounters = encounters ?? [],
       startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'roundNum': roundNum,
    'encounters': encounters.map((e) => e.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
  };

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      roundNum: json['roundNum'],
      encounters: (json['encounters'] as List<dynamic>?)
          ?.map((e) => Encounter.fromJson(e))
          .toList(),
      startedAt: DateTime.parse(json['startedAt']),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
    );
  }
}
