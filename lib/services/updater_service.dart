import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../utils/app_paths.dart';
import '../utils/executable_helper.dart';
import '../utils/logger.dart';

class UpdaterService {
  static final String binDir = AppPaths.binDir;

  /// Atualiza o yt-dlp
  static Future<bool> updateYtDlp() async {
    const url =
        "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe";
    final filePath = p.join(binDir, "yt-dlp.exe");
    return await _downloadFile(url, filePath, "yt-dlp");
  }

  /// Atualiza o spotDL (pega última release via API)
  static Future<bool> updateSpotdl() async {
    const apiUrl = "https://api.github.com/repos/spotDL/spotify-downloader/releases/latest";
    try {
      Logger.info("Consultando última versão do spotDL...");
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final assets = json["assets"] as List<dynamic>;
        final asset = assets.firstWhere(
              (a) => (a["name"] as String).toLowerCase().endsWith(".exe"),
          orElse: () => null,
        );

        if (asset != null) {
          final downloadUrl = asset["browser_download_url"];
          final filePath = p.join(binDir, "spotdl.exe");
          return await _downloadFile(downloadUrl, filePath, "spotDL");
        } else {
          Logger.error("Nenhum executável encontrado na release do spotDL.");
          return false;
        }
      } else {
        Logger.error("Falha ao consultar releases do spotDL: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      Logger.error("Erro ao atualizar spotDL: $e");
      return false;
    }
  }

  /// Atualiza spotdl+yt-dlp via pip (modo preferido quando spotdl vem do pip).
  static Future<bool> updateSpotdlPip() async {
    final runner = await ExecutableHelper.resolveSpotdlRunner();
    if (runner.$1 == AppPaths.spotdlExe) {
      Logger.error('spotdl não está em modo pip.');
      return false;
    }

    Logger.info('Atualizando spotdl/yt-dlp via pip...');
    try {
      final result = await Process.run(
        runner.$1,
        ['-m', 'pip', 'install', '--user', '--upgrade', 'spotdl', 'yt-dlp'],
      );
      if (result.exitCode == 0) {
        ExecutableHelper.resetSpotdlRunnerCache();
        Logger.info('spotdl/yt-dlp atualizados via pip.');
        return true;
      }
      Logger.error('pip install falhou (exitCode=${result.exitCode})');
      return false;
    } catch (e) {
      Logger.error('Erro ao atualizar via pip: $e');
      return false;
    }
  }

  /// Atualiza o FFmpeg.
  ///
  /// Baixa o zip oficial e extrai `bin/ffmpeg.exe` e `bin/ffprobe.exe` (o zip
  /// vem no formato `ffmpeg-<versao>-essentials_build/bin/...`) para
  /// [AppPaths.binDir], removendo o zip em seguida. Retorna `true` somente se
  /// a extração de `ffmpeg.exe` gerou o arquivo. `ffprobe.exe` é
  /// best-effort: sua ausência apenas gera aviso.
  static Future<bool> updateFfmpeg() async {
    const url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip";
    final zipPath = p.join(binDir, "ffmpeg.zip");
    final ffmpegPath = AppPaths.ffmpegExe;

    try {
      Logger.info("Baixando ffmpeg...");
      final downloaded = await _downloadFile(url, zipPath, "ffmpeg");
      if (!downloaded) return false;

      Logger.info("Extraindo ffmpeg...");
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? ffmpegEntry;
      ArchiveFile? ffprobeEntry;
      for (final entry in archive.files) {
        final entryName = entry.name.replaceAll('\\', '/');
        if (entryName.endsWith('bin/ffmpeg.exe')) {
          ffmpegEntry = entry;
        } else if (entryName.endsWith('bin/ffprobe.exe')) {
          ffprobeEntry = entry;
        }
      }

      if (ffmpegEntry == null) {
        Logger.error("ffmpeg.exe não encontrado no zip baixado.");
        return false;
      }

      final outFile = File(ffmpegPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(ffmpegEntry.content, flush: true);

      if (ffprobeEntry != null) {
        final ffprobeFile = File(AppPaths.ffprobeExe);
        await ffprobeFile.writeAsBytes(ffprobeEntry.content, flush: true);
        Logger.info("ffprobe extraído para ${ffprobeFile.path}");
      } else {
        Logger.warn("ffprobe.exe não encontrado no zip baixado.");
      }

      return outFile.existsSync();
    } catch (e) {
      Logger.error("Erro ao atualizar ffmpeg: $e");
      return false;
    } finally {
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        try {
          await zipFile.delete();
        } catch (_) {
          // Limpeza best-effort; a falha ao apagar o zip não invalida a
          // extração já concluída.
        }
      }
    }
  }

  /// Indica se o yt-dlp está velho o suficiente para justificar atualização.
  ///
  /// Função pura e testável: `true` quando a idade ultrapassa [maxAge].
  @visibleForTesting
  static bool shouldUpdateYtDlp(
    DateTime lastModified,
    DateTime now, {
    Duration maxAge = const Duration(days: 7),
  }) =>
      now.difference(lastModified) > maxAge;

  /// Garante que os executáveis necessários estejam presentes, baixando o
  /// que faltar. Retorna `false` se algum continuar ausente.
  ///
  /// Para YouTube, requer yt-dlp + ffmpeg. Para Spotify, requer ffmpeg +
  /// spotdl (preferindo a instalação via pip, com fallback para o exe).
  static Future<bool> ensureExecutables({required bool youtube}) async {
    if (youtube) {
      final ytDlpFile = File(AppPaths.ytDlpExe);

      if (!ytDlpFile.existsSync()) {
        Logger.info("yt-dlp não encontrado. Baixando...");
        await updateYtDlp();
      } else {
        bool needsUpdate;
        try {
          needsUpdate =
              shouldUpdateYtDlp(ytDlpFile.lastModifiedSync(), DateTime.now());
        } catch (e) {
          Logger.warn(
              "Não foi possível ler a data do yt-dlp ($e). Atualizando por precaução.");
          needsUpdate = true;
        }

        if (needsUpdate) {
          Logger.info("yt-dlp com mais de 7 dias. Atualizando proativamente...");
          final updated = await updateYtDlp();
          if (!updated) {
            // O exe antigo continua disponível; o retry de falha do
            // DownloadService ainda protege contra 403.
            Logger.warn(
                "Falha ao atualizar yt-dlp proativamente. Prosseguindo com o existente.");
          }
        }
      }

      await _ensureFfmpeg();

      final ytDlpOk = File(AppPaths.ytDlpExe).existsSync();
      final ffmpegOk = File(AppPaths.ffmpegExe).existsSync();

      if (!ytDlpOk || !ffmpegOk) {
        Logger.error(
            "Executáveis ausentes após tentativa de download "
            "(yt-dlp: $ytDlpOk, ffmpeg: $ffmpegOk).");
        return false;
      }

      return true;
    }

    // Fluxo Spotify: ffmpeg + spotdl (pip preferencial, fallback exe).
    await _ensureFfmpeg();

    final runner = await ExecutableHelper.resolveSpotdlRunner();
    var spotdlOk = true;

    if (runner.$1 == AppPaths.spotdlExe &&
        !File(AppPaths.spotdlExe).existsSync()) {
      Logger.info("spotdl.exe não encontrado. Baixando...");
      await updateSpotdl();
      spotdlOk = File(AppPaths.spotdlExe).existsSync();
    }

    final ffmpegOk = File(AppPaths.ffmpegExe).existsSync();

    if (!spotdlOk || !ffmpegOk) {
      Logger.error(
          "Não foi possível preparar o spotdl/ffmpeg. Instale Python e rode "
          "'pip install spotdl' ou verifique a conexão.");
      return false;
    }

    return true;
  }

  /// Garante que o ffmpeg esteja presente, baixando se necessário.
  static Future<void> _ensureFfmpeg() async {
    if (!File(AppPaths.ffmpegExe).existsSync()) {
      Logger.info("ffmpeg não encontrado. Baixando...");
      await updateFfmpeg();
    }
  }

  /// Função auxiliar
  static Future<bool> _downloadFile(String url, String filePath, String name) async {
    final client = http.Client();
    try {
      Logger.info("Baixando $name de $url...");
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        Logger.info("$name atualizado com sucesso!");
        return true;
      } else {
        Logger.error("Falha ao baixar $name: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      Logger.error("Erro ao atualizar $name: $e");
      return false;
    } finally {
      client.close();
    }
  }
}
