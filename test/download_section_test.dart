import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:downloader/widgets/download_section.dart';

void main() {
  group('DownloadSection', () {
    testWidgets(
        'mostra botão Cancelar quando isDownloading é true e onCancel é fornecido',
        (WidgetTester tester) async {
      var callbackCalled = false;

      void onCancelCallback() {
        callbackCalled = true;
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadSection(
              onDownload:
                  (link, fromYouTube, mp3Format, outputDir, generateM3u) {},
              isDownloading: true,
              onCancel: onCancelCallback,
            ),
          ),
        ),
      );

      // Encontrar o botão Cancelar
      final cancelButton = find.text('Cancelar');
      expect(cancelButton, findsOneWidget);

      // Tocar no botão
      await tester.tap(cancelButton);
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('botão Cancelar não aparece quando isDownloading é false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadSection(
              onDownload:
                  (link, fromYouTube, mp3Format, outputDir, generateM3u) {},
              isDownloading: false,
            ),
          ),
        ),
      );

      // Botão Cancelar não deve existir
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('callback onCancel é chamado ao tocar no botão Cancelar',
        (WidgetTester tester) async {
      var callbackCalled = false;

      void onCancelCallback() {
        callbackCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadSection(
              onDownload:
                  (link, fromYouTube, mp3Format, outputDir, generateM3u) {},
              isDownloading: true,
              onCancel: onCancelCallback,
            ),
          ),
        ),
      );

      // Encontrar o botão Cancelar
      expect(find.text('Cancelar'), findsOneWidget);

      // Tocar no botão
      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets(
        'botão Cancelar não aparece quando onCancel é null mesmo com isDownloading true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadSection(
              onDownload:
                  (link, fromYouTube, mp3Format, outputDir, generateM3u) {},
              isDownloading: true,
              onCancel: null,
            ),
          ),
        ),
      );

      // Botão Cancelar não deve existir quando onCancel é null
      expect(find.text('Cancelar'), findsNothing);
    });
  });
}
