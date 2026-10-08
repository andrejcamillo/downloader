import 'package:flutter_test/flutter_test.dart';
import 'package:downloader/services/download_service.dart';

void main() {
  group('DownloadService.shouldAttemptRecovery', () {
    test('retorna false em sucesso (exitCode 0 com YouTube e arquivos novos)',
        () {
      expect(
        DownloadService.shouldAttemptRecovery(
          exitCode: 0,
          isYouTube: true,
          hasNewFiles: true,
        ),
        isFalse,
      );
    });

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
}
