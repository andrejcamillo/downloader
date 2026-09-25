import 'dart:io';
import '../utils/logger.dart';

class PlaylistService {
  static Future<void> generateM3uFile(
      String outputDir,
      String playlistName,
      List<String> downloadedFilePaths,
      ) async {
    try {
      if (downloadedFilePaths.isEmpty) {
        Logger.warn("Nenhum arquivo fornecido para gerar a playlist M3U.");
        return;
      }

      final sanitizedName =
      playlistName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final m3uFile = File('$outputDir/$sanitizedName.m3u');
      final sink = m3uFile.openWrite();

      for (var filePath in downloadedFilePaths) {
        sink.writeln(filePath);
      }

      await sink.flush();
      await sink.close();

      Logger.info(
          "Playlist M3U gerada com sucesso: ${m3uFile.path} (total de ${downloadedFilePaths.length} músicas).");
    } catch (e) {
      Logger.error("Erro ao gerar playlist M3U: $e");
    }
  }
}
