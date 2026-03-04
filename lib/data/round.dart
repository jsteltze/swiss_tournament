import 'package:swiss_tournament/data/encounter.dart';

class Round {
  final DateTime startedAt;
  DateTime? finishedAt;
  final List<Encounter> encounters;
  final double acceleratedRoundVirtualPoints;

  Round({
    List<Encounter>? encounters,
    DateTime? startedAt,
    this.finishedAt,
    double? acceleratedRoundVirtualPoints,
  }) : encounters = encounters ?? [],
       startedAt = startedAt ?? DateTime.now(),
       acceleratedRoundVirtualPoints = acceleratedRoundVirtualPoints ?? 0.0;

  Map<String, dynamic> toJson() => {
    'encounters': encounters.map((e) => e.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
  };

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
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
