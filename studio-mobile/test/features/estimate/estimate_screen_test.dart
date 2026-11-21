import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/estimate/models/estimate_models.dart';
import 'package:siteseva/features/estimate/presentation/screens/estimate_detail_screen.dart';
import 'package:siteseva/features/estimate/presentation/screens/estimate_screen.dart';
import 'package:siteseva/features/estimate/providers/estimate_provider.dart';
import 'package:siteseva/features/estimate/repository/estimate_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets('desktop estimate portfolio renders live feasibility data', (
    tester,
  ) async {
    await _pumpPortfolio(tester, const Size(1440, 1000));

    expect(find.text('Project Estimator'), findsOneWidget);
    expect(find.text('Connected feasibility workflow'), findsOneWidget);
    expect(find.text('Server cost mix'), findsOneWidget);
    expect(find.text('Material plan'), findsOneWidget);
    expect(find.text('Branding context'), findsOneWidget);
    expect(find.text('Orchid Premium Feasibility'), findsOneWidget);
    expect(find.text('INR 85 L'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    _expectNoFlutterException(tester);
  });

  testWidgets('mobile estimate portfolio settles without responsive overflow', (
    tester,
  ) async {
    await _pumpPortfolio(tester, const Size(390, 844));

    expect(
      find.text('Build budget confidence before mobilization.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Create estimate'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    _expectNoFlutterException(tester);
  });

  testWidgets('issued estimate detail renders costs and material assumptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeEstimateRepository(_studioData);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_contractor),
          ),
          estimateRepositoryProvider.overrideWithValue(repository),
          estimateStudioControllerProvider.overrideWith(
            (ref) => _LoadedEstimateStudioController(_studioData, repository),
          ),
          estimateDetailControllerProvider.overrideWith(
            (ref, estimateId) => _LoadedEstimateDetailController(
              _document,
              repository,
              estimateId,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const EstimateDetailScreen(estimateId: 'estimate-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Cost composition'), findsOneWidget);
    expect(find.text('Planning assumptions'), findsOneWidget);
    expect(find.text('Material quantity plan'), findsOneWidget);
    expect(find.text('Cement'), findsOneWidget);
    expect(find.text('Commercial summary'), findsOneWidget);
    expect(find.text('Document identity'), findsOneWidget);
    expect(find.text('Proposal controls'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    _expectNoFlutterException(tester);
  });
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
}

Future<void> _pumpPortfolio(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FakeEstimateRepository(_studioData);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(_contractor),
        ),
        estimateRepositoryProvider.overrideWithValue(repository),
        estimateStudioControllerProvider.overrideWith(
          (ref) => _LoadedEstimateStudioController(_studioData, repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const EstimateScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

const _contractor = AuthUser(
  id: 'contractor-1',
  email: 'contractor@siteseva.test',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: ['site-1'],
  blocked: false,
);

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

final _document = EstimateDocument.fromJson({
  'id': 'estimate-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'name': 'Orchid Premium Feasibility',
  'input': {
    'site_id': 'site-1',
    'name': 'Orchid Premium Feasibility',
    'plot_area_sqft': 2400,
    'floors': 2,
    'basement': true,
    'construction_type': 'RESIDENTIAL',
    'quality': 'PREMIUM',
    'budget': 8500000,
  },
  'builtup_sqft': 6840,
  'rate_per_sqft': 1242.69,
  'quality_band': 'PREMIUM',
  'type_factor': 1,
  'materials': {
    'cement_bags': 2900.16,
    'steel_kg': 30096,
    'sand_cft': 5814,
    'aggregate_cft': 4446,
    'bricks_pcs': 54720,
  },
  'material_cost': 5100000,
  'labour_cost': 2210000,
  'overhead': 1190000,
  'total': 8500000,
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
});

final _branding = EstimateBranding.fromJson({
  'company_name': 'Buildcraft Projects',
  'email': 'projects@buildcraft.test',
  'gst_number': '06ABCDE1234F1Z5',
  'signature': 'https://cdn.example.test/signature.png',
});

final _studioData = EstimateStudioData(
  estimates: [_document],
  sites: [_site],
  branding: _branding,
  fetchedAt: DateTime(2026, 8, 6),
);

class _LoadedEstimateStudioController extends EstimateStudioController {
  _LoadedEstimateStudioController(
    EstimateStudioData data,
    EstimateRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _LoadedEstimateDetailController extends EstimateDetailController {
  _LoadedEstimateDetailController(
    EstimateDocument document,
    EstimateRepository repository,
    String estimateId,
  ) : super(repository: repository, estimateId: estimateId) {
    state = AsyncValue.data(document);
  }
}

class _FakeEstimateRepository implements EstimateRepository {
  const _FakeEstimateRepository(this.data);
  final EstimateStudioData data;

  @override
  Future<EstimateDocument> create(EstimateBrief brief) async => _document;

  @override
  Future<EstimateDocument> fetchEstimate(String estimateId) async => _document;

  @override
  Future<EstimateStudioData> fetchStudio() async => data;
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
