import 'dart:io';

class ExecutableHelper {
  static final String _baseDir = Directory.current.path;
  static final String ytDlpExe =
      '$_baseDir${Platform.pathSeparator}bin${Platform.pathSeparator}yt-dlp.exe';
  static final String spotdlExe =
      '$_baseDir${Platform.pathSeparator}bin${Platform.pathSeparator}spotdl.exe';
  static final String ffmpegExe =
      '$_baseDir${Platform.pathSeparator}bin${Platform.pathSeparator}ffmpeg.exe';

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
  '--output',
  outputTemplate,
  '--windows-filenames',
  '--ignore-errors',
  '--no-part',
  link,
  ]
      : [
  '-f',
  'best[ext=mp4]',
  '--output',
  outputTemplate,
  '--windows-filenames',
  '--ignore-errors',
  '--no-part',
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
