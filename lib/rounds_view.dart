import 'package:flutter/material.dart';
import 'package:swiss_tournament/single_round_view.dart';

import 'data/tournament.dart';

// stores ExpansionPanel state information
class RoundsPanel {
  RoundsPanel({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  Widget expandedValue;
  String headerValue;
  bool isExpanded;
}

List<RoundsPanel> generateItems(
  Tournament tournament,
  VoidCallback? onTournamentChanged,
) {
  int numberOfItems = 1;
  return List<RoundsPanel>.generate(numberOfItems, (int index) {
    return RoundsPanel(
      headerValue: 'Round ${index + 1}',
      expandedValue: SingleRound(
        tournament: tournament,
        roundIndex: index,
        onTournamentChanged: onTournamentChanged,
      ),
      isExpanded: index == numberOfItems - 1,
    );
  });
}

class RoundsView extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback? onTournamentChanged;

  const RoundsView({
    super.key,
    required this.tournament,
    this.onTournamentChanged,
  });

  @override
  State<RoundsView> createState() => _RoundsViewState();
}

class _RoundsViewState extends State<RoundsView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Container(child: _buildPanel()));
  }

  Widget _buildPanel() {
    final List<RoundsPanel> data = generateItems(
      widget.tournament,
      widget.onTournamentChanged,
    );
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          data[index].isExpanded = isExpanded;
        });
      },
      children: data.map<ExpansionPanel>((RoundsPanel item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(title: Text(item.headerValue));
          },
          body: item.expandedValue,
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}
