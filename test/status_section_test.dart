import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:downloader/widgets/status_section.dart';

void main() {
  group('StatusSection', () {
    testWidgets(
      'mostra Tooltip com faixas não encontradas quando failedTracks não está vazio',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StatusSection(
                isDownloading: false,
                progress: 0.0,
                statusMessage: 'Download concluído! 1 faixa não encontrada',
                playlistName: null,
                failedTracks: ['Artista - Música'],
              ),
            ),
          ),
        );

        // Encontrar o Tooltip específico das faixas não encontradas
        final tooltipFinder = find.byTooltip(
          'Faixas não encontradas:\n• Artista - Música',
        );
        expect(tooltipFinder, findsOneWidget);
      },
    );

    testWidgets('não mostra Tooltip de faixas quando failedTracks está vazio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusSection(
              isDownloading: false,
              progress: 0.0,
              statusMessage: 'Download concluído!',
              playlistName: null,
              failedTracks: [],
            ),
          ),
        ),
      );

      // Não deve existir Tooltip com mensagem de faixas não encontradas
      expect(find.byTooltip('Faixas não encontradas:'), findsNothing);

      // O Tooltip do botão copiar deve existir
      expect(find.byTooltip('Copiar mensagem'), findsOneWidget);
    });

    testWidgets('mostra Tooltip com múltiplas faixas não encontradas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusSection(
              isDownloading: false,
              progress: 0.0,
              statusMessage: 'Download concluído! 2 faixas não encontradas',
              playlistName: null,
              failedTracks: ['Artista 1 - Música 1', 'Artista 2 - Música 2'],
            ),
          ),
        ),
      );

      final tooltipFinder = find.byTooltip(
        'Faixas não encontradas:\n• Artista 1 - Música 1\n• Artista 2 - Música 2',
      );
      expect(tooltipFinder, findsOneWidget);
    });

    testWidgets(
      'não renderiza Container de status quando statusMessage está vazio',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StatusSection(
                isDownloading: false,
                progress: 0.0,
                statusMessage: '',
                playlistName: null,
                failedTracks: ['Artista - Música'],
              ),
            ),
          ),
        );

        // Não deve haver Tooltip de faixas não encontradas
        expect(find.byTooltip('Faixas não encontradas:'), findsNothing);

        // Não deve haver SelectableText (que está dentro do Container de status)
        expect(find.byType(SelectableText), findsNothing);
      },
    );
  });
}
