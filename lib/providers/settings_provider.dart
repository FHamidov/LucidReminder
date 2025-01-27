import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isEnabled = false;
  int _intervalMinutes = 30;
  String _selectedSound = 'notification.mp3';

  bool get isEnabled => _isEnabled;
  int get intervalMinutes => _intervalMinutes;
  String get selectedSound => _selectedSound;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('isEnabled') ?? false;
    _intervalMinutes = prefs.getInt('intervalMinutes') ?? 30;
    _selectedSound = prefs.getString('selectedSound') ?? 'notification.mp3';
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnabled', value);
    notifyListeners();
  }

  Future<void> setIntervalMinutes(int minutes) async {
    _intervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intervalMinutes', minutes);
    notifyListeners();
  }

  Future<void> setSelectedSound(String soundFile) async {
    _selectedSound = soundFile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSound', soundFile);
    notifyListeners();
  }
} 