import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';

import 'data/tournament.dart';
import 'java.g.dart';

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

List<RoundsPanel> generateItems(Tournament tournament) {
  int numberOfItems = 1;
  var playerRatings = tournament.players
      .map((player) => player.rating)
      .toList();
  JIntArray arr = JIntArray(playerRatings.length);
  arr.setRange(0, playerRatings.length, playerRatings);
  return List<RoundsPanel>.generate(numberOfItems, (int index) {
    return RoundsPanel(
      headerValue: 'Round ${index + 1}',
      expandedValue: ElevatedButton.icon(
        onPressed: () {
          var response = Sample.initTournament(
            Jni.androidActivity(PlatformDispatcher.instance.engineId!),
            JString.fromString("xxx"),
            arr,
            tournament.numberOfRounds,
          );
          print(response?.toDartString());
        },
        icon: Icon(Icons.play_arrow),
        label: Text('Start Round ${index + 1}'),
      ),
      isExpanded: index == numberOfItems - 1,
    );
  });
}

class RoundsView extends StatefulWidget {
  const RoundsView({super.key, required this.tournament});

  final Tournament tournament;

  @override
  State<RoundsView> createState() => _RoundsViewState();
}

class _RoundsViewState extends State<RoundsView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Container(child: _buildPanel()));
  }

  Widget _buildPanel() {
    final List<RoundsPanel> data = generateItems(widget.tournament);
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
          body: ListTile(
            title: item.expandedValue,
            subtitle: const Text(
              'To delete this panel, tap the trash can icon',
            ),
            trailing: const Icon(Icons.delete),
            onTap: () {
              setState(() {
                data.removeWhere(
                  (RoundsPanel currentItem) => item == currentItem,
                );
              });
            },
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}
