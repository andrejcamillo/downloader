import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../services/updater_service.dart';
import '../utils/logger.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = false;
  String _status = "";

  Future<void> _updateExecutable(
      Future<bool> Function() updater, String name) async {
    setState(() {
      _loading = true;
      _status = "Atualizando $name...";
    });

    final success = await updater();

    setState(() {
      _loading = false;
      _status = success
          ? "$name atualizado com sucesso!"
          : "Falha ao atualizar $name.";
    });

    Logger.info(_status);
  }

  Future<void> _updateAll() async {
    setState(() {
      _loading = true;
      _status = "Atualizando todos os pacotes...";
    });

    final yt = await UpdaterService.updateYtDlp();
    final spot = await UpdaterService.updateSpotdl();
    final ffmpeg = await UpdaterService.updateFfmpeg();

    final success = yt && spot && ffmpeg;

    setState(() {
      _loading = false;
      _status = success
          ? "Todos os pacotes foram atualizados com sucesso!"
          : "Alguns pacotes falharam na atualização.";
    });

    Logger.info(_status);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Configurações'),
            centerTitle: true,
            actions: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Tema
                  const Text("Tema",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Tooltip(
                        message: "Claro",
                        child: IconButton(
                          icon: const Icon(Icons.light_mode, color: Colors.amber),
                          onPressed: () =>
                              controller.changeTheme(ThemeMode.light),
                          color: controller.themeMode == ThemeMode.light
                              ? Colors.amber
                              : Colors.grey,
                        ),
                      ),
                      Tooltip(
                        message: "Escuro",
                        child: IconButton(
                          icon: const Icon(Icons.dark_mode,
                              color: Colors.deepPurple),
                          onPressed: () =>
                              controller.changeTheme(ThemeMode.dark),
                          color: controller.themeMode == ThemeMode.dark
                              ? Colors.deepPurple
                              : Colors.grey,
                        ),
                      ),
                      Tooltip(
                        message: "Sistema",
                        child: IconButton(
                          icon: const Icon(Icons.phone_android, color: Colors.blue),
                          onPressed: () =>
                              controller.changeTheme(ThemeMode.system),
                          color: controller.themeMode == ThemeMode.system
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // 🔹 Diretórios
                  const Text("Diretórios de downloads",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Tooltip(
                        message: controller.mp3Dir,
                        child: Text("MP3: ${controller.mp3Dir.split('\\').last}"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder),
                        onPressed: () => controller.pickDirectory("mp3"),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: controller.mp4Dir,
                        child: Text("MP4: ${controller.mp4Dir.split('\\').last}"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder),
                        onPressed: () => controller.pickDirectory("mp4"),
                      ),
                    ],
                  ),
                  const Divider(),

                  // 🔹 Plano de fundo
                  const Text("Plano de Fundo",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Usar fundo personalizado"),
                    value: controller.useCustomBackground,
                    onChanged: controller.setUseCustomBackground,
                  ),
                  if (controller.customBackgroundPath != null)
                    Tooltip(
                      message: controller.customBackgroundPath!,
                      child: Text(
                        controller.customBackgroundPath!.split('\\').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: controller.pickCustomBackground,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: controller.removeCustomBackground,
                      ),
                    ],
                  ),
                  const Divider(),

                  // 🔹 Botões de atualização
                  const Text("Atualizações",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Tooltip(
                        message: "Atualizar YouTube (yt-dlp)",
                        child: IconButton(
                          icon:
                          const Icon(Icons.video_library, color: Colors.red),
                          onPressed: () => _updateExecutable(
                              UpdaterService.updateYtDlp, "yt-dlp"),
                        ),
                      ),
                      Tooltip(
                        message: "Atualizar Spotify (spotDL)",
                        child: IconButton(
                          icon: const Icon(Icons.music_note, color: Colors.green),
                          onPressed: () => _updateExecutable(
                              UpdaterService.updateSpotdl, "spotDL"),
                        ),
                      ),
                      Tooltip(
                        message: "Atualizar todos (inclui ffmpeg)",
                        child: IconButton(
                          icon: const Icon(Icons.system_update,
                              color: Colors.blue),
                          onPressed: _updateAll,
                        ),
                      ),
                    ],
                  ),
                  if (_status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _status.contains("falha")
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  const Divider(),

                  // 🔹 Resetar configurações
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.restore),
                      label: const Text("Resetar configurações"),
                      onPressed: controller.resetSettings,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
