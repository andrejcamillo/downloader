import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/file_service.dart';

class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  String _mp3Dir = '';
  String _mp4Dir = '';

  bool _useCustomBackground = false;
  String? _customBackgroundPath;

  final FileService _fileService = FileService();

  ThemeMode get themeMode => _themeMode;
  String get mp3Dir => _mp3Dir;
  String get mp4Dir => _mp4Dir;
  bool get useCustomBackground => _useCustomBackground;
  String? get customBackgroundPath => _customBackgroundPath;

  SettingsController._();

  static Future<SettingsController> create() async {
    final controller = SettingsController._();
    await controller._loadPreferences();
    return controller;
  }

  ImageProvider? get backgroundImage {
    if (_useCustomBackground) {
      if (_customBackgroundPath != null &&
          File(_customBackgroundPath!).existsSync()) {
        return FileImage(File(_customBackgroundPath!));
      } else {
        return const AssetImage('assets/images/fundo.png');
      }
    }
    return null; // deixa o gradiente aparecer
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode');
    _themeMode = themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.system;

    _mp3Dir = prefs.getString('mp3Dir') ?? '';
    _mp4Dir = prefs.getString('mp4Dir') ?? '';

    _useCustomBackground = prefs.getBool('useCustomBackground') ?? false;
    _customBackgroundPath = prefs.getString('customBackgroundPath');

    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> pickDirectory(String type) async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      final dir = await _fileService.ensureOutputDir(path);
      final prefs = await SharedPreferences.getInstance();
      if (type == "mp3") {
        _mp3Dir = dir.path;
        await prefs.setString('mp3Dir', dir.path);
      } else {
        _mp4Dir = dir.path;
        await prefs.setString('mp4Dir', dir.path);
      }
      notifyListeners();
    }
  }

  Future<void> setUseCustomBackground(bool value) async {
    _useCustomBackground = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCustomBackground', value);
  }

  Future<void> pickCustomBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      _customBackgroundPath = result.files.single.path;
      _useCustomBackground = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customBackgroundPath', _customBackgroundPath!);
      await prefs.setBool('useCustomBackground', true);
    }
  }

  Future<void> removeCustomBackground() async {
    _customBackgroundPath = null;
    _useCustomBackground = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customBackgroundPath');
    await prefs.setBool('useCustomBackground', false);
  }

  Future<void> resetSettings() async {
    _themeMode = ThemeMode.system;
    _mp3Dir = '';
    _mp4Dir = '';
    _useCustomBackground = false;
    _customBackgroundPath = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
