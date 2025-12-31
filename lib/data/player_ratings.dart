import 'package:swiss_tournament/data/player.dart';

class PlayerRatings {
  final Player player;
  final int startIndex;
  int? rank;
  int? wins;
  int? losses;
  int? draws;
  double? points;
  double? buchholz;
  bool sharedPlace = false;

  PlayerRatings({required this.player, required this.startIndex});
}
