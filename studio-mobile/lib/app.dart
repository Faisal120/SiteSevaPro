import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/notifications/providers/push_notifications_provider.dart';

class SiteSevaApp extends ConsumerWidget {
  const SiteSevaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    ref.listen(pushNotificationRouteProvider, (previous, next) {
      final route = next.valueOrNull;
      if (route == null || route.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => router.go(route));
    });
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SiteSeva Pro',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: router,
    );
  }
}
