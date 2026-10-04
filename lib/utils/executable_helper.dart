import 'dart:io';

import 'app_paths.dart';
import 'logger.dart';

class ExecutableHelper {
  static final String ytDlpExe = AppPaths.ytDlpExe;
  static final String spotdlExe = AppPaths.spotdlExe;
  static final String ffmpegExe = AppPaths.ffmpegExe;

  /// Resolve como executar o spotdl: preferência para instalação via pip
  /// (`python -m spotdl`), com fallback para o binário em bin/.
  /// Cache: a sondagem ocorre uma única vez por sessão.
  static Future<(String, List<String>)>? _spotdlRunner;

  static Future<(String, List<String>)> resolveSpotdlRunner() {
    return _spotdlRunner ??= _resolveSpotdlRunner();
  }

  /// Reseta o cache (usado após instalação/atualização do spotdl).
  static void resetSpotdlRunnerCache() => _spotdlRunner = null;

  static Future<(String, List<String>)> _resolveSpotdlRunner() async {
    try {
      final result =
          await Process.run('python', ['-m', 'spotdl', '--version']);
      if (result.exitCode == 0) {
        Logger.info('spotdl via pip detectado: ${result.stdout}'.trim());
        return ('python', ['-m', 'spotdl']);
      }
    } catch (_) {
      // python ausente ou spotdl não instalado via pip
    }
    return (AppPaths.spotdlExe, <String>[]);
  }

  /// yt-dlp → retorna comando + args corretos
  static (String, List<String>) buildYtDlpCommand({
  required bool isMp3,
  required String link,
  required String tempDir,
  }) {
  final outputTemplate =
  '$tempDir${Platform.pathSeparator}%(title)s.%(ext)s';

  final args = isMp3
  ? [
  '--extract-audio',
  '--audio-format',
  'mp3',
  '--audio-quality',
  '0',
  '--add-metadata',
  '--embed-thumbnail',
  '--ffmpeg-location',
  AppPaths.binDir,
  '--output',
  outputTemplate,
  '--windows-filenames',
  '--ignore-errors',
  '--no-part',
  '--retries',
  '10',
  '--fragment-retries',
  '10',
  '--retry-sleep',
  '5',
  link,
  ]
      : [
  '-f',
  'best[ext=mp4]',
  '--ffmpeg-location',
  AppPaths.binDir,
  '--output',
  outputTemplate,
  '--windows-filenames',
  '--ignore-errors',
  '--no-part',
  '--retries',
  '10',
  '--fragment-retries',
  '10',
  '--retry-sleep',
  '5',
  link,
  ];

  return (ytDlpExe, args);
  }

  /// spotdl → retorna comando + args corretos
  static (String, List<String>) buildSpotdlCommand({
  required (String, List<String>) runner,
  required String link,
  required String finalOutputDir,
  }) {
  final args = [
  ...runner.$2,
  'download',
  link,
  '--ffmpeg',
  ffmpegExe,
  '--output',
  finalOutputDir,
  '--log-level',
  'INFO',
  '--overwrite',
  'force',
  '--no-cache',
  '--simple-tui',
  '--bitrate',
  '192k',
  ];

  return (runner.$1, args);
  }
}
