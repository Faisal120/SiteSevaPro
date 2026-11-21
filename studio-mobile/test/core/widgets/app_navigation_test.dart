import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/core/widgets/app_ui.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/dashboard/dashboard_shell.dart';

void main() {
  testWidgets('feature page back action returns to the previous route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/sites',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Sites workspace')),
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home workspace')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(
            body: AppPage(
              title: 'Settings',
              subtitle: 'Workspace preferences',
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    router.push('/sites');
    await tester.pumpAndSettle();
    router.push('/settings');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Sites workspace'), findsOneWidget);
  });

  testWidgets('home page does not render a redundant back action', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: AppPage(
              title: 'Home',
              subtitle: 'Workspace overview',
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('system back from a shell screen returns to home', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        ShellRoute(
          builder: (context, state, child) => DashboardShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Center(
                child: Text('Home workspace'),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const Center(
                child: Text('Profile workspace'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_contractor),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile workspace'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Home workspace'), findsOneWidget);
  });

  testWidgets('floating AI destination fits in the mobile navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => DashboardShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Center(child: Text('Home workspace')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_contractor),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Studio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _contractor = AuthUser(
  id: 'user-1',
  email: 'contractor@siteseva.test',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  siteIds: [],
  blocked: false,
);

class _AuthenticatedController extends AuthController {
  _AuthenticatedController(AuthUser user) : super(_FakeAuthRepository()) {
    state = AsyncValue.data(user);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) => throw UnimplementedError();
}
