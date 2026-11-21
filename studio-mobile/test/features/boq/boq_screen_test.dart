import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/boq/models/boq_models.dart';
import 'package:siteseva/features/boq/presentation/screens/boq_detail_screen.dart';
import 'package:siteseva/features/boq/presentation/screens/boq_screen.dart';
import 'package:siteseva/features/boq/providers/boq_provider.dart';
import 'package:siteseva/features/boq/repository/boq_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets('desktop BOQ portfolio renders live cost intelligence', (
    tester,
  ) async {
    await _pumpPortfolio(tester, const Size(1440, 1000));

    expect(find.text('Bill of Quantities'), findsOneWidget);
    expect(find.text('Connected cost workflow'), findsOneWidget);
    expect(find.text('Estimate-linked'), findsOneWidget);
    expect(find.text('Vendor reference'), findsOneWidget);
    expect(find.text('Orchid Tender BOQ'), findsOneWidget);
    expect(find.text('INR 4.3 L'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile BOQ portfolio settles without responsive overflow', (
    tester,
  ) async {
    await _pumpPortfolio(tester, const Size(390, 844));

    expect(
      find.text('Turn measured scope into a controlled cost baseline.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Generate BOQ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('issued BOQ detail renders composition and itemized worksheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeBoqRepository(_studioData);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_contractor),
          ),
          boqRepositoryProvider.overrideWithValue(repository),
          boqStudioControllerProvider.overrideWith(
            (ref) => _LoadedBoqStudioController(_studioData, repository),
          ),
          boqDetailControllerProvider.overrideWith(
            (ref, boqId) =>
                _LoadedBoqDetailController(_document, repository, boqId),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const BoqDetailScreen(boqId: 'boq-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Issued quantity and rate worksheet'), findsOneWidget);
    expect(find.text('Cost composition'), findsOneWidget);
    expect(find.text('Source estimate'), findsOneWidget);
    expect(find.text('Rate validation directory'), findsOneWidget);
    expect(find.text('Itemized worksheet'), findsOneWidget);
    expect(find.text('PCC bed'), findsOneWidget);
    expect(find.text('TOTALS VERIFIED'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPortfolio(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FakeBoqRepository(_studioData);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(_contractor),
        ),
        boqRepositoryProvider.overrideWithValue(repository),
        boqStudioControllerProvider.overrideWith(
          (ref) => _LoadedBoqStudioController(_studioData, repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const BoqScreen()),
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

final _estimate = BoqEstimateSummary.fromJson({
  'id': 'estimate-1',
  'site_id': 'site-1',
  'name': 'Approved Premium Estimate',
  'builtup_sqft': 4650,
  'total': 8500000,
  'quality_band': 'PREMIUM',
  'created_at': '2026-08-05T09:00:00Z',
});

final _vendor = BoqVendorSummary.fromJson({
  'id': 'vendor-1',
  'name': 'Shree Buildmart',
  'contact': '9876543210',
  'gst': '06ABCDE1234F1Z5',
  'categories': ['Cement', 'Steel'],
});

final _document = BoqDocument.fromJson({
  'id': 'boq-1',
  'estimate_id': 'estimate-1',
  'site_id': 'site-1',
  'name': 'Orchid Tender BOQ',
  'builtup_sqft': 4650,
  'sections': [
    {
      'name': 'Foundation',
      'subtotal': 142000,
      'items': [
        {
          'desc': 'PCC bed',
          'unit': 'cum',
          'qty': 12,
          'rate': 6500,
          'amount': 78000,
        },
        {
          'desc': 'Earthwork excavation',
          'unit': 'cum',
          'qty': 200,
          'rate': 320,
          'amount': 64000,
        },
      ],
    },
    {
      'name': 'RCC Work',
      'subtotal': 291000,
      'items': [
        {
          'desc': 'Columns and beams',
          'unit': 'cum',
          'qty': 30,
          'rate': 9700,
          'amount': 291000,
        },
      ],
    },
  ],
  'total': 433000,
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
});

final _studioData = BoqStudioData(
  boqs: [_document],
  sites: [_site],
  estimates: [_estimate],
  vendors: [_vendor],
  fetchedAt: DateTime(2026, 8, 6),
);

class _LoadedBoqStudioController extends BoqStudioController {
  _LoadedBoqStudioController(BoqStudioData data, BoqRepository repository)
    : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _LoadedBoqDetailController extends BoqDetailController {
  _LoadedBoqDetailController(
    BoqDocument document,
    BoqRepository repository,
    String boqId,
  ) : super(repository: repository, boqId: boqId) {
    state = AsyncValue.data(document);
  }
}

class _FakeBoqRepository implements BoqRepository {
  const _FakeBoqRepository(this.data);
  final BoqStudioData data;

  @override
  Future<BoqDocument> fetchBoq(String boqId) async => _document;

  @override
  Future<BoqStudioData> fetchStudio() async => data;

  @override
  Future<BoqDocument> generate(BoqGenerationBrief brief) async => _document;
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
