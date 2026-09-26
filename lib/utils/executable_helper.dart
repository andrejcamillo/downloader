import 'dart:io';

import 'app_paths.dart';

class ExecutableHelper {
  static final String ytDlpExe = AppPaths.ytDlpExe;
  static final String spotdlExe = AppPaths.spotdlExe;
  static final String ffmpegExe = AppPaths.ffmpegExe;

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
  required String link,
  required String finalOutputDir,
  }) {
  final args = [
  'download',
  link,
  '--ffmpeg',
  ffmpegExe,
  '--output',
  finalOutputDir,
  '--log-level',
  'DEBUG',
  '--overwrite',
  'force',
  '--no-cache',
  '--bitrate',
  '192k',
  ];

  return (spotdlExe, args);
  }
}
