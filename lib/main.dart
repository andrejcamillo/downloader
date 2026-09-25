import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

import 'controllers/home_controller.dart';
import 'controllers/settings_controller.dart';
import 'screens/home_page.dart';
import 'utils/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(500, 800)); // Tamanho mínimo
    setWindowMaxSize(Size.infinite);        // Permite maximizar
  }

  // 🔹 Inicializa o SettingsController antes do app
  final settingsController = await SettingsController.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider.value(value: settingsController),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Music Downloader',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: settings.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
