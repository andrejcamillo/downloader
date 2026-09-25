import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../utils/logger.dart';

class UpdaterService {
  static final String binDir = p.join(Directory.current.path, "bin");

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

  /// Atualiza o FFmpeg
  static Future<bool> updateFfmpeg() async {
    const url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip";
    final zipPath = p.join(binDir, "ffmpeg.zip");

    try {
      Logger.info("Baixando ffmpeg...");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(zipPath).writeAsBytes(response.bodyBytes);
        Logger.info("ffmpeg baixado (precisa ser descompactado).");
        return true;
      } else {
        Logger.error("Falha ao baixar ffmpeg: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      Logger.error("Erro ao atualizar ffmpeg: $e");
      return false;
    }
  }

  /// Função auxiliar
  static Future<bool> _downloadFile(String url, String filePath, String name) async {
    try {
      Logger.info("Baixando $name de $url...");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(filePath);
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
    }
  }
}
