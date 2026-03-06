import 'package:flutter/material.dart';
import 'package:swiss_tournament/dialogs/longpress_popup_menu.dart';

import '../data/tournament.dart';
import '../data/tournament_storage.dart';
import 'tournament_dialogs.dart';

class TournamentPopupMenu extends StatelessWidget {
  final Tournament tournament;
  final TournamentStorage storage;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final Function(Tournament) onEdit;
  final Widget? child;

  const TournamentPopupMenu({
    super.key,
    this.child,
    required this.tournament,
    required this.storage,
    required this.onDelete,
    required this.onUpdate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Set<Set<void>> onSelected(value) => ({
      if (value == 'edit')
        {showEditTournamentDialog(context, tournament, onEdit)}
      else if (value == 'delete')
        {confirmDeleteTournament(context, tournament, onDelete)}
      else if (value == 'export')
        {showExportTournamentDialog(context, tournament)}
      else if (value == 'duplicate')
        {showDuplicateTournamentDialog(context, tournament, storage, onUpdate)}
      else if (value == 'advanced_settings')
        {showAdvancedSettingsDialog(context, tournament)},
    });

    List<PopupMenuItem<String>> itemBuilder(BuildContext context) {
      return [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'advanced_settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.save_alt, size: 20),
              SizedBox(width: 8),
              Text('Export'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ];
    }

    return child == null
        ? PopupMenuButton<String>(
            onSelected: onSelected,
            itemBuilder: itemBuilder,
          )
        : LongPressPopupMenu(
            items: itemBuilder(context),
            onSelected: onSelected,
            child: child!,
          );
  }
}
