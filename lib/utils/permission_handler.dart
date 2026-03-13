import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid11OrAbove()) {
        // For Android 11 and above, request MANAGE_EXTERNAL_STORAGE permission
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      } else {
        // For Android versions below 11, request READ/WRITE_EXTERNAL_STORAGE permissions
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }
    }
  }

  static Future<bool> _isAndroid11OrAbove() async {
    return (await Permission.manageExternalStorage.isGranted) ||
        Platform.version.contains('API 30');
  }
}
