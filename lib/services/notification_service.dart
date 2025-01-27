import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // no icon for now
      [
        NotificationChannel(
          channelKey: 'reality_check_channel',
          channelName: 'Reality Check Notifications',
          channelDescription: 'Periodic reality check notifications',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          playSound: false,
        )
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleRealityCheck(int intervalMinutes, String soundFile) async {
    await AwesomeNotifications().cancelAll();
    
    if (intervalMinutes <= 0) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'reality_check_channel',
        title: 'Reality Check',
        body: 'Time to check if you are dreaming!',
        notificationLayout: NotificationLayout.Default,
      ),
    );

    await playSound(soundFile);

    // Schedule the next check
    Future.delayed(Duration(minutes: intervalMinutes), () {
      scheduleRealityCheck(intervalMinutes, soundFile);
    });
  }

  Future<void> playSound(String soundFile) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> stopNotifications() async {
    await AwesomeNotifications().cancelAll();
    await _audioPlayer.stop();
  }
} 