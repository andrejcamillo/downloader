import 'dart:io';

class Logger {
  static final _logFile =
  File('${Directory.current.path}${Platform.pathSeparator}log.txt');

  static Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final fullMessage = '[$timestamp] $message\n';
    await _logFile.writeAsString(fullMessage, mode: FileMode.append);
  }

  static Future<void> info(String message) async {
    await log("[INFO] $message");
  }

  static Future<void> warn(String message) async {
    await log("[WARN] $message");
  }

  static Future<void> error(String message) async {
    await log("[ERRO] $message");
  }
}
