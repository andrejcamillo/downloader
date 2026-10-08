import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Retorna os caminhos presentes em [after] mas não em [before].
  @visibleForTesting
  static List<String> diffNewFiles(List<String> before, List<String> after) {
    final beforeSet = before.toSet();
    return after.where((f) => !beforeSet.contains(f)).toList();
  }

  /// Apaga todo o conteúdo de [dirPath] recursivamente, mantendo o diretório
  /// raiz. Se o diretório não existir, não faz nada.
  /// Erros ao deletar itens individuais são logados e o método continua.
  static Future<void> clearDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return;
    }

    // Usa listagem não recursiva: cada entrada de nível raiz é deletada com
    // delete(recursive: true), que remove subdiretórios inteiros. A lista é
    // materializada antes de deletar para evitar pular entradas ao alterar o
    // diretório durante a enumeração (problema em algumas plataformas).
    final entities = await dir.list().toList();

    for (final entity in entities) {
      try {
        await entity.delete(recursive: true);
      } catch (e) {
        Logger.error("Falha ao deletar ${entity.path}: $e");
      }
    }
  }
}
