import 'package:flutter_test/flutter_test.dart';

import 'package:downloader/services/file_service.dart';

void main() {
  group('FileService.diffNewFiles', () {
    test('retorna apenas os itens presentes em after e ausentes em before', () {
      final before = ['/musicas/a.mp3', '/musicas/b.mp3'];
      final after = [
        '/musicas/a.mp3',
        '/musicas/b.mp3',
        '/musicas/c.mp3',
        '/musicas/d.mp3',
      ];

      expect(
        FileService.diffNewFiles(before, after),
        ['/musicas/c.mp3', '/musicas/d.mp3'],
      );
    });

    test('retorna vazio quando after é idêntico a before', () {
      final files = ['/musicas/a.mp3', '/musicas/b.mp3'];

      expect(FileService.diffNewFiles(files, files), isEmpty);
    });

    test('retorna todos quando before está vazio', () {
      final after = ['/musicas/a.mp3', '/musicas/b.mp3'];

      expect(FileService.diffNewFiles(const [], after), after);
    });
  });
}
