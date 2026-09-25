import 'dart:io';
import '../utils/logger.dart';

class FileService {
  /// Garante que o diretório exista
  Future<Directory> ensureOutputDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      Logger.info("Diretório criado: ${dir.path}");
    } else {
      Logger.info("Diretório já existente: ${dir.path}");
    }
    return dir;
  }

  /// Move os arquivos baixados da pasta temp para a pasta final
  static Future<List<String>> moveFilesFromTempToFinal(
      String tempDir, String finalDir) async {
    final tempDirectory = Directory(tempDir);
    final finalDirectory = Directory(finalDir);

    if (!await finalDirectory.exists()) {
      await finalDirectory.create(recursive: true);
      Logger.info("Diretório final criado: ${finalDirectory.path}");
    }

    final files = tempDirectory.listSync().whereType<File>().toList();

    if (files.isEmpty) {
      Logger.info("Nenhum arquivo encontrado em $tempDir para mover.");
    }

    final movedFiles = <String>[];

    for (final file in files) {
      final newPath =
          '${finalDirectory.path}${Platform.pathSeparator}${file.uri.pathSegments.last}';
      try {
        await file.rename(newPath);
        movedFiles.add(newPath);
        Logger.info("Arquivo movido: ${file.path} → $newPath");
      } catch (e) {
        Logger.error("Erro ao mover arquivo ${file.path}: $e");
      }
    }

    return movedFiles;
  }

  /// Lista novos arquivos na pasta
  static List<String> listNewFiles(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      Logger.error("Diretório não encontrado: $dirPath");
      return [];
    }

    final files = dir
        .listSync(recursive: false)
        .whereType<File>()
        .map((f) => f.path)
        .toList();

    Logger.info("Arquivos encontrados em $dirPath: ${files.length}");
    return files;
  }
}
