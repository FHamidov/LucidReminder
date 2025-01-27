import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _notificationTimer;
  
  Future<void> initialize() async {
    // No initialization needed for this simplified version
  }

  Future<void> scheduleRealityCheck(int intervalMinutes, String soundFile) async {
    _notificationTimer?.cancel();
    
    if (intervalMinutes <= 0) return;

    // Play sound immediately
    await playSound(soundFile);

    // Schedule periodic checks
    _notificationTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => playSound(soundFile),
    );
  }

  Future<void> playSound(String soundFile) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> stopNotifications() async {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    await _audioPlayer.stop();
  }
} 