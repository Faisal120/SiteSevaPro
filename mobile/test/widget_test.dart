import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siteseva/core/app_controller.dart';
import 'package:siteseva/main.dart';

void main() {
  testWidgets('shows the SiteSeva login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();

    await tester.pumpWidget(SiteSevaApp(controller: controller));

    expect(find.text('SiteSeva Pro'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.text('Contractor account ke liye apply karein'),
      findsOneWidget,
    );
  });
}
