import 'package:flutter/material.dart';
import 'package:js_flutter/components/badge.dart';
import 'package:js_flutter/utils/timestampx.dart';
import 'package:swiss_tournament/data/tournament.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final Function(Tournament) onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          tournament.title,
          style: Theme.of(context).textTheme.titleMedium!
              .copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        subtitle: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .max,
          children: [
            SizedBox(
              width: double.maxFinite,
              child: Wrap(
                verticalDirection: .up,
                alignment: .spaceBetween,
                children: [
                  MyBadge(
                    'Rounds: ${tournament.numberOfRounds}',
                    icon: Icon(
                      Icons.list,
                      color: Theme.of(context).colorScheme.secondary
                          .withAlpha(100),
                      applyTextScaling: true,
                      size: 18,
                    ),
                    variant: .ghost,
                  ),
                  tournament.getStateBadge(),
                ],
              ),
            ),
            MyBadge(
              'Players: ${tournament.players.length}',
              icon: Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                applyTextScaling: true,
                size: 18,
              ),
              variant: .ghost,
            ),
            if (tournament.rounds.isNotEmpty)
              MyBadge(
                tournament.rounds[0].startedAt.dateSpan(
                  tournament.isFinished()
                      ? tournament.rounds.last.finishedAt
                      : null,
                ),
                icon: Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                  applyTextScaling: true,
                  size: 18,
                ),
                variant: .ghost,
              ),
            if (tournament.isFinished())
              MyBadge(
                'Winner: ${tournament.getWinner()}',
                icon: Icon(
                  Icons.emoji_events_outlined,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                  applyTextScaling: true,
                  size: 18,
                ),
                variant: .ghost,
              ),
          ],
        ),
        leading: Icon(
          Icons.emoji_events,
          color: Theme.of(context).colorScheme.secondary,
          applyTextScaling: true,
        ),
        trailing: Icon(
          Icons.navigate_next,
          color: Theme.of(context).colorScheme.secondary.withAlpha(100),
        ),
        onTap: () => onTap(tournament),
      ),
    );
  }
}
