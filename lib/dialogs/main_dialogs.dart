import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiss_tournament/components/info_panel.dart';
import 'package:swiss_tournament/components/info_table_row.dart';
import 'package:swiss_tournament/components/input_field.dart';
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
import 'dialog_utils.dart';

void showImportConfirmationDialog(
  BuildContext context,
  String filename,
  List<Tournament> tournaments,
  TournamentStorage storage,
  VoidCallback onImportComplete,
) {
  String importType = 'Full Tournament';
  List<bool> selected = List.generate(tournaments.length, (index) => true);

  openDialog(
    context,
    title: 'Confirm Import',
    titleIcon: Icon(Icons.upload),
    child: (ctx, setDialogState, toggleMainAction) => Column(
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
        Column(
          children: tournaments.map((t) {
            final index = tournaments.indexOf(t);
            return CheckboxListTile(
              title: Text(t.title),
              subtitle: Text(
                '${t.players.length} players${importType == 'Full Tournament' ? ', ${t.numberOfRounds} rounds' : ''}',
              ),
              value: selected[index],
              onChanged: (val) {
                setDialogState(() {
                  selected[index] = val!;
                  toggleMainAction(selected.contains(true));
                });
              },
            );
          }).toList(),
        ),
        InputTitle(
          'Selected: ${selected.where((s) => s).length} / ${tournaments.length}',
        ),
      ],
    ),
    mainAction: DialogAction(
      title: 'Import Selected',
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
                  FileLogger.log('Saving imported tournament: ${t.title}');
                  await storage.updateTournament(t);
                  count++;
                }
              }
              onImportComplete();
              if (context.mounted) {
                Navigator.pop(context);
                showSnackbar(context, 'Imported $count tournament(s)');
              }
            },
    ),
  );
}

void showExportDialog(BuildContext context, List<Tournament> tournaments) {
  final TextEditingController filenameController = TextEditingController(
    text: 'tournaments',
  );
  List<bool> selected = List.generate(tournaments.length, (index) => true);

  openDialog(
    context,
    title: 'Export Tournaments',
    titleIcon: Icon(Icons.save_alt),
    child: (ctx, setDialogState, toggleMainAction) => Column(
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
        InputField('Filename', filenameController, suffixText: '.json'),
        const SizedBox(height: 20),
        const InputTitle('Select tournament(s) to export:'),
        Column(
          children: tournaments.map((t) {
            final index = tournaments.indexOf(t);
            return CheckboxListTile(
              title: Text(t.title),
              subtitle: Text(
                '${t.players.length} players, ${t.numberOfRounds} rounds',
              ),
              value: selected[index],
              onChanged: (val) {
                setDialogState(() {
                  selected[index] = val!;
                  toggleMainAction(selected.contains(true));
                });
              },
            );
          }).toList(),
        ),
        InputTitle(
          'Selected: ${selected.where((s) => s).length} / ${tournaments.length}',
        ),
      ],
    ),
    mainAction: DialogAction(
      title: 'Export Selected',
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
    ),
  );
}

void showAppInfoDialog(BuildContext context) {
  if (!context.mounted) return;
  openDialog(
    context,
    title: 'App Info',
    titleIcon: Icon(Icons.info_outline),
    child: (ctx, setDialogState, toggleMainAction) => Column(
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            InfoRow(
              'Version:',
              '${Globals.packageInfo.version}, ${DateFormat('MMMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(lastAppBuildTimestamp))}',
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            const InfoRow('Language:', 'Flutter 3 / Dart SDK 3'),
            const InfoRow('Database:', 'sqflite'),
            const InfoRow(
              'Packages:',
              'package_info_plus, expandable_search_bar_plus, url_launcher',
            ),
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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
    closeButtonTitle: 'Close',
  );
}

void showLogsDialog(BuildContext context) {
  final logs = FileLogger.getLogs();
  openDialog(
    context,
    title: 'Logs',
    titleIcon: Icon(Icons.list_alt),
    child: (ctx, setDialogState, toggleMainAction) => Text(
      logs,
      style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
    ),
    closeButtonTitle: null,
    mainAction: DialogAction(
      title: 'Close',
      onPressed: () => Navigator.pop(context),
    ),
    secondaryActions: [
      DialogAction(
        title: 'Export',
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
      ),
      DialogAction(
        title: 'Clear',
        onPressed: () {
          FileLogger.clearLogs();
          showSnackbar(context, 'Logs removed');
          Navigator.pop(context);
        },
        isDestructive: true,
        icon: Icon(Icons.delete_outline),
      ),
    ],
  );
}

void showErrorDialog(BuildContext context, String msg) {
  openDialog(
    context,
    title: 'Error',
    titleIcon: Icon(Icons.error_outline),
    child: (ctx, setDialogState, toggleMainAction) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [const Text('An error occurred:'), Warning(msg)],
    ),
    closeButtonTitle: 'Close',
  );
}

void showWelcomeDialog(BuildContext context) {
  openDialog(
    context,
    title: 'Welcome!',
    titleIcon: Icon(Icons.emoji_events_outlined),
    child: (ctx, setDialogState, toggleMainAction) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Image(image: AssetImage('assets/rook_new.png'), height: 100),
        const SizedBox(height: 20),
        const Text(
          'Thank you for using the Chess Swiss Tournament App!\n\nThis app helps you manage chess tournaments using the Swiss system. All data is stored locally on your device.\n\nPlease note that this is not FIDE-approved software.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
    mainAction: DialogAction(
      title: 'Get Started',
      onPressed: () => Navigator.pop(context),
    ),
    closeButtonTitle: null,
  );
}

Future<void> checkFirstTime(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final bool? isFirstTime = prefs.getBool('first_time');

  if (isFirstTime == null || isFirstTime) {
    if (context.mounted) {
      showWelcomeDialog(context);
    }
    await prefs.setBool('first_time', false);
  }
}
