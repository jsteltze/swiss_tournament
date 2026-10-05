import 'package:flutter/material.dart';
import 'package:js_flutter/components/longpress_popup_menu.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';

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
    final items = [
      DialogAction(
        title: 'Edit',
        icon: editIcon,
        onPressed: () => showEditTournamentDialog(context, tournament, onEdit),
      ),
      DialogAction(
        title: 'Settings',
        icon: settingsIcon,
        onPressed: () => showAdvancedSettingsDialog(context, tournament),
      ),
      DialogAction(
        title: 'Duplicate',
        icon: copyIcon,
        onPressed: () => showDuplicateTournamentDialog(
          context,
          tournament,
          storage,
          onUpdate,
        ),
      ),
      DialogAction(
        title: 'Export',
        icon: exportIcon,
        onPressed: () => showExportTournamentDialog(context, tournament),
      ),
      DialogAction(
        title: 'Delete',
        icon: deleteIcon,
        isDestructive: true,
        onPressed: () => confirmDeleteTournament(context, tournament, onDelete),
      ),
    ];
    return child == null
        ? createPopupMenu(items)
        : LongPressPopupMenu(items: items, child: child!);
  }
}
