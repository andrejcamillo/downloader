import 'package:flutter_test/flutter_test.dart';

import 'package:downloader/services/updater_service.dart';

void main() {
  group('UpdaterService.shouldUpdateYtDlp', () {
    final now = DateTime(2026, 8, 19, 12, 0, 0);

    test('retorna false dentro do prazo padrão de 7 dias', () {
      final lastModified = now.subtract(const Duration(days: 3));

      expect(
        UpdaterService.shouldUpdateYtDlp(lastModified, now),
        isFalse,
      );
    });

    test('retorna true fora do prazo padrão de 7 dias', () {
      final lastModified = now.subtract(const Duration(days: 8));

      expect(
        UpdaterService.shouldUpdateYtDlp(lastModified, now),
        isTrue,
      );
    });

    test('retorna false exatamente com 7 dias', () {
      final lastModified = now.subtract(const Duration(days: 7));

      expect(
        UpdaterService.shouldUpdateYtDlp(lastModified, now),
        isFalse,
      );
    });

    test('respeita maxAge customizado', () {
      final lastModified = now.subtract(const Duration(days: 2));

      expect(
        UpdaterService.shouldUpdateYtDlp(
          lastModified,
          now,
          maxAge: const Duration(days: 1),
        ),
        isTrue,
      );
      expect(
        UpdaterService.shouldUpdateYtDlp(
          lastModified,
          now,
          maxAge: const Duration(days: 3),
        ),
        isFalse,
      );
    });
  });

  group('UpdaterService com cancelamento', () {
    test(
        'ensureExecutables(youtube: true, isCancelled: () => true) retorna false sem rede',
        () async {
      final result = await UpdaterService.ensureExecutables(
        youtube: true,
        isCancelled: () => true,
      );

      // Não deve fazer download se cancelado imediatamente
      expect(result, isFalse);
    });

    test(
        'ensureExecutables(youtube: false, isCancelled: () => true) retorna false',
        () async {
      final result = await UpdaterService.ensureExecutables(
        youtube: false,
        isCancelled: () => true,
      );

      expect(result, isFalse);
    });

    test('updateYtDlp(isCancelled: () => true) retorna false sem rede',
        () async {
      final result = await UpdaterService.updateYtDlp(isCancelled: () => true);

      expect(result, isFalse);
    });
  });
}
