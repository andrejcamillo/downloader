import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class DownloadLogger {
  // A função agora aceita um caminho de lista (para Spotify) e uma URL (para YouTube ou um único item).
  // A lógica interna determinará se deve usar --list ou processar uma URL.
  static Future<void> baixarMusicasComLog(BuildContext context, {String? listaPath, String? url}) async {
    final currentDir = Directory.current.path;
    final logFile = File('$currentDir${Platform.pathSeparator}log.txt');
    final spotdl = '$currentDir${Platform.pathSeparator}bin${Platform.pathSeparator}spotdl.exe';

    final List<String> args = [
      '--output', 'musicas',
      '--audio-format', 'mp3', // Explicitamente define o formato de saída como MP3
    ];

    if (listaPath != null && await File(listaPath).exists()) {
      args.addAll(['--list', listaPath]);
    } else if (url != null && url.isNotEmpty) {
      args.add(url);
    } else {
      // Se nem a lista nem a URL forem fornecidas, exiba uma mensagem de erro
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma lista de arquivos ou URL fornecida.')),
        );
      }
      return;
    }

    final process = await Process.start(
      spotdl,
      args,
      runInShell: true,
    );

    final logSink = logFile.openWrite(mode: FileMode.append);

    logSink.writeln('[INICIADO] Executando spotdl com argumentos: ${args.join(' ')}');

    process.stdout.transform(utf8.decoder).listen((data) {
      // Filtra as linhas de progresso para manter o log limpo, mas ainda útil
      if (data.contains('Downloading') || data.contains('Converting') || data.contains('Finished')) {
        logSink.writeln('[SPOTDL]: $data');
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      logSink.writeln('[ERRO]: $data');
    });

    final exitCode = await process.exitCode;
    logSink.writeln('[FINALIZADO] Código de saída: $exitCode');
    await logSink.flush();
    await logSink.close();

    if (exitCode != 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao executar o download. Verifique o log.txt')),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download concluído com sucesso!')),
      );
    }
  }
}
