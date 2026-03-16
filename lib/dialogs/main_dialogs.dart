import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swiss_tournament/components/info_panel.dart';
import 'package:swiss_tournament/components/info_table_row.dart';
import 'package:swiss_tournament/components/link.dart';
import 'package:swiss_tournament/components/styled_text.dart';
import 'package:swiss_tournament/components/warning.dart';
import 'package:swiss_tournament/data/tournament.dart';
import 'package:swiss_tournament/data/tournament_storage.dart';
import 'package:swiss_tournament/generated/app_build_timestamp.g.dart';
import 'package:swiss_tournament/utils/globals.dart';
import 'package:swiss_tournament/utils/logger.dart';
import 'package:swiss_tournament/utils/snackbar_utils.dart';
import 'package:swiss_tournament/utils/timestampx.dart';

import '../components/input_title.dart';
import '../utils/export_handler.dart';

void showImportConfirmationDialog(
  BuildContext context,
  String filename,
  List<Tournament> tournaments,
  TournamentStorage storage,
  VoidCallback onImportComplete,
) {
  String importType = 'Full Tournament';

  showDialog(
    context: context,
    builder: (context) {
      List<bool> selected = List.generate(tournaments.length, (index) => true);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Confirm Import'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InfoPanel(
                  Text(
                    '$filename: contains ${tournaments.length} tournament(s) that can be imported.',
                  ),
                ),
                const SizedBox(height: 10),
                const InputTitle('Import type:'),
                DropdownButton<String>(
                  value: importType,
                  isExpanded: true,
                  items: <String>['Full Tournament', 'Players only']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      importType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const InputTitle('Select tournament(s) to import:'),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final t = tournaments[index];
                      return CheckboxListTile(
                        title: Text(t.title),
                        subtitle: Text(
                          '${t.players.length} players${importType == 'Full Tournament' ? ', ${t.numberOfRounds} rounds' : ''}',
                        ),
                        value: selected[index],
                        onChanged: (val) {
                          setDialogState(() {
                            selected[index] = val!;
                          });
                        },
                      );
                    },
                  ),
                ),
                InputTitle(
                  'Selected: ${selected.where((s) => s).length} / ${tournaments.length}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selected.where((s) => s).isEmpty
                    ? null
                    : () async {
                        int count = 0;
                        FileLogger.log('Importing $importType from $filename');
                        for (int i = 0; i < tournaments.length; i++) {
                          if (selected[i]) {
                            final t = tournaments[i];
                            t.id = null; // Save as new
                            if (importType == 'Players only') {
                              t.rounds.clear();
                            }
                            FileLogger.log(
                              'Saving imported tournament: ${t.title}',
                            );
                            await storage.updateTournament(t);
                            count++;
                          }
                        }
                        onImportComplete();
                        if (context.mounted) {
                          Navigator.pop(context);
                          showSnackbar(
                            context,
                            'Imported $count tournament(s)',
                          );
                        }
                      },
                child: Text(
                  'Import Selected (${selected.where((s) => s).length})',
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void showExportDialog(BuildContext context, List<Tournament> tournaments) {
  final TextEditingController filenameController = TextEditingController(
    text: 'tournaments',
  );

  showDialog(
    context: context,
    builder: (context) {
      List<bool> selected = List.generate(tournaments.length, (index) => true);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Export Tournaments'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InfoPanel(
                  Text(
                    'Export tournaments to Downloads folder. The saved file can serve as a backup or can be shared and imported on other devices.',
                  ),
                ),
                const SizedBox(height: 10),
                const InputTitle('Filename:'),
                TextField(
                  controller: filenameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter filename',
                    suffixText: '.json',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                const InputTitle('Select tournament(s) to export:'),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final t = tournaments[index];
                      return CheckboxListTile(
                        title: Text(t.title),
                        subtitle: Text(
                          '${t.players.length} players, ${t.numberOfRounds} rounds',
                        ),
                        value: selected[index],
                        onChanged: (val) {
                          setDialogState(() {
                            selected[index] = val!;
                          });
                        },
                      );
                    },
                  ),
                ),
                InputTitle(
                  'Selected: ${selected.where((s) => s).length} / ${tournaments.length}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selected.where((s) => s).isEmpty
                    ? null
                    : () async {
                        String filename = '${filenameController.text}.json';
                        final selectedList = tournaments
                            .where((t) => selected[tournaments.indexOf(t)])
                            .toList();
                        FileLogger.log(
                          'Exporting ${selectedList.length} tournaments to $filename',
                        );
                        final String json = jsonEncode(
                          selectedList.map((t) => t.toJson()).toList(),
                        );

                        await ExportHandler.exportToDownloads(
                          context,
                          filename,
                          json,
                          () => Navigator.pop(context),
                        );
                      },
                child: Text(
                  'Export Selected (${selected.where((s) => s).length})',
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void showAppInfoDialog(BuildContext context) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('App Info'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InfoPanel(
                    Text(
                      'Welcome to ${Globals.packageInfo.appName}!\nThis is an Opensource, Free-to-use Android-App for organizing and managing chess tournaments in Swiss mode.\nAll data is stored locally on your device. No Internet connection required.',
                    ),
                  ),
                  ExpansionTile(
                    title: const Text('About'),
                    children: [
                      StyledText(
                        'As an organizer of chess tournaments I am familiar with FIDE-approved commercial programs. However besides being costly, they run on Windows/PC only.\nMy goal was to create an easy to use and free App, since all the Apps I found so far were either commercial or did not convince me. Also I wanted the App to require as little dependencies and permissions as possible. So everything is stored locally on your device. You are the owner of your tournament data!\nThis App will probably not support each and every advanced setting for Swiss tournaments. But I hope it will be suitable for the majority of tournaments.\n\n**FIDE regulations:** This App is not guaranteed to implement the lastest FIDE regulations/rules. Neither does it support each and every possible tournament setup. Thus it cannot be considered FIDE-approved software for official chess tournaments.\n\n**How to share tournament data:** to share tournament data between devices, use the export function. This will create a json file in the Android Downloads folder. Now this file can be sent using the default communication apps (e.g. WhatsApp, Telegram, etc.). The receiver can import the file using the import function.\n\nThe same way **backups** can be created. Since data is only stored locally you should organize backups yourself.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Version'),
                    expandedAlignment: Alignment.topLeft,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Globals.packageInfo.appName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      InfoRow(
                        'Version:',
                        '${Globals.packageInfo.version}, ${DateFormat('MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(lastAppBuildTimestamp))}',
                      ),
                      InfoRow('Package:', Globals.packageInfo.packageName),
                      InfoRow('DB Path:', TournamentStorage.dbPath ?? '-'),
                      InfoRow(
                        'Installed:',
                        Globals.packageInfo.installTime?.toHumanString() ?? '-',
                      ),
                      InfoRow(
                        'Updated:',
                        Globals.packageInfo.updateTime?.toHumanString() ?? '-',
                      ),
                      InfoRow(
                        'Sources:',
                        '',
                        contentWidget: const Link(
                          'Github',
                          'https://github.com/jsteltze/swiss_tournament.git',
                        ),
                      ),
                      InfoRow(
                        'Author:',
                        '',
                        contentWidget: const Link(
                          'Johannes Steltzer',
                          'https://github.com/jsteltze',
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Libraries'),
                    children: [
                      Text(
                        'This is my first programming with Flutter/Dart. Initially I did not intend to restrict the platform to Android. But I\'m using the pairing engine "JaVaFo", which is a Java library. I was only able to get this Java program running on Android.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const InfoRow('Language:', 'Flutter 3 / Dart SDK 3'),
                      const InfoRow('Database:', 'sqflite'),
                      const InfoRow('Package Info:', 'package_info_plus'),
                      const InfoRow('Design:', 'Material v3'),
                      const InfoRow('Icons:', 'Cupertino Icons'),
                      InfoRow(
                        'Pairing:',
                        '',
                        contentWidget: const Link(
                          'JaVaFo (main.jar v2.2)',
                          'https://www.rrweb.org/javafo/JaVaFo.htm',
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('License Info'),
                    children: [
                      StyledText(
                        'I want this App to remain open-source (copyleft). Thus this program and all of its sourcecode is licensed under **GPL v3**\nFeel free to use, modify and redistribute it under the terms of this license.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      InfoRow(
                        'License text:',
                        '',
                        titleWidth: 90,
                        contentWidget: const Link(
                          'gnu.org/licenses/gpl-3.0',
                          'https://www.gnu.org/licenses/gpl-3.0.html',
                        ),
                      ),
                      InfoRow(
                        'Rook Icon:',
                        '',
                        titleWidth: 90,
                        contentWidget: const Link(
                          'Icon by Freepik',
                          'https://www.freepik.com/icon/rook_562880#fromView=search&page=1&position=36&uuid=c1e0d777-66db-4757-98d6-8a870ff59f43',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          );
        },
      );
    },
  );
}

void showLogsDialog(BuildContext context) {
  final logs = FileLogger.getLogs();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logs'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            logs,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            final filename = 'logs-${DateTime.now().toTechString()}.txt';
            ExportHandler.exportToDownloads(
              context,
              filename,
              logs,
              () => Navigator.pop(context),
            );
          },
          icon: Icon(Icons.save_alt),
          label: const Text('Export'),
        ),
        TextButton.icon(
          onPressed: () {
            FileLogger.clearLogs();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: Icon(Icons.delete_outline),
          label: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void showErrorDialog(BuildContext context, String msg) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const Text('An error occurred:'), Warning(msg)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
