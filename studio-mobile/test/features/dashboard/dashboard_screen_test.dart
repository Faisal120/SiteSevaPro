import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/dashboard/models/dashboard_data.dart';
import 'package:siteseva/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:siteseva/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:siteseva/features/dashboard/providers/dashboard_provider.dart';
import 'package:siteseva/features/dashboard/repository/dashboard_repository.dart';

void main() {
  testWidgets('contractor dashboard renders live contractor KPIs', (
    tester,
  ) async {
    await _pumpDashboard(tester, role: 'CONTRACTOR');

    expect(find.text('Financial command'), findsOneWidget);
    expect(find.text('LIVE FINANCIAL POSITION'), findsOneWidget);
    expect(find.text('COLLECTED'), findsWidgets);
    expect(find.text('TOTAL SPENT'), findsWidgets);
    expect(find.text('OUTSTANDING'), findsWidgets);
    expect(find.text('Current projects'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('LIVE PORTFOLIO'), findsOneWidget);
    expect(find.text('Portfolio intelligence'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('supervisor dashboard uses field KPIs and hides budget', (
    tester,
  ) async {
    await _pumpDashboard(tester, role: 'SUPERVISOR');

    expect(find.text('Assigned sites'), findsWidgets);
    expect(find.text('PRESENT TODAY'), findsOneWidget);
    expect(find.text('LABOUR TODAY'), findsNothing);
    expect(find.textContaining('\u20B9'), findsNothing);
    expect(find.text('Payments'), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('client dashboard renders project and payment views', (
    tester,
  ) async {
    await _pumpDashboard(tester, role: 'CLIENT');

    expect(find.text('My projects'), findsWidgets);
    expect(find.text('Payments'), findsWidgets);
    expect(find.text('Payment activity'), findsOneWidget);
    expect(find.text('Attendance'), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('campaign carousel auto-advances and exposes page controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = DashboardData.fromJson({
      'campaigns': [
        {
          'id': 'campaign-1',
          'title': 'Campaign one',
          'body': 'First production campaign.',
          'action_key': 'SITES',
        },
        {
          'id': 'campaign-2',
          'title': 'Campaign two',
          'body': 'Second production campaign.',
          'action_key': 'REPORTS',
        },
      ],
    });
    const user = AuthUser(
      id: 'user-1',
      email: 'contractor@siteseva.test',
      fullName: 'Site Contractor',
      role: 'CONTRACTOR',
      siteIds: [],
      blocked: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DashboardCampaignCarousel(user: user, data: data),
        ),
      ),
    );
    await tester.pump();
    final pageView = tester.widget<PageView>(
      find.byKey(const ValueKey('dashboard-campaign-carousel')),
    );
    expect(pageView.controller?.page, 0);
    expect(
      find.byKey(const ValueKey('dashboard-campaign-dot-1')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 700));

    expect(pageView.controller?.page, closeTo(1, .01));
    _expectNoFlutterException(tester);
    await tester.pumpWidget(const SizedBox());
  });
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
}

Future<void> _pumpDashboard(WidgetTester tester, {required String role}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final user = AuthUser(
    id: 'user-1',
    email: 'user@siteseva.test',
    fullName: 'Site User',
    role: role,
    companyName: 'Buildcraft Projects',
    siteIds: const ['site-1'],
    blocked: false,
  );
  final dashboard = DashboardData.fromJson({
    'company': {'id': 'company-1', 'name': 'Buildcraft Projects'},
    'stats': {
      'total_sites': 1,
      'active_sites': 1,
      'completed_sites': 0,
      'labours': 12,
      'today_labours': 9,
      'pending_tasks': 3,
      'completed_tasks': 7,
      'today_reports': 1,
    },
    'sites': [
      {
        'id': 'site-1',
        'name': 'Orchid Residence',
        'location': 'Gurugram',
        'status': 'ACTIVE',
        'progress': 52,
        'budget': 4800000,
        'end_date': '2026-12-20',
        'supervisor_names': ['Field Supervisor'],
      },
    ],
    'todayAttendance': [
      {'id': 'attendance-1', 'status': 'PRESENT', 'site_id': 'site-1'},
    ],
    'payments': [
      {
        'id': 'payment-1',
        'type': 'CLIENT_RECEIVED',
        'amount': 250000,
        'description': 'Milestone payment',
      },
    ],
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(user),
        ),
        dashboardControllerProvider.overrideWith(
          (ref) => _LoadedDashboardController(dashboard),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

class _AuthenticatedController extends AuthController {
  _AuthenticatedController(AuthUser user) : super(_FakeAuthRepository()) {
    state = AsyncValue.data(user);
  }
}

class _LoadedDashboardController extends DashboardController {
  _LoadedDashboardController(DashboardData data)
    : super(_FakeDashboardRepository(data)) {
    state = AsyncValue.data(data);
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository(this.data);

  final DashboardData data;

  @override
  Future<DashboardData> fetch() async => data;
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) {
    throw UnimplementedError();
  }
}
