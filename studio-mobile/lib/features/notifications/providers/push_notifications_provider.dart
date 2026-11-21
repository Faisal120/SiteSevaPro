import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/push_notifications_service.dart';

final pushNotificationRouteProvider = StreamProvider<String>((ref) {
  return PushNotificationsService.instance.routes;
});
