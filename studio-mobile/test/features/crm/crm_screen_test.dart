import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/crm/models/crm_models.dart';
import 'package:siteseva/features/crm/presentation/screens/crm_screen.dart';
import 'package:siteseva/features/crm/providers/crm_provider.dart';
import 'package:siteseva/features/crm/repository/crm_repository.dart';

void main() {
  testWidgets('mobile client sees an honest unavailable read-only CRM state', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _client,
      data: CrmWorkspaceData.unavailable(
        fetchedAt: DateTime(2026, 8, 8),
      ),
    );

    expect(find.text('CRM'), findsOneWidget);
    expect(find.text('CRM service not connected'), findsOneWidget);
    expect(find.text('Awaiting CRM API'), findsOneWidget);
    expect(find.text('Create record'), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contractor sees live records and can access CRM creation', (
    tester,
  ) async {
    final data = CrmWorkspaceData.fromJson({
      'metrics': {'leads': 1, 'pipeline_value': 450000},
      'leads': [
        {
          'id': 'lead-1',
          'name': 'Neha Sharma',
          'company': 'Northstar Homes',
          'status': 'QUALIFIED',
        },
      ],
    });
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      data: data,
    );

    expect(find.text('Neha Sharma'), findsOneWidget);
    expect(find.text('Northstar Homes'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Create record'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required AuthUser user,
  required CrmWorkspaceData data,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FakeCrmRepository(data);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(user),
        ),
        crmRepositoryProvider.overrideWithValue(repository),
        crmControllerProvider.overrideWith(
          (ref) => _LoadedCrmController(data, repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const CrmScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

const _contractor = AuthUser(
  id: 'contractor-1',
  email: 'contractor@siteseva.test',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  siteIds: ['site-1'],
  blocked: false,
);

const _client = AuthUser(
  id: 'client-1',
  email: 'client@siteseva.test',
  fullName: 'Neha Sharma',
  role: 'CLIENT',
  siteIds: ['site-1'],
  blocked: false,
);

class _LoadedCrmController extends CrmController {
  _LoadedCrmController(CrmWorkspaceData data, CrmRepository repository)
    : super(repository) {
    state = AsyncValue.data(data);
  }
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
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) => throw UnimplementedError();
}

class _FakeCrmRepository implements CrmRepository {
  _FakeCrmRepository(this.data);

  final CrmWorkspaceData data;

  @override
  Future<CrmWorkspaceData> fetchWorkspace() async => data;

  @override
  Future<void> createActivity(CrmActivityInput input) async {}

  @override
  Future<void> createContact(CrmContactInput input) async {}

  @override
  Future<void> createLead(CrmLeadInput input) async {}

  @override
  Future<void> createQuotation(CrmQuotationInput input) async {}

  @override
  Future<void> completeActivity(String id) async {}
}
