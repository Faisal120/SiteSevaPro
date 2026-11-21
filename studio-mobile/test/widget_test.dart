import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siteseva/app.dart';
import 'package:siteseva/features/auth/splash_screen.dart';

void main() {
  testWidgets('App starts on the branded splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SiteSevaApp()));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
