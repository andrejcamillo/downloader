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
}
