import 'dart:convert';
import 'dart:io';

import '../../../core/network/api_service.dart';

typedef NotificationRealtimeEvent = void Function(
  Map<String, dynamic> payload,
);
typedef NotificationRealtimeDisconnect = void Function(Object? error);

abstract interface class NotificationRealtimeClient {
  Future<void> connect({
    required NotificationRealtimeEvent onEvent,
    required NotificationRealtimeDisconnect onDisconnected,
  });

  Future<void> disconnect();
}

class HttpNotificationRealtimeClient implements NotificationRealtimeClient {
  WebSocket? _socket;
  bool _intentionalDisconnect = false;

  @override
  Future<void> connect({
    required NotificationRealtimeEvent onEvent,
    required NotificationRealtimeDisconnect onDisconnected,
  }) async {
    await disconnect();
    _intentionalDisconnect = false;
    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'A signed-in session is required for realtime notifications.',
        kind: ApiErrorKind.authentication,
      );
    }
    final socket = await WebSocket.connect(
      ApiService.notificationsWebSocketUri.toString(),
      headers: {'Authorization': 'Bearer $token'},
    );
    _socket = socket;
    var disconnected = false;
    void notifyDisconnected([Object? error]) {
      if (disconnected || _intentionalDisconnect) return;
      disconnected = true;
      onDisconnected(error);
    }

    socket.listen(
      (event) => _decode(event, onEvent),
      onError: (Object error) => notifyDisconnected(error),
      onDone: notifyDisconnected,
      cancelOnError: false,
    );
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    final socket = _socket;
    _socket = null;
    await socket?.close(WebSocketStatus.normalClosure, 'client disconnect');
  }

  void _decode(Object? event, NotificationRealtimeEvent onEvent) {
    Object? decoded = event;
    if (event is String) {
      try {
        decoded = jsonDecode(event);
      } on FormatException {
        return;
      }
    }
    if (decoded is! Map) return;
    final map = Map<String, dynamic>.from(decoded);
    final nested = map['notification'] ?? map['data'] ?? map['payload'];
    final payload = nested is Map ? Map<String, dynamic>.from(nested) : map;
    onEvent(payload);
  }
}
