import 'dart:io';

import 'app_paths.dart';

class Logger {
  static final _logFile = File(AppPaths.logFilePath);

  static Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final fullMessage = '[$timestamp] $message\n';
    try {
      await _logFile.writeAsString(fullMessage, mode: FileMode.append);
    } catch (_) {
      // O log nunca deve quebrar o app (ex.: pasta de instalação sem
      // permissão de escrita). Falhas de log são ignoradas silenciosamente.
    }
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
