enum Tiebreak {
  buchholz09(
    longName: 'Buchholz (FIDE 2009)',
    shortName: 'Buchholz',
    description:
        'Buchholz tiebreak: this is the sum of all opponent scores (independent from the result). FIDE 2009 rule: if an opponent has unplayed rounds the forfeit win only counts 0.5 points. If the player self has unplayed round, a virtual opponent is introduced, which has an equal score.',
  ),
  buchholz24(
    longName: 'Buchholz (FIDE 2024)',
    shortName: 'Buchholz',
    description:
        'Buchholz tiebreak: this is the sum of all opponent scores (independent from the result). FIDE 2024 rule: if an opponent has unplayed rounds the forfeit win counts as 1 regular point. If the player self has unplayed round, for each of them the own score is used.',
  ),
  soberg09(
    longName: 'Sonneborn-Berger (FIDE 2009)',
    shortName: 'SoBerg',
    description:
        'Sonneborn-Berger tiebreak: calculated the same way as Buchholz, but the opponents score is weighted with the result (factor 1.0 if won, factor 0.5 if draw, factor 0 if lost).',
  ),
  soberg24(
    longName: 'Sonneborn-Berger (FIDE 2024)',
    shortName: 'SoBerg',
    description:
        'Sonneborn-Berger tiebreak: calculated the same way as Buchholz, but the opponents score is weighted with the result (factor 1.0 if won, factor 0.5 if draw, factor 0 if lost).',
  ),
  direct(
    longName: 'Direct Encounter',
    shortName: 'Direct',
    description:
        'Direct Encounter tiebreak: for players sharing the same rank, this is the result of their direct encounter (if possible). If multiple players share the same rank the direct encounter score can be >1. If the players did not have a direct encounter the value remains 0.',
  ),
  no(
    longName: 'No Tiebreak',
    shortName: 'No',
    description: 'No Tiebreak: no tiebreak is used. Shared ranks are possible.',
  );

  const Tiebreak({
    required this.longName,
    required this.shortName,
    required this.description,
  });

  final String longName;
  final String shortName;
  final String description;
}
