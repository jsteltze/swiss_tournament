import 'package:js_flutter/components/longpress_popup_menu.dart';
import 'package:js_flutter/components/popup_menu.dart';
import 'package:js_flutter/icons.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:material_ui/material_ui.dart';

import '../data/tournament.dart';
import '../data/tournament_storage.dart';
import 'tournament_dialogs.dart';

class TournamentPopupMenu extends StatelessWidget {
  final Tournament tournament;
  final TournamentStorage? storage;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;
  final Function(Tournament)? onEdit;
  final Widget? child;

  const TournamentPopupMenu({
    super.key,
    this.child,
    required this.tournament,
    this.storage,
    this.onDelete,
    this.onUpdate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      if (onEdit != null)
        DialogAction(
          title: 'Edit',
          icon: editIcon,
          onPressed: (_) =>
              showEditTournamentDialog(context, tournament, onEdit!),
        ),
      DialogAction(
        title: 'Settings',
        icon: settingsIcon,
        onPressed: (_) => showAdvancedSettingsDialog(context, tournament),
      ),
      if (storage != null && onUpdate != null)
        DialogAction(
          title: 'Duplicate',
          icon: copyIcon,
          onPressed: (_) => showDuplicateTournamentDialog(
            context,
            tournament,
            storage!,
            onUpdate!,
          ),
        ),
      DialogAction(
        title: 'Export',
        icon: exportIcon,
        onPressed: (_) => showExportTournamentDialog(context, tournament),
      ),
      if (onDelete != null)
        DialogAction(
          title: 'Delete',
          icon: deleteIcon,
          isDestructive: true,
          onPressed: (_) =>
              confirmDeleteTournament(context, tournament, onDelete!),
        ),
    ];
    return child == null
        ? createPopupMenu(items)
        : LongPressPopupMenu(items: items, child: child!);
  }
}
