import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../services/file_service.dart';
import '../utils/app_paths.dart';

class HomeController extends ChangeNotifier {
  // Estado
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';
  String? _currentPlaylistName;

  // Caminhos executáveis
  late final String _ytDlpTempDir;

  // Pastas padrão
  late final String _defaultMp3Dir;
  late final String _defaultMp4Dir;

  // Getters
  bool get isDownloading => _isDownloading;
  double get progress => _downloadProgress;
  String get status => _statusMessage;
  String? get playlistName => _currentPlaylistName;

  HomeController() {
    _ytDlpTempDir = AppPaths.tempDir;
    _defaultMp3Dir = AppPaths.defaultMp3Dir;
    _defaultMp4Dir = AppPaths.defaultMp4Dir;

    // Usa FileService para garantir que as pastas existam
    FileService().ensureOutputDir(_ytDlpTempDir);
    FileService().ensureOutputDir(_defaultMp3Dir);
    FileService().ensureOutputDir(_defaultMp4Dir);
  }

  /// Limpa e prepara o link
  String sanitizeLink(String rawLink) {
    String link = rawLink.trim();

    if ((link.startsWith('"') && link.endsWith('"')) ||
        (link.startsWith("'") && link.endsWith("'"))) {
      link = link.substring(1, link.length - 1);
    }

    link = link.replaceAll('“', '').replaceAll('”', '');
    return link;
  }

  /// Executa o download
  Future<void> performDownload({
    required String rawLink,
    required bool fromYouTube,
    required bool mp3Format,
    required String finalOutputDir,
    bool generateM3u = true,
  }) async {
    if (_isDownloading) return;

    final link = sanitizeLink(rawLink);
    if (link.isEmpty) {
      _statusMessage = 'Link inválido';
      notifyListeners();
      return;
    }

    _isDownloading = true;
    _statusMessage = 'Iniciando download...';
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // fallback → pasta default se usuário não informar
      String resolvedOutputDir = finalOutputDir.isNotEmpty
          ? finalOutputDir
          : (mp3Format ? _defaultMp3Dir : _defaultMp4Dir);

      // garante que a pasta exista
      await FileService().ensureOutputDir(resolvedOutputDir);

      final downloader = DownloadService(ytDlpTempDir: _ytDlpTempDir);

      await downloader.performDownload(
        isYouTube: fromYouTube,
        isMp3: mp3Format,
        link: link,
        finalOutputDir: resolvedOutputDir,
        generateM3u: generateM3u,
        playlistName: _currentPlaylistName,
      );

      _isDownloading = false;
      _downloadProgress = 0.0;
      _statusMessage = 'Download concluído!';
      notifyListeners();
    } catch (e) {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _statusMessage = 'Erro no download: $e';
      notifyListeners();
    }
  }
}
