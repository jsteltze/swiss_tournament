import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:js_flutter/android/permission_handler.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:js_flutter/utils/snackbar_utils.dart';

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
      FileLogger.error(
        'Error while exporting $filename: ${result.toDartString().substring(7)}',
      );
      if (context.mounted) {
        showErrorDialog(context, result.toDartString().substring(7));
      }
      return false;
    } else {
      FileLogger.log('Exporting $filename was successful');
      if (context.mounted) {
        showSnackbar(context, '"$filename" exported to Downloads');
      }
      onSuccess?.call();
      return true;
    }
  }
}
