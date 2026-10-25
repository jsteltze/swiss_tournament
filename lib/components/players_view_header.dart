import 'package:flutter/material.dart';
import 'package:js_flutter/components/badge.dart';
import 'package:js_flutter/components/view_header.dart';
import 'package:swiss_tournament/data/tournament.dart';

import '../dialogs/rating_distribution_dialog.dart';

class PlayersViewHeader extends StatelessWidget {
  final Tournament tournament;

  const PlayersViewHeader(this.tournament, {super.key});

  @override
  Widget build(BuildContext context) {
    final int playersWithRating = tournament.players
        .where((p) => p.rating > 0)
        .length;
    double averageRating = 0;
    if (playersWithRating > 1) {
      averageRating =
          tournament.players
              .where((p) => p.rating > 0)
              .map((p) => p.rating)
              .fold(0, (a, b) => a + b) /
          playersWithRating;
    }

    return ViewHeader(
      Row(
        spacing: 15,
        children: [
          Icon(
            Icons.people,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  'Players: ${tournament.players.length}',
                  style: Theme.of(context).textTheme.titleLarge!
                      .copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                MyBadge(
                  'active: ${tournament.players.where((p) => p.leftAt == null).length}',
                ),
              ],
            ),
          ),
          if (playersWithRating > 1)
            TextButton(
              onPressed: () =>
                  openRatingDistributionDialog(tournament, context),
              child: Column(
                crossAxisAlignment: .end,
                children: [
                  Text(
                    'Average rating:',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  MyBadge(
                    '',
                    variant: .tertiary,
                    child: Stack(
                      alignment: .centerLeft,
                      children: [
                        Text(
                          'o',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                fontFamily: 'RobotoMono',
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                        Text(
                          '/',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                fontFamily: 'RobotoMono',
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                        Text(
                          '     ${averageRating.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
