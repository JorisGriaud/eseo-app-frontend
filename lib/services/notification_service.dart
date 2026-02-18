import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'auth_service.dart';

/// Instance for local notifications (nullable for lazy initialization)
FlutterLocalNotificationsPlugin? _localNotifications;

/// Top-level function for background message handler
/// Must be outside the class and at the top level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print('Handling background message: ${message.notification?.title}');

  // Show notification
  await _showNotification(message);
}

/// Show local notification
Future<void> _showNotification(RemoteMessage message) async {
  _localNotifications ??= FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'Notifications importantes',
    channelDescription: 'Canal pour les notifications importantes de l\'application',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  try {
    await _localNotifications!.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      notificationDetails,
    );
  } catch (e) {
    print('Error showing notification: $e');
  }
}

/// Firebase Cloud Messaging service for push notifications
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');

      try {
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          // Register token with backend
          await _registerToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_registerToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      } catch (e) {
        print('Error initializing Firebase Messaging: $e');
        print('The app will continue without push notifications.');
        print('To fix: Add SHA-1 fingerprint to Firebase Console.');
      }
    } else {
      print('User declined or has not accepted notification permission');
    }
  }

  /// Register FCM token with backend
  static Future<void> _registerToken(String token) async {
    try {
      await AuthService.registerDeviceToken(token);
      print('Device token registered with backend');
    } catch (e) {
      print('Failed to register device token: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return; // Not supported on web

    _localNotifications ??= FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(settings);

    // Create Android notification channel
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifications importantes',
        description: 'Canal pour les notifications importantes de l\'application',
        importance: Importance.high,
      );

      await _localNotifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    // Show notification when app is in foreground
    _showNotification(message);
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
