import 'package:js_flutter/components/number_card.dart';
import 'package:js_flutter/components/view_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swiss_tournament/data/tournament.dart';

enum TournamentFilter { all, inProgress, finished }

class TournamentsViewHeader extends StatefulWidget {
  final List<Tournament> tournaments;
  final TournamentFilter initialFilter;
  final Function(TournamentFilter) filterCallback;

  const TournamentsViewHeader(
    this.tournaments,
    this.initialFilter,
    this.filterCallback, {
    super.key,
  });

  @override
  State<TournamentsViewHeader> createState() => _TournamentsViewHeaderState();
}

class _TournamentsViewHeaderState extends State<TournamentsViewHeader> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final countNotFinished = widget.tournaments
        .where((t) => !t.isFinished())
        .length;
    return ViewHeader(
      padding: EdgeInsets.all(0),
      Column(
        children: [
          ExpansionTile(
            title: Text(
              'YOUR TOURNAMENTS',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: .normal,
              ),
            ),
            shape: const Border(),
            onExpansionChanged: (x) {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          IntrinsicHeight(
            child: Row(
              spacing: 8,
              children: [
                SizedBox(width: 8),
                NumberCard(
                  widget.tournaments.length.toString(),
                  isExpanded: _isExpanded,
                  isSelected: widget.initialFilter == .all,
                  onSelect: () {
                    widget.filterCallback.call(.all);
                  },
                  label: 'All',
                  icon: Icon(
                    Icons.emoji_events_outlined,
                    applyTextScaling: true,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                NumberCard(
                  countNotFinished.toString(),
                  isExpanded: _isExpanded,
                  isSelected: widget.initialFilter == .inProgress,
                  onSelect: () {
                    widget.filterCallback.call(.inProgress);
                  },
                  label: 'In Progress',
                  variant: .green,
                  icon: Icon(
                    Icons.change_circle,
                    applyTextScaling: true,
                    color: Colors.green,
                  ),
                ),
                NumberCard(
                  (widget.tournaments.length - countNotFinished).toString(),
                  label: 'Finished',
                  isExpanded: _isExpanded,
                  isSelected: widget.initialFilter == .finished,
                  onSelect: () {
                    widget.filterCallback.call(.finished);
                  },
                  icon: Icon(
                    Icons.check,
                    applyTextScaling: true,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}
