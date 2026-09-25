import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;
  final String mp3Dir;
  final String mp4Dir;
  final VoidCallback onPickMp3Dir;
  final VoidCallback onPickMp4Dir;
  final bool useCustomBackground;
  final Function(bool) onToggleBackground;
  final String? customBackgroundPath;
  final VoidCallback onPickBackground;
  final VoidCallback onRemoveBackground;
  final VoidCallback onResetSettings;

  const SettingsSection({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.mp3Dir,
    required this.mp4Dir,
    required this.onPickMp3Dir,
    required this.onPickMp4Dir,
    required this.useCustomBackground,
    required this.onToggleBackground,
    required this.customBackgroundPath,
    required this.onPickBackground,
    required this.onRemoveBackground,
    required this.onResetSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Tema compacto
        const Text("Tema", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Tooltip(
              message: "Tema claro",
              child: IconButton(
                icon: const Icon(Icons.light_mode, color: Colors.amber),
                onPressed: () => onThemeChanged(ThemeMode.light),
                color: currentTheme == ThemeMode.light
                    ? Colors.amber
                    : Colors.grey,
              ),
            ),
            Tooltip(
              message: "Tema escuro",
              child: IconButton(
                icon: const Icon(Icons.dark_mode, color: Colors.deepPurple),
                onPressed: () => onThemeChanged(ThemeMode.dark),
                color: currentTheme == ThemeMode.dark
                    ? Colors.deepPurple
                    : Colors.grey,
              ),
            ),
            Tooltip(
              message: "Seguir sistema",
              child: IconButton(
                icon: const Icon(Icons.phone_android, color: Colors.blue),
                onPressed: () => onThemeChanged(ThemeMode.system),
                color: currentTheme == ThemeMode.system
                    ? Colors.blue
                    : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 Diretórios mais enxutos
        const Text("Diretórios de downloads",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Tooltip(
              message: mp3Dir,
              child: Text("MP3: ${mp3Dir.split('\\').last}"),
            ),
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: onPickMp3Dir,
            ),
          ],
        ),
        Row(
          children: [
            Tooltip(
              message: mp4Dir,
              child: Text("MP4: ${mp4Dir.split('\\').last}"),
            ),
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: onPickMp4Dir,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 Plano de fundo
        const Text("Plano de Fundo",
            style: TextStyle(fontWeight: FontWeight.bold)),
        SwitchListTile(
          title: const Text("Usar fundo personalizado"),
          value: useCustomBackground,
          onChanged: onToggleBackground,
        ),
        if (customBackgroundPath != null)
          Tooltip(
            message: customBackgroundPath!,
            child: Text(
              customBackgroundPath!.split('\\').last,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: onPickBackground,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onRemoveBackground,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 Botões de atualização
        Row(
          children: [
            Tooltip(
              message: "Atualizar YouTube (yt-dlp)",
              child: IconButton(
                icon: const Icon(Icons.video_library, color: Colors.red),
                onPressed: () {
                  // vai chamar no controller
                },
              ),
            ),
            Tooltip(
              message: "Atualizar Spotify (spotDL)",
              child: IconButton(
                icon: const Icon(Icons.music_note, color: Colors.green),
                onPressed: () {
                  // vai chamar no controller
                },
              ),
            ),
            Tooltip(
              message: "Atualizar todos (inclui ffmpeg)",
              child: IconButton(
                icon: const Icon(Icons.system_update, color: Colors.blue),
                onPressed: () {
                  // vai chamar no controller
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 Resetar configurações
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          icon: const Icon(Icons.restore),
          label: const Text("Resetar configurações"),
          onPressed: onResetSettings,
        ),
      ],
    );
  }
}
