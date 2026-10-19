import 'package:flutter/material.dart';
import 'package:js_flutter/components/view_header.dart';
import 'package:swiss_tournament/data/tournament.dart';

class TournamentsViewHeader extends StatelessWidget {
  final List<Tournament> tournaments;
  final bool filterNotFinished;
  final Function(bool filterNotFinished) filterCallback;

  const TournamentsViewHeader(
    this.tournaments,
    this.filterNotFinished,
    this.filterCallback, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final countNotFinished = tournaments.where((t) => !t.isFinished()).length;
    return ViewHeader(
      padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
      Column(
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        children: [
          Text(
            'Tournaments: ${tournaments.length}',
            style: Theme.of(context).textTheme.titleLarge!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          if (countNotFinished > 0)
            Row(
              mainAxisAlignment: .end,
              spacing: 10,
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                  applyTextScaling: true,
                ),
                Text(
                  'Filter:',
                  style: Theme.of(context).textTheme.titleMedium!
                      .copyWith(color: Theme.of(context).colorScheme.secondary),
                ),
                FilterChip(
                  label: Text(
                    'not finished ($countNotFinished)',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  selected: filterNotFinished,
                  onSelected: filterCallback,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
