import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:downloader/utils/app_paths.dart';
import 'package:downloader/utils/executable_helper.dart';

void main() {
  group('ExecutableHelper.buildYtDlpCommand', () {
    test('inclui --ffmpeg-location apontando para o binDir no MP3', () {
      final (command, args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: true,
        link: 'https://music.youtube.com/playlist?list=ABC',
        tempDir: '/tmp/temp_downloads',
      );

      expect(command, AppPaths.ytDlpExe);

      final ffmpegIndex = args.indexOf('--ffmpeg-location');
      expect(ffmpegIndex, isNot(-1));
      expect(args[ffmpegIndex + 1], AppPaths.binDir);
    });

    test('inclui --ffmpeg-location apontando para o binDir no MP4', () {
      final (_, args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: false,
        link: 'https://music.youtube.com/playlist?list=ABC',
        tempDir: '/tmp/temp_downloads',
      );

      final ffmpegIndex = args.indexOf('--ffmpeg-location');
      expect(ffmpegIndex, isNot(-1));
      expect(args[ffmpegIndex + 1], AppPaths.binDir);
    });

    test('inclui flags de retry no MP3', () {
      final (_, args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: true,
        link: 'https://music.youtube.com/playlist?list=ABC',
        tempDir: '/tmp/temp_downloads',
      );

      expect(_valueOf(args, '--retries'), '10');
      expect(_valueOf(args, '--fragment-retries'), '10');
      expect(_valueOf(args, '--retry-sleep'), '5');
    });

    test('inclui flags de retry no MP4', () {
      final (_, args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: false,
        link: 'https://music.youtube.com/playlist?list=ABC',
        tempDir: '/tmp/temp_downloads',
      );

      expect(_valueOf(args, '--retries'), '10');
      expect(_valueOf(args, '--fragment-retries'), '10');
      expect(_valueOf(args, '--retry-sleep'), '5');
    });

    test('mantém o link como último argumento', () {
      const link = 'https://music.youtube.com/playlist?list=ABC';

      final (_, mp3Args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: true,
        link: link,
        tempDir: '/tmp/temp_downloads',
      );
      final (_, mp4Args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: false,
        link: link,
        tempDir: '/tmp/temp_downloads',
      );

      expect(mp3Args.last, link);
      expect(mp4Args.last, link);
    });

    test('usa o tempDir informado no template de saída', () {
      const tempDir = '/tmp/meu_temp_downloads';

      final (_, mp3Args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: true,
        link: 'https://music.youtube.com/watch?v=ABC',
        tempDir: tempDir,
      );
      final (_, mp4Args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: false,
        link: 'https://music.youtube.com/watch?v=ABC',
        tempDir: tempDir,
      );

      final expectedTemplate =
          p.join(tempDir, '%(title)s.%(ext)s');

      expect(mp3Args[mp3Args.indexOf('--output') + 1], expectedTemplate);
      expect(mp4Args[mp4Args.indexOf('--output') + 1], expectedTemplate);
    });
  });
}

String? _valueOf(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1) return null;
  return args[index + 1];
}
