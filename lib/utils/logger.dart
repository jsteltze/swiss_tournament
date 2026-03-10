import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FileLogger {
  static File? _logFile;
  static Logger? logger;
  static String filePrefix = 'app_log_';
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final currentTimestamp = DateTime.now().microsecondsSinceEpoch;
      _logFile = File('${directory.path}/$filePrefix$currentTimestamp.txt');

      logger = Logger(
        // simple printer without too many bells and whistles
        printer: SimplePrinter(colors: false),
        // permissive filter enables logs for Release mode, too
        filter: PermissiveFilter(),
        output: FileOutput(file: _logFile!),
      );

      log('Logger initialized');

      directory.list().listen((file) {
        final name = basename(file.path);
        if (name.startsWith(filePrefix)) {
          String timestamp = name.substring(filePrefix.length);
          timestamp = timestamp.substring(0, timestamp.length - 4);
          var millis = int.parse(timestamp);
          // delete log files older than 1 week
          if (currentTimestamp - millis > 1000 * 1000 * 60 * 60 * 24 * 7) {
            log('Clean up old logfile: $name');
            file.delete();
          }
        }
      });
    } catch (e) {
      print('Failed to initialize logger: $e');
    }
  }

  static void log(String message) {
    final timestamp = _dateFormat.format(DateTime.now());
    final logMessage = '[$timestamp] $message\n';

    // Print to console as well
    print(logMessage.trim());

    logger?.i(logMessage.trim());
  }

  static String getLogs() {
    try {
      if (_logFile != null && _logFile!.existsSync()) {
        return _logFile!.readAsStringSync();
      } else {
        return 'file ${_logFile!.path} does not exist';
      }
    } catch (e) {
      print('Failed to read log file: $e');
    }
    return 'No logs found.';
  }

  static void clearLogs() {
    try {
      if (_logFile != null && _logFile!.existsSync()) {
        _logFile!.writeAsStringSync('');
      }
    } catch (e) {
      print('Failed to clear log file: $e');
    }
  }
}

class PermissiveFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}
