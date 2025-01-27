import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

const String taskName = 'realityCheckTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == taskName) {
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('isEnabled') ?? false;
        final selectedSound = prefs.getString('selectedSound') ?? 'notification.mp3';
        
        if (isEnabled) {
          final player = AudioPlayer();
          await player.play(AssetSource('sounds/$selectedSound'));
          // Keep the task running for a few seconds to ensure sound plays
          await Future.delayed(const Duration(seconds: 3));
          await player.dispose();
        }
      }
      return true;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> scheduleRealityCheck(int intervalMinutes, String soundFile) async {
    await Workmanager().cancelAll();
    
    if (intervalMinutes <= 0) return;

    // Play sound immediately
    await playSound(soundFile);

    // Schedule periodic task with minimum battery optimizations
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: Duration(minutes: 1),
    );
  }

  Future<void> playSound(String soundFile) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> stopNotifications() async {
    await Workmanager().cancelAll();
    await _audioPlayer.stop();
  }
} 