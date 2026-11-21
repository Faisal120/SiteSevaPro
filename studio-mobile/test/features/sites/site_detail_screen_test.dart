import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';
import 'package:siteseva/features/sites/models/site_records.dart';
import 'package:siteseva/features/sites/presentation/screens/site_detail_screen.dart';
import 'package:siteseva/features/sites/presentation/screens/sites_screen.dart';
import 'package:siteseva/features/sites/providers/sites_provider.dart';
import 'package:siteseva/features/sites/repository/site_repository.dart';

void main() {
  testWidgets('site detail screen renders the live project command center', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_user),
          ),
          siteRepositoryProvider.overrideWithValue(_FakeSiteRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SiteDetailScreen(siteId: 'site-1'),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Orchid Residence'), findsWidgets);
    expect(find.text('SITE COMMAND'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Project overview'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('site portfolio renders at the desktop breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_user),
          ),
          siteRepositoryProvider.overrideWithValue(_FakeSiteRepository()),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const SitesScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('LIVE PORTFOLIO'), findsOneWidget);
    expect(find.text('Orchid Residence'), findsOneWidget);
    expect(find.text('Project portfolio'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final _user = AuthUser(
  id: 'contractor-1',
  email: 'contractor@siteseva.test',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: const ['site-1'],
  blocked: false,
);

final _site = SiteDetail.fromJson({
  'id': 'site-1',
  'company_id': 'company-1',
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'budget': 8500000,
  'start_date': '2026-01-15',
  'end_date': '2026-12-20',
  'description': 'Premium residential construction.',
  'status': 'ACTIVE',
  'progress': 64,
  'floors': 3,
  'has_boring': true,
  'has_septic_tank': true,
  'has_soak_pit': true,
  'has_mumty': true,
  'supervisor_ids': ['supervisor-1'],
  'supervisor_names': ['Rohan Singh'],
  'client_ids': ['client-1'],
  'client_name': 'Kapoor Family',
});

class _FakeSiteRepository implements SiteRepository {
  @override
  Future<void> assignClient(String siteId, String userId) async {}

  @override
  Future<void> assignSupervisor(String siteId, String userId) async {}

  @override
  Future<SiteDetail> createSite(SiteMutation mutation) async => _site;

  @override
  Future<void> deleteSite(String siteId) async {}

  @override
  Future<List<SiteAttendanceDay>> fetchAttendance(String siteId) async => [];

  @override
  Future<List<SiteLabour>> fetchLabour(String siteId) async => [];

  @override
  Future<List<SiteMaterial>> fetchMaterials(String siteId) async => [];

  @override
  Future<List<SitePayment>> fetchPayments(String siteId) async => [];

  @override
  Future<List<SiteReport>> fetchReports(String siteId) async => [];

  @override
  Future<SiteDetail> fetchSite(String siteId) async => _site;

  @override
  Future<SiteCollection> fetchSites() async =>
      SiteCollection(sites: [_site.summary], fetchedAt: DateTime(2026, 8, 6));

  @override
  Future<List<SiteAssignee>> fetchTeam() async => const [];

  @override
  Future<SiteDetail> updateSite(String siteId, SiteMutation mutation) async =>
      _site;
}

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
