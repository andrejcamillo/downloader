import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolve os caminhos base da aplicação de forma independente do diretório
/// de trabalho atual.
///
/// Em produção (Windows) o executável fica ao lado da pasta `bin/`, então
/// usamos o diretório do executável. Em modo de desenvolvimento
/// (`flutter run`), o executável fica no cache do Flutter e a pasta `bin/`
/// não existe ao lado dele, então caímos para `Directory.current`.
class AppPaths {
  AppPaths._();

  /// Diretório onde está o executável atual.
  static final String exeDir = p.dirname(Platform.resolvedExecutable);

  static final String baseDir = () {
    final binFromExe = p.join(exeDir, 'bin');
    final ytDlpFromExe = p.join(binFromExe, 'yt-dlp.exe');

    if (File(ytDlpFromExe).existsSync() ||
        Directory(binFromExe).existsSync()) {
      return exeDir;
    }

    return Directory.current.path;
  }();

  /// Diretório onde ficam os executáveis externos (yt-dlp, ffmpeg, spotdl).
  static String get binDir => p.join(baseDir, 'bin');

  static String get ytDlpExe => p.join(binDir, 'yt-dlp.exe');

  static String get spotdlExe => p.join(binDir, 'spotdl.exe');

  static String get ffmpegExe => p.join(binDir, 'ffmpeg.exe');

  static String get ffprobeExe => p.join(binDir, 'ffprobe.exe');

  /// Diretório temporário usado pelo yt-dlp.
  static String get tempDir => p.join(baseDir, 'temp_downloads');

  /// Pasta padrão de saída para MP3.
  static String get defaultMp3Dir => p.join(baseDir, 'downloads', 'mp3');

  /// Pasta padrão de saída para MP4.
  static String get defaultMp4Dir => p.join(baseDir, 'downloads', 'mp4');

  /// Arquivo de log da aplicação.
  static String get logFilePath => p.join(baseDir, 'log.txt');
}
