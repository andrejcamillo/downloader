import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:downloader/services/download_service.dart';

void main() {
  group('DownloadService.shouldAttemptRecovery', () {
    test(
      'retorna false em sucesso (exitCode 0 com YouTube e arquivos novos)',
      () {
        expect(
          DownloadService.shouldAttemptRecovery(
            exitCode: 0,
            isYouTube: true,
            hasNewFiles: true,
          ),
          isFalse,
        );
      },
    );

    test('retorna true quando exitCode != 0 (qualquer fonte)', () {
      expect(
        DownloadService.shouldAttemptRecovery(
          exitCode: 1,
          isYouTube: true,
          hasNewFiles: true,
        ),
        isTrue,
      );
    });

    test('retorna true quando exitCode != 0 (Spotify)', () {
      expect(
        DownloadService.shouldAttemptRecovery(
          exitCode: 1,
          isYouTube: false,
          hasNewFiles: true,
        ),
        isTrue,
      );
    });

    test('retorna false para YouTube com exitCode=0 e sem arquivos novos', () {
      // No fluxo YouTube os arquivos vão para o temp dir e são movidos depois,
      // então ausência de arquivos novos na pasta final é normal
      expect(
        DownloadService.shouldAttemptRecovery(
          exitCode: 0,
          isYouTube: true,
          hasNewFiles: false,
        ),
        isFalse,
      );
    });

    test('retorna false para Spotify com exitCode=0 e arquivos novos', () {
      expect(
        DownloadService.shouldAttemptRecovery(
          exitCode: 0,
          isYouTube: false,
          hasNewFiles: true,
        ),
        isFalse,
      );
    });

    test('retorna true para Spotify com exitCode=0 e sem arquivos novos', () {
      // Spotdl pode terminar com exitCode=0 sem baixar nada
      expect(
        DownloadService.shouldAttemptRecovery(
          exitCode: 0,
          isYouTube: false,
          hasNewFiles: false,
        ),
        isTrue,
      );
    });
  });

  group('DownloadService.extractPlaylistName', () {
    test('extrai nome de playlist padrão', () {
      expect(
        DownloadService.extractPlaylistName(
          '[download] Downloading playlist: Best Andre Songs',
        ),
        equals('Best Andre Songs'),
      );
    });

    test('extrai nome de playlist com acentos e espaços', () {
      expect(
        DownloadService.extractPlaylistName(
          '[download] Downloading playlist: Músicas Para Programar',
        ),
        equals('Músicas Para Programar'),
      );
    });

    test(
      'extrai nome de playlist com espaços à direita (trim deve removê-los)',
      () {
        expect(
          DownloadService.extractPlaylistName(
            '[download] Downloading playlist: Minha Playlist   ',
          ),
          equals('Minha Playlist'),
        );
      },
    );

    test('retorna null para linha que não é playlist', () {
      expect(
        DownloadService.extractPlaylistName(
          '[download] Downloading item 2 of 41',
        ),
        isNull,
      );
    });

    test('retorna null para linha de página web', () {
      expect(
        DownloadService.extractPlaylistName(
          '[youtube:tab] PLVtqvlJGrW8o: Downloading webpage',
        ),
        isNull,
      );
    });

    test('retorna null para linha vazia', () {
      expect(DownloadService.extractPlaylistName(''), isNull);
    });
  });

  group('DownloadService.extractNotFoundTrack', () {
    test('extrai nome da faixa de LookupError padrão', () {
      expect(
        DownloadService.extractNotFoundTrack(
          'LookupError: No results found for song: Artista - Música',
        ),
        equals('Artista - Música'),
      );
    });

    test(
      'extrai nome da faixa com prefixo de logging antes do LookupError',
      () {
        expect(
          DownloadService.extractNotFoundTrack(
            '[INFO] LookupError: No results found for song: Artista - Música',
          ),
          equals('Artista - Música'),
        );
      },
    );

    test('retorna null para linha sem o padrão LookupError', () {
      expect(DownloadService.extractNotFoundTrack('[download] 50.0%'), isNull);
    });

    test('retorna null para linha com padrão "returned no usable results"', () {
      expect(
        DownloadService.extractNotFoundTrack(
          '[youtube] abc123: returned no usable results',
        ),
        isNull,
      );
    });

    test('extrai nome da faixa com acentos e caracteres especiais', () {
      expect(
        DownloadService.extractNotFoundTrack(
          'LookupError: No results found for song: Artista Com Acentuação - Música Especial',
        ),
        equals('Artista Com Acentuação - Música Especial'),
      );
    });

    test('retorna null para linha vazia', () {
      expect(DownloadService.extractNotFoundTrack(''), isNull);
    });
  });

  group('DownloadService.decodeProcessOutput', () {
    test(
      'decodifica UTF-8 com acentos mesmo quando chunks dividem multibyte',
      () async {
        const input = 'Músicas de Natal — ção\nSegunda linha';
        final bytes = utf8.encode(input);

        // Divide no meio da sequência multibyte do 'ú' (0xC3 0xBA)
        // 'M' 'ú' = 0x4D 0xC3 0xBA ... dividindo após 0xC3
        final chunk1 = bytes.sublist(0, 2); // 'M' + primeiro byte de 'ú'
        final chunk2 = bytes.sublist(2); // resto

        final stream = Stream<List<int>>.fromIterable([chunk1, chunk2]);
        final result = await DownloadService.decodeProcessOutput(
          stream,
        ).toList();

        expect(result, ['Músicas de Natal — ção', 'Segunda linha']);
      },
    );

    test(
      'tolera bytes inválidos substituindo por U+FFFD sem lançar exceção',
      () async {
        // 0xFF é byte inválido em UTF-8
        final bytes = <int>[
          0x4D,
          0xFF,
          0x75,
          0x73,
          0x69,
          0x63,
          0x61,
          0x0A,
        ]; // M<inválido>usica\n

        final stream = Stream<List<int>>.fromIterable([bytes]);
        final result = await DownloadService.decodeProcessOutput(
          stream,
        ).toList();

        expect(result.length, 1);
        expect(result[0], contains('\uFFFD')); // caractere de substituição
        expect(result[0], endsWith('usica'));
      },
    );

    test(
      'separa múltiplas linhas com LF e CRLF sem incluir terminadores',
      () async {
        const input = 'Linha 1\nLinha 2\r\nLinha 3\n';
        final bytes = utf8.encode(input);

        // Envia em chunks arbitrários
        final chunk1 = bytes.sublist(0, 8);
        final chunk2 = bytes.sublist(8, 16);
        final chunk3 = bytes.sublist(16);

        final stream = Stream<List<int>>.fromIterable([chunk1, chunk2, chunk3]);
        final result = await DownloadService.decodeProcessOutput(
          stream,
        ).toList();

        expect(result, ['Linha 1', 'Linha 2', 'Linha 3']);
      },
    );

    test(
      'não produz linha vazia ao final quando input termina com newline',
      () async {
        const input = 'Linha 1\nLinha 2\n';
        final bytes = utf8.encode(input);

        final stream = Stream<List<int>>.fromIterable([bytes]);
        final result = await DownloadService.decodeProcessOutput(
          stream,
        ).toList();

        expect(result, ['Linha 1', 'Linha 2']);
        expect(result.length, 2);
      },
    );
  });
}
