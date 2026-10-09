import 'dart:io';

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

      expect(FileService.diffNewFiles(before, after), [
        '/musicas/c.mp3',
        '/musicas/d.mp3',
      ]);
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

  group('FileService.moveFilesFromTempToFinal', () {
    late Directory tempDir;
    late Directory finalDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_service_test_');
      finalDir = await Directory.systemTemp.createTemp('file_service_final_');
    });

    tearDown(() async {
      // Limpa os diretórios temporários
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      if (await finalDir.exists()) {
        await finalDir.delete(recursive: true);
      }
    });

    test('move arquivos no mesmo volume (caminho feliz)', () async {
      // Cria 2 arquivos no temp
      final file1 = File('${tempDir.path}/musica1.mp3');
      final file2 = File('${tempDir.path}/musica2.mp3');
      await file1.writeAsString('content1');
      await file2.writeAsString('content2');

      // Executa o move
      final movedFiles = await FileService.moveFilesFromTempToFinal(
        tempDir.path,
        finalDir.path,
      );

      // Verifica resultados
      expect(movedFiles, hasLength(2));
      expect(
        movedFiles,
        contains('${finalDir.path}${Platform.pathSeparator}musica1.mp3'),
      );
      expect(
        movedFiles,
        contains('${finalDir.path}${Platform.pathSeparator}musica2.mp3'),
      );

      // Verifica que os arquivos existem no destino
      expect(
        await File(
          '${finalDir.path}${Platform.pathSeparator}musica1.mp3',
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          '${finalDir.path}${Platform.pathSeparator}musica2.mp3',
        ).exists(),
        isTrue,
      );

      // Verifica que os arquivos não existem mais no temp
      expect(await file1.exists(), isFalse);
      expect(await file2.exists(), isFalse);
    });

    test('retorna vazio quando não há arquivos no temp', () async {
      // Temp está vazio (criado no setUp)
      final movedFiles = await FileService.moveFilesFromTempToFinal(
        tempDir.path,
        finalDir.path,
      );

      expect(movedFiles, isEmpty);
    });

    test(
      'lança exceção quando há arquivos mas nenhum pôde ser movido',
      () async {
        // Cria um arquivo no temp
        final file1 = File('${tempDir.path}/musica1.mp3');
        await file1.writeAsString('content1');

        // Cria um DIRETÓRIO com o mesmo nome do arquivo no destino
        // Isso faz com que rename e copy falhem
        final conflictingDir = Directory(
          '${finalDir.path}${Platform.pathSeparator}musica1.mp3',
        );
        await conflictingDir.create();

        // Espera que lance exceção
        expect(
          () =>
              FileService.moveFilesFromTempToFinal(tempDir.path, finalDir.path),
          throwsException,
        );
      },
    );
  });

  group('FileService.clearDirectory', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_service_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('apaga conteúdo de diretório com arquivos e subdiretório', () async {
      // Cria arquivos e subdiretório
      final file1 = File('${tempDir.path}/arquivo1.txt');
      final subdir = Directory('${tempDir.path}/subdir');
      final file2 = File('${subdir.path}/arquivo2.txt');

      await file1.writeAsString('content1');
      await subdir.create();
      await file2.writeAsString('content2');

      // Verifica que os arquivos existem
      expect(await file1.exists(), isTrue);
      expect(await file2.exists(), isTrue);

      // Chama clearDirectory
      await FileService.clearDirectory(tempDir.path);

      // Verifica que o diretório raiz ainda existe e está vazio
      expect(await tempDir.exists(), isTrue);
      expect(tempDir.listSync().length, equals(0));
    });

    test('não lança exceção para diretório inexistente', () async {
      const nonExistentDir = '/non/existent/directory/path';

      // Não deve lançar exceção
      await FileService.clearDirectory(nonExistentDir);
    });

    test('no-op para diretório vazio', () async {
      // Diretório já está vazio (criado no setUp)
      expect(tempDir.listSync().length, equals(0));

      // Não deve lançar exceção nem mudar nada
      await FileService.clearDirectory(tempDir.path);

      expect(tempDir.listSync().length, equals(0));
    });

    test(
      'apaga diretório com muitos subdirs e arquivos aninhados sem exceção',
      () async {
        // Cria estrutura realista: 3 subdirs × 30 arquivos + nested subdir
        for (var i = 0; i < 3; i++) {
          final subdir = Directory('${tempDir.path}/sub$i');
          await subdir.create();

          for (var j = 0; j < 30; j++) {
            await File('${subdir.path}/arquivo$j.txt').writeAsString('content');
          }

          // Primeiro subdir tem subdiretório aninhado com mais 10 arquivos
          if (i == 0) {
            final nestedSubdir = Directory('${subdir.path}/nested');
            await nestedSubdir.create();
            for (var j = 0; j < 10; j++) {
              await File(
                '${nestedSubdir.path}/nestedArquivo$j.txt',
              ).writeAsString('nested_content');
            }
          }
        }

        // Verifica que os arquivos foram criados
        var fileCount = 0;
        await for (final entity in tempDir.list(recursive: true)) {
          if (entity is File) fileCount++;
        }
        expect(fileCount, equals(100)); // 3*30 + 10

        // Chama clearDirectory - não deve lançar exceção nem deixar arquivos
        await FileService.clearDirectory(tempDir.path);

        // Raiz deve existir e estar vazio
        expect(await tempDir.exists(), isTrue);
        expect(tempDir.listSync().length, equals(0));
      },
    );
  });
}
