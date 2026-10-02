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

    // Windows usa cp1252 no console; força UTF-8 para o Python empacotado
    // (yt-dlp/spotdl) não quebrar ao imprimir caracteres especiais.
    environmentVars['PYTHONIOENCODING'] = 'utf-8';
    environmentVars['PYTHONUTF8'] = '1';

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

    final beforeFiles = FileService.listNewFiles(finalOutputDir);

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

    // Usada tanto em produção (detecção de arquivos novos do spotdl) quanto
    // nos testes; a anotação @visibleForTesting documenta a testabilidade.
    // ignore: invalid_use_of_visible_for_testing_member
    final newFiles = FileService.diffNewFiles(
      beforeFiles,
      FileService.listNewFiles(finalOutputDir),
    );

    // O spotdl pode terminar com exitCode=0 mesmo falhando em todas as
    // faixas (ex.: 403 do yt-dlp vendorizado). Nesse caso não há arquivos
    // novos e tratamos como falha.
    final spotdlNoFiles = !isYouTube && exitCode == 0 && newFiles.isEmpty;
    final shouldUpdate = exitCode != 0 || spotdlNoFiles;

    if (shouldUpdate && !retrying) {
      if (exitCode != 0) {
        Logger.error("Falha no download: exitCode=$exitCode");
      } else {
        Logger.error(
            "spotdl terminou com exitCode=0 sem baixar nenhuma música nova.");
      }

      final provider = isYouTube ? "yt-dlp" : "spotDL";
      Logger.info("Tentando atualizar $provider automaticamente...");
      final updated = isYouTube
          ? await UpdaterService.updateYtDlp()
          : await UpdaterService.updateSpotdl();
      if (updated) {
        Logger.info("$provider atualizado. Tentando o download novamente...");
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
        Logger.error("Falha ao atualizar $provider automaticamente.");
      }
    }

    if (exitCode != 0) {
      throw Exception("Erro no processo de download (exitCode=$exitCode)");
    }

    if (spotdlNoFiles) {
      throw Exception(
          "O spotdl terminou sem baixar nenhuma música. Tente atualizar o spotDL nas Configurações ou verifique o log.txt.");
    }

    // Caminho feliz: exitCode==0 com arquivos novos (ou fluxo YouTube).
    // garante que a pasta final exista
    await FileService().ensureOutputDir(finalOutputDir);

    List<String> downloadedFiles = [];
    if (isYouTube) {
      downloadedFiles = await FileService.moveFilesFromTempToFinal(
        ytDlpTempDir,
        finalOutputDir,
      );
    } else {
      downloadedFiles = newFiles;
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
  }
}
