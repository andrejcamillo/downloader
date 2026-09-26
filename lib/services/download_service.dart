import 'dart:io';
import '../utils/logger.dart';
import '../utils/executable_helper.dart';
import 'file_service.dart';
import 'playlist_service.dart';
import 'updater_service.dart';

class DownloadService {
  final String ytDlpTempDir;

  DownloadService({
    required this.ytDlpTempDir,
  });

  Future<List<String>> performDownload({
    required bool isYouTube,
    required bool isMp3,
    required String link,
    required String finalOutputDir,
    required bool generateM3u,
    String? playlistName,
    bool retrying = false, // <- controle interno para evitar loop infinito
  }) async {
    if (isYouTube) {
      if (!await UpdaterService.ensureExecutables(youtube: true)) {
        throw Exception(
            'Falha ao preparar yt-dlp/ffmpeg (verifique a conexão).');
      }
    }

    final environmentVars = Map<String, String>.from(Platform.environment);

    String command;
    List<String> args;

    if (isYouTube) {
      (command, args) = ExecutableHelper.buildYtDlpCommand(
        isMp3: isMp3,
        link: link,
        tempDir: ytDlpTempDir,
      );
    } else {
      (command, args) = ExecutableHelper.buildSpotdlCommand(
        link: link,
        finalOutputDir: finalOutputDir,
      );
    }

    Logger.info("Iniciando processo: $command ${args.join(' ')}");

    final process = await Process.start(
      command,
      args,
      runInShell: false,
      environment: environmentVars,
    );

    process.stdout.transform(const SystemEncoding().decoder).listen((line) {
      Logger.info(line.trim());
    });

    process.stderr.transform(const SystemEncoding().decoder).listen((line) {
      Logger.error(line.trim());
    });

    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      // garante que a pasta final exista
      await FileService().ensureOutputDir(finalOutputDir);

      List<String> downloadedFiles = [];
      if (isYouTube) {
        downloadedFiles = await FileService.moveFilesFromTempToFinal(
          ytDlpTempDir,
          finalOutputDir,
        );
      } else {
        downloadedFiles = FileService.listNewFiles(finalOutputDir);
      }

      if (generateM3u && downloadedFiles.isNotEmpty) {
        await PlaylistService.generateM3uFile(
          finalOutputDir,
          playlistName ?? "Minha Playlist",
          downloadedFiles,
        );
      }

      Logger.info("Download concluído com sucesso!");
      return downloadedFiles;
    } else {
      Logger.error("Falha no download: exitCode=$exitCode");

      // Se for YouTube e ainda não tentamos atualizar, vamos tentar
      if (isYouTube && !retrying) {
        Logger.info("Tentando atualizar yt-dlp automaticamente...");
        final updated = await UpdaterService.updateYtDlp();
        if (updated) {
          Logger.info("yt-dlp atualizado. Tentando o download novamente...");
          return await performDownload(
            isYouTube: isYouTube,
            isMp3: isMp3,
            link: link,
            finalOutputDir: finalOutputDir,
            generateM3u: generateM3u,
            playlistName: playlistName,
            retrying: true, // <- evita loop infinito
          );
        } else {
          Logger.error("Falha ao atualizar yt-dlp automaticamente.");
        }
      }

      throw Exception("Erro no processo de download (exitCode=$exitCode)");
    }
  }
}
