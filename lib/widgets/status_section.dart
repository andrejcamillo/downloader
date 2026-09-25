import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusSection extends StatelessWidget {
  final bool isDownloading;
  final double progress;
  final String statusMessage;
  final String? playlistName;

  const StatusSection({
    super.key,
    required this.isDownloading,
    required this.progress,
    required this.statusMessage,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔹 Barra de progresso
        if (isDownloading) ...[
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
        ],

        // 🔹 Caixa de status com botão copiar
        if (statusMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensagem copiável
                Expanded(
                  child: SelectableText(
                    statusMessage,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontFamily: "monospace",
                      fontSize: 14,
                    ),
                  ),
                ),

                // Botão copiar
                IconButton(
                  tooltip: "Copiar mensagem",
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: statusMessage));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Mensagem copiada para área de transferência"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        // 🔹 Playlist
        if (playlistName != null && playlistName!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            "Playlist: $playlistName",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ],
    );
  }
}
