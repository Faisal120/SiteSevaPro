import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/network/api_service.dart';

@pragma('vm:entry-point')
Future<void> siteSevaFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

class PushNotificationsService {
  PushNotificationsService._();

  static final instance = PushNotificationsService._();
  static const _channel = AndroidNotificationChannel(
    'siteseva_operations',
    'SiteSeva operations',
    description: 'Live project, payment, stock and attendance alerts.',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _routes = StreamController<String>.broadcast();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _ready = false;
  String? _registeredToken;
  String? _pendingRoute;

  Stream<String> get routes async* {
    final pending = _pendingRoute;
    _pendingRoute = null;
    if (pending != null) yield pending;
    yield* _routes.stream;
  }

  Future<void> initialize() async {
    if (_ready || kIsWeb || !_isMobilePlatform) return;
    try {
      FirebaseMessaging.onBackgroundMessage(
        siteSevaFirebaseMessagingBackgroundHandler,
      );
      await Firebase.initializeApp();
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = _safeRoute(response.payload);
          if (route != null) _routes.add(route);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openRemoteMessage,
      );
      _tokenSubscription = FirebaseMessaging.instance.onRegistered.listen(
        _registerToken,
      );
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _pendingRoute = _routeForMessage(initialMessage);
      }
      _ready = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Push notifications are unavailable: $error');
      }
    }
  }

  Future<void> syncRegistration() async {
    if (!_ready || ApiService.token?.isNotEmpty != true) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await FirebaseMessaging.instance.register();
    } catch (error) {
      if (kDebugMode) debugPrint('Push registration failed: $error');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    final token = _registeredToken;
    if (!_ready || token == null || ApiService.token?.isNotEmpty != true) {
      return;
    }
    try {
      await ApiService.unregisterPushDevice(token);
      _registeredToken = null;
    } catch (error) {
      if (kDebugMode) debugPrint('Push unregister failed: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    if (ApiService.token?.isNotEmpty != true) return;
    try {
      await ApiService.registerPushDevice(
        token: token,
        platform: defaultTargetPlatform.name,
      );
      _registeredToken = token;
    } catch (error) {
      if (kDebugMode) debugPrint('Push token sync failed: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? '${message.data['title'] ?? ''}';
    final body =
        notification?.body ??
        '${message.data['message'] ?? message.data['body'] ?? ''}';
    if (title.isEmpty && body.isEmpty) return;
    await _local.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title.isEmpty ? 'SiteSeva Pro' : title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'siteseva_operations',
          'SiteSeva operations',
          channelDescription:
              'Live project, payment, stock and attendance alerts.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _routeForMessage(message),
    );
  }

  void _openRemoteMessage(RemoteMessage message) {
    _routes.add(_routeForMessage(message));
  }

  String _routeForMessage(RemoteMessage message) {
    final id = '${message.data['notification_id'] ?? message.data['id'] ?? ''}'
        .trim();
    if (id.isNotEmpty) return '/notifications/${Uri.encodeComponent(id)}';
    return _safeRoute('${message.data['action_url'] ?? ''}') ??
        '/notifications';
  }

  String? _safeRoute(String? value) {
    final route = value?.trim();
    if (route == null || !route.startsWith('/') || route.startsWith('//')) {
      return null;
    }
    const allowedRoots = {
      '/',
      '/sites',
      '/labour',
      '/attendance',
      '/materials',
      '/payments',
      '/expenses',
      '/reports',
      '/notifications',
      '/planning',
      '/subscription',
    };
    return allowedRoots.any(
          (root) =>
              route == root || (root != '/' && route.startsWith('$root/')),
        )
        ? route
        : '/notifications';
  }

  bool get _isMobilePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _routes.close();
  }
}
