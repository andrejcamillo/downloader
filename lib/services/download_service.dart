import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/executable_helper.dart';
import '../utils/logger.dart';
import 'file_service.dart';
import 'playlist_service.dart';
import 'updater_service.dart';

/// Lançada quando um download em andamento é cancelado pelo usuário.
///
/// Diferencia explicitamente o cancelamento de uma falha genérica para que a
/// apresentação possa reagir de forma adequada.
class DownloadCancelledException implements Exception {
  const DownloadCancelledException([this.message = 'Download cancelado.']);

  final String message;

  @override
  String toString() => message;
}

class DownloadService {
  final String ytDlpTempDir;

  DownloadService({
    required this.ytDlpTempDir,
  });

  /// Processo externo em execução no momento, quando houver.
  Process? _activeProcess;

  /// `true` enquanto um download estiver em andamento.
  bool _isDownloading = false;

  /// Sinalizado por [cancelActive] e verificado nos pontos de retomada do
  /// fluxo (após operações longas), permitindo interromper o retry mesmo
  /// quando o processo externo já terminou.
  bool _cancelRequested = false;

  /// Cancela o download em andamento.
  ///
  /// Mata o processo externo ativo, se houver. Quando nenhum download está em
  /// andamento a chamada é um no-op.
  Future<void> cancelActive() async {
    if (!_isDownloading) return;

    _cancelRequested = true;

    final process = _activeProcess;
    if (process == null) return;

    try {
      process.kill();
      Logger.info("Processo de download encerrado pelo usuário.");
    } catch (e) {
      Logger.warn("Falha ao encerrar o processo de download: $e");
    }
  }

  /// Decide se a tentativa atual falhou e justifica a recuperação automática
  /// (atualizar a ferramenta e tentar novamente).
  ///
  /// O spotdl pode terminar com `exitCode == 0` mesmo sem baixar nada, então
  /// esse caso também é tratado como falha.
  @visibleForTesting
  static bool shouldAttemptRecovery({
    required int exitCode,
    required bool isYouTube,
    required bool hasNewFiles,
  }) {
    final spotdlNoFiles = !isYouTube && exitCode == 0 && !hasNewFiles;
    return exitCode != 0 || spotdlNoFiles;
  }

  Future<List<String>> performDownload({
    required bool isYouTube,
    required bool isMp3,
    required String link,
    required String finalOutputDir,
    required bool generateM3u,
    String? playlistName,
  }) async {
    // Reseta o estado de cancelamento de uma execução anterior e marca o
    // início do download (inclusive durante a preparação dos executáveis).
    _cancelRequested = false;
    _isDownloading = true;

    try {
      if (!await UpdaterService.ensureExecutables(youtube: isYouTube)) {
        throw Exception(isYouTube
            ? 'Falha ao preparar yt-dlp/ffmpeg (verifique a conexão).'
            : 'Falha ao preparar spotdl/ffmpeg (instale Python + pip install spotdl ou verifique a conexão).');
      }

      if (_cancelRequested) {
        throw const DownloadCancelledException();
      }

      final environmentVars = Map<String, String>.from(Platform.environment);

      // Windows usa cp1252 no console; força UTF-8 para o Python empacotado
      // (yt-dlp/spotdl) não quebrar ao imprimir caracteres especiais.
      environmentVars['PYTHONIOENCODING'] = 'utf-8';
      environmentVars['PYTHONUTF8'] = '1';

      // No máximo uma tentativa de retry, e apenas quando a atualização
      // automática for bem-sucedida.
      const maxRetries = 1;

      var exitCode = 0;

      for (var attempt = 0; attempt <= maxRetries; attempt++) {
        if (_cancelRequested) {
          await _cleanupAfterCancel(isYouTube);
          throw const DownloadCancelledException();
        }

        String command;
        List<String> args;
        (String, List<String>)? spotdlRunner;

        if (isYouTube) {
          (command, args) = ExecutableHelper.buildYtDlpCommand(
            isMp3: isMp3,
            link: link,
            tempDir: ytDlpTempDir,
          );
        } else {
          final runner = await ExecutableHelper.resolveSpotdlRunner();
          spotdlRunner = runner;
          (command, args) = ExecutableHelper.buildSpotdlCommand(
            runner: runner,
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
        _activeProcess = process;

        process.stdout.transform(const SystemEncoding().decoder).listen((line) {
          Logger.info(line.trim());
        });

        process.stderr.transform(const SystemEncoding().decoder).listen((line) {
          Logger.error(line.trim());
        });

        exitCode = await process.exitCode;
        _activeProcess = null;

        // Cancelamento detectado: interrompe antes de avaliar o resultado.
        if (_cancelRequested) {
          await _cleanupAfterCancel(isYouTube);
          throw const DownloadCancelledException();
        }

        // Usada tanto em produção (detecção de arquivos novos do spotdl)
        // quanto nos testes; a anotação @visibleForTesting documenta a
        // testabilidade.
        // ignore: invalid_use_of_visible_for_testing_member
        final newFiles = FileService.diffNewFiles(
          beforeFiles,
          FileService.listNewFiles(finalOutputDir),
        );

        // O spotdl pode terminar com exitCode=0 mesmo falhando em todas as
        // faixas (ex.: 403 do yt-dlp vendorizado). Nesse caso não há arquivos
        // novos e tratamos como falha.
        final shouldUpdate = shouldAttemptRecovery(
          exitCode: exitCode,
          isYouTube: isYouTube,
          hasNewFiles: newFiles.isNotEmpty,
        );

        if (!shouldUpdate) {
          // Caminho feliz: exitCode==0 com arquivos novos (ou fluxo YouTube).
          // garante que a pasta final exista
          await FileService().ensureOutputDir(finalOutputDir);

          List<String> downloadedFiles;
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

        // Falhou: só tenta recuperação se ainda houver retry disponível.
        if (attempt >= maxRetries) {
          break;
        }

        if (exitCode != 0) {
          Logger.error("Falha no download: exitCode=$exitCode");
        } else {
          Logger.error(
              "spotdl terminou com exitCode=0 sem baixar nenhuma música nova.");
        }

        bool updated;
        if (isYouTube) {
          Logger.info("Tentando atualizar yt-dlp automaticamente...");
          updated = await UpdaterService.updateYtDlp();
        } else if (spotdlRunner != null &&
            spotdlRunner.$1 != ExecutableHelper.spotdlExe) {
          Logger.info(
              "Tentando atualizar spotdl/yt-dlp via pip automaticamente...");
          updated = await UpdaterService.updateSpotdlPip();
        } else {
          Logger.info("Tentando atualizar spotDL automaticamente...");
          updated = await UpdaterService.updateSpotdl();
        }

        // A atualização é longa: se o usuário cancelou nesse intervalo,
        // interrompe antes de iniciar uma nova tentativa.
        if (_cancelRequested) {
          await _cleanupAfterCancel(isYouTube);
          throw const DownloadCancelledException();
        }

        if (!updated) {
          Logger.error("Falha ao atualizar automaticamente.");
          break;
        }

        Logger.info("Atualizado. Tentando o download novamente...");
      }

      // Chega aqui somente em caso de falha (retry esgotado ou atualização
      // malsucedida).
      if (exitCode != 0) {
        throw Exception("Erro no processo de download (exitCode=$exitCode)");
      }

      throw Exception(
          "O spotdl terminou sem baixar nenhuma música. Tente atualizar o spotDL nas Configurações ou verifique o log.txt.");
    } finally {
      _activeProcess = null;
      _isDownloading = false;
      _cancelRequested = false;
    }
  }

  /// Remove arquivos temporários deixados pelo yt-dlp quando o download é
  /// cancelado. No fluxo Spotify os arquivos vão direto à pasta final, então
  /// nada é removido.
  Future<void> _cleanupAfterCancel(bool isYouTube) async {
    if (!isYouTube) return;
    await FileService.clearDirectory(ytDlpTempDir);
  }
}
