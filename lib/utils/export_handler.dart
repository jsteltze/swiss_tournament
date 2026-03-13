import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:logger/logger.dart';
import 'package:swiss_tournament/utils/logger.dart';
import 'package:swiss_tournament/utils/permission_handler.dart';

import '../dialogs/main_dialogs.dart';
import '../generated/java.g.dart';

class ExportHandler {
  static Future<bool> exportToDownloads(
    BuildContext context,
    String filename,
    String fileContent, [
    Function? onSuccess,
  ]) async {
    await Permissions.requestStoragePermission();
    final result = SwissChessAndroid.exportToFile(
      Jni.androidActivity(PlatformDispatcher.instance.engineId!),
      JString.fromString(fileContent),
      JString.fromString(filename),
    );
    if (result != null && result.toDartString().startsWith('ERROR: ')) {
      FileLogger.log(
        'Error while exporting $filename: ${result.toDartString().substring(7)}',
        Level.error,
      );
      if (context.mounted) {
        showErrorDialog(context, result.toDartString().substring(7));
      }
      return false;
    } else {
      FileLogger.log('Exporting $filename was successful');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$filename" exported to Downloads')),
        );
      }
      onSuccess?.call();
      return true;
    }
  }
}
