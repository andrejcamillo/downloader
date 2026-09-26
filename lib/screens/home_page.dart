import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/home_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/download_section.dart';
import '../widgets/status_section.dart';
import '../screens/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeController, SettingsController>(
      builder: (context, homeController, settings, _) {
        final theme = Theme.of(context);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Music Downloader"),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: "Configurações",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Container(decoration: BoxDecoration(
            image: settings.backgroundImage != null
                ? DecorationImage(
              image: settings.backgroundImage!,
              fit: BoxFit.cover,
            )
                : null,
            gradient: settings.backgroundImage == null
                ? const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
          ),

            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24.0,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 24.0,
                  24.0,
                  24.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 300,
                    maxWidth: 600,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔹 Download section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: DownloadSection(
                          onDownload: (link, fromYouTube, mp3Format, outputDir,
                              generateM3u) {
                            homeController.performDownload(
                              rawLink: link,
                              fromYouTube: fromYouTube,
                              mp3Format: mp3Format,
                              finalOutputDir: outputDir,
                              generateM3u: generateM3u,
                            );
                          },
                          isDownloading: homeController.isDownloading,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 🔹 Status section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: StatusSection(
                          isDownloading: homeController.isDownloading,
                          progress: homeController.progress,
                          statusMessage: homeController.status,
                          playlistName: homeController.playlistName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
