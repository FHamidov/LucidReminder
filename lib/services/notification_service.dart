import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

const String taskName = 'realityCheckTask';
const String portName = 'reality_check_port';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == taskName) {
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('isEnabled') ?? false;
        final selectedSound = prefs.getString('selectedSound') ?? 'notification.mp3';
        final intervalMinutes = prefs.getInt('intervalMinutes') ?? 30;
        
        if (isEnabled) {
          final player = AudioPlayer();
          await player.play(AssetSource('sounds/$selectedSound'));
          await Future.delayed(const Duration(seconds: 3));
          await player.dispose();

          // For 1-minute intervals, schedule the next task immediately
          if (intervalMinutes == 1) {
            final SendPort? send = IsolateNameServer.lookupPortByName(portName);
            send?.send('schedule_next');
          }
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
  Timer? _oneMinuteTimer;
  ReceivePort? _receivePort;
  
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Set up communication channel for 1-minute intervals
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, portName);
    
    _receivePort!.listen((message) {
      if (message == 'schedule_next') {
        _scheduleNextMinute();
      }
    });
  }

  Future<void> _scheduleNextMinute() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isEnabled') ?? false;
    if (isEnabled) {
      await scheduleRealityCheck(1, prefs.getString('selectedSound') ?? 'notification.mp3');
    }
  }

  Future<void> scheduleRealityCheck(int intervalMinutes, String soundFile) async {
    await Workmanager().cancelAll();
    _oneMinuteTimer?.cancel();
    
    if (intervalMinutes <= 0) return;

    // Play sound immediately
    await playSound(soundFile);

    if (intervalMinutes == 1) {
      // For 1-minute intervals, use immediate scheduling
      _oneMinuteTimer = Timer(const Duration(minutes: 1), () async {
        await playSound(soundFile);
        _scheduleNextMinute();
      });
    } else {
      // For longer intervals, use WorkManager
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
    _oneMinuteTimer?.cancel();
    _oneMinuteTimer = null;
    await _audioPlayer.stop();
  }

  void dispose() {
    _oneMinuteTimer?.cancel();
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(portName);
  }
} 