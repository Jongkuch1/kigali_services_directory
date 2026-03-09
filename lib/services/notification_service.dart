import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Top-level handler for background/terminated FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray.
  // No additional processing needed here.
  debugPrint('FCM background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once after Firebase.initializeApp(), before runApp().
  static Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call after the user is authenticated. Requests permission, saves the
  /// FCM token to Firestore, and subscribes to the default topic.
  Future<void> initialize(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _saveTokenToFirestore(uid);

      // Refresh token whenever it changes
      _messaging.onTokenRefresh.listen((token) {
        _saveToken(uid, token);
      });

      // Subscribe to the default app topic
      await _messaging.subscribeToTopic('kigali_services');
    }
  }

  Future<void> _saveTokenToFirestore(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  /// Subscribe to location-based alerts topic.
  Future<void> enableLocationNotifications() async {
    await _messaging.subscribeToTopic('kigali_location');
  }

  /// Unsubscribe from location-based alerts topic.
  Future<void> disableLocationNotifications() async {
    await _messaging.unsubscribeFromTopic('kigali_location');
  }

  /// Subscribe to general push notifications topic.
  Future<void> enablePushNotifications() async {
    await _messaging.subscribeToTopic('kigali_services');
  }

  /// Unsubscribe from general push notifications topic.
  Future<void> disablePushNotifications() async {
    await _messaging.unsubscribeFromTopic('kigali_services');
  }

  /// Listen for foreground messages and display them as a SnackBar.
  /// Call this inside a widget that has a Scaffold in scope.
  static void listenForeground(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF1A2C42),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? 'Kigali Services',
                style: const TextStyle(
                  color: Color(0xFFF5A623),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (notification.body != null)
                Text(
                  notification.body!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
