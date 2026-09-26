import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:downloader/utils/app_paths.dart';

void main() {
  group('AppPaths.baseDir', () {
    test('faz fallback para Directory.current quando <exeDir>/bin não existe',
        () {
      final binFromExe = p.join(AppPaths.exeDir, 'bin');

      if (Directory(binFromExe).existsSync() ||
          File(p.join(binFromExe, 'yt-dlp.exe')).existsSync()) {
        // Ambiente empacotado: baseDir deve ser o diretório do executável.
        expect(AppPaths.baseDir, AppPaths.exeDir);
      } else {
        // Modo dev (flutter run/test): baseDir deve ser o diretório atual.
        expect(AppPaths.baseDir, Directory.current.path);
      }
    });
  });

  group('AppPaths getters', () {
    test('montam caminhos a partir de baseDir com o separador da plataforma',
        () {
      expect(AppPaths.binDir, p.join(AppPaths.baseDir, 'bin'));
      expect(AppPaths.ytDlpExe, p.join(AppPaths.baseDir, 'bin', 'yt-dlp.exe'));
      expect(AppPaths.spotdlExe, p.join(AppPaths.baseDir, 'bin', 'spotdl.exe'));
      expect(AppPaths.ffmpegExe, p.join(AppPaths.baseDir, 'bin', 'ffmpeg.exe'));
      expect(AppPaths.tempDir, p.join(AppPaths.baseDir, 'temp_downloads'));
      expect(
        AppPaths.defaultMp3Dir,
        p.join(AppPaths.baseDir, 'downloads', 'mp3'),
      );
      expect(
        AppPaths.defaultMp4Dir,
        p.join(AppPaths.baseDir, 'downloads', 'mp4'),
      );
      expect(AppPaths.logFilePath, p.join(AppPaths.baseDir, 'log.txt'));
    });

    test('não usa separadores hardcoded do Windows ou POSIX', () {
      // Cada getter deve ser composto com o separador da plataforma atual.
      expect(AppPaths.binDir.contains(Platform.pathSeparator), isTrue);
      expect(AppPaths.ytDlpExe.contains(Platform.pathSeparator), isTrue);
      expect(AppPaths.tempDir.contains(Platform.pathSeparator), isTrue);
      expect(AppPaths.defaultMp3Dir.contains(Platform.pathSeparator), isTrue);
    });
  });
}
