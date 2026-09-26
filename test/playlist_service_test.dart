import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:downloader/services/playlist_service.dart';

void main() {
  group('PlaylistService.generateM3uFile', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('playlist_service_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('gera .m3u com nome sanitizado e conteúdo com os caminhos', () async {
      final songs = [
        p.join(tempDir.path, 'musica1.mp3'),
        p.join(tempDir.path, 'musica2.mp3'),
      ];

      await PlaylistService.generateM3uFile(
        tempDir.path,
        r'Minha/Play:list*?"<>|',
        songs,
      );

      final m3uFile = File(p.join(tempDir.path, 'Minha_Play_list______.m3u'));

      expect(await m3uFile.exists(), isTrue);

      final content = await m3uFile.readAsLines();
      expect(content, songs);
    });

    test('não gera arquivo quando a lista de músicas está vazia', () async {
      await PlaylistService.generateM3uFile(tempDir.path, 'Vazia', const []);

      final generated = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m3u'))
          .toList();

      expect(generated, isEmpty);
    });
  });
}
