import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/design_studio/models/design_models.dart';
import 'package:siteseva/features/design_studio/presentation/screens/design_studio_screen.dart';
import 'package:siteseva/features/design_studio/presentation/screens/design_viewer_screen.dart';
import 'package:siteseva/features/design_studio/providers/design_studio_provider.dart';
import 'package:siteseva/features/design_studio/repository/design_studio_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets(
    'contractor studio renders live credits and production workflow',
    (tester) async {
      await _pumpStudio(
        tester,
        role: 'CONTRACTOR',
        size: const Size(1440, 1000),
      );

      expect(find.text('AI Design Studio'), findsOneWidget);
      expect(find.text('86 credits'), findsOneWidget);
      expect(find.text('Production workflow'), findsOneWidget);
      expect(find.text('2D floor plans'), findsOneWidget);
      expect(find.text('Furnished 3D'), findsOneWidget);
      expect(find.text('Start floor plan'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('supervisor studio is responsive and strictly review-only', (
    tester,
  ) async {
    await _pumpStudio(tester, role: 'SUPERVISOR', size: const Size(390, 844));

    expect(
      find.text('Review the latest design set for your sites.'),
      findsOneWidget,
    );
    expect(find.text('Start floor plan'), findsNothing);
    expect(find.text('86 credits'), findsNothing);
    expect(find.byTooltip('Generate floor plan'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewer exposes real floor, export, and discipline controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeDesignRepository(_studioData);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedController(_user('CONTRACTOR')),
          ),
          designStudioRepositoryProvider.overrideWithValue(repository),
          designStudioControllerProvider.overrideWith(
            (ref) => _LoadedStudioController(_studioData, repository),
          ),
          designDetailControllerProvider.overrideWith(
            (ref, designId) =>
                _LoadedDesignDetailController(_design, repository, designId),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DesignViewerScreen(designId: 'design-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Design command center · Ready'), findsOneWidget);
    expect(find.text('Ground Floor'), findsOneWidget);
    expect(find.text('Share SVG'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);
    expect(find.text('Drawing disciplines'), findsOneWidget);
    expect(find.text('Electrical'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpStudio(
  WidgetTester tester, {
  required String role,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final data = role == 'CONTRACTOR'
      ? _studioData
      : DesignStudioData(
          sites: _studioData.sites,
          designs: _studioData.designs,
          transactions: const [],
          purchases: const [],
          fetchedAt: _studioData.fetchedAt,
        );
  final repository = _FakeDesignRepository(data);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(_user(role)),
        ),
        designStudioRepositoryProvider.overrideWithValue(repository),
        designStudioControllerProvider.overrideWith(
          (ref) => _LoadedStudioController(data, repository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const DesignStudioScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

AuthUser _user(String role) => AuthUser(
  id: 'user-1',
  email: 'user@siteseva.test',
  fullName: 'Aarav Mehta',
  role: role,
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: const ['site-1'],
  blocked: false,
);

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

final _design = DesignRecord.fromJson({
  'id': 'design-1',
  'site_id': 'site-1',
  'project_name': 'Orchid Residence',
  'design_type': '2D',
  'status': 'COMPLETED',
  'credits_used': 10,
  'created_at': '2026-08-06T09:00:00Z',
  'updated_at': '2026-08-06T09:02:00Z',
  'inputs': {
    'plot_width': 40,
    'plot_length': 60,
    'facing': 'North',
    'floors': 2,
    'variation': 0,
  },
  'outputs': {
    'svg': _svg,
    'layout': {
      'svg': _svg,
      'plot': {'width': 40, 'length': 60, 'facing': 'North'},
      'rooms': [
        {'name': 'Living', 'x': 0, 'y': 0, 'width': 15, 'height': 12},
      ],
    },
    'floor_plans': [
      {
        'floor_number': 1,
        'label': 'Ground Floor',
        'layout': {
          'svg': _svg,
          'plot': {'width': 40, 'length': 60, 'facing': 'North'},
          'rooms': [
            {'name': 'Living', 'x': 0, 'y': 0, 'width': 15, 'height': 12},
          ],
        },
      },
      {
        'floor_number': 2,
        'label': 'First Floor',
        'layout': {
          'svg': _svg,
          'plot': {'width': 40, 'length': 60, 'facing': 'North'},
          'rooms': [],
        },
      },
    ],
    'technical_drawings': {
      'ELECTRICAL': {
        'type': 'ELECTRICAL',
        'title': 'Electrical layout',
        'svg': _svg,
      },
    },
    'three_d': {
      '1': {'floor_number': 1, 'label': 'Furnished 3D', 'svg': _svg},
    },
  },
});

final _studioData = DesignStudioData(
  sites: [_site],
  designs: [_design],
  wallet: const DesignWallet(companyId: 'company-1', credits: 86),
  transactions: const [],
  purchaseConfig: const DesignPurchaseConfig(
    upiId: 'billing@siteseva',
    payeeName: 'SiteSeva Pro',
    packs: [DesignCreditPack(code: 'starter', credits: 50, amount: 199)],
  ),
  purchases: const [],
  fetchedAt: DateTime(2026, 8, 6),
);

const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 600">
  <rect width="400" height="600" fill="#f8fafc"/>
  <rect x="24" y="24" width="352" height="552" fill="none" stroke="#172033" stroke-width="8"/>
  <path d="M24 300h352M200 24v552" stroke="#172033" stroke-width="5"/>
</svg>
''';

class _LoadedStudioController extends DesignStudioController {
  _LoadedStudioController(
    DesignStudioData data,
    DesignStudioRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _LoadedDesignDetailController extends DesignDetailController {
  _LoadedDesignDetailController(
    DesignRecord design,
    DesignStudioRepository repository,
    String designId,
  ) : super(repository: repository, designId: designId) {
    state = AsyncValue.data(design);
  }
}

class _FakeDesignRepository implements DesignStudioRepository {
  const _FakeDesignRepository(this.data);

  final DesignStudioData data;

  @override
  Future<void> deleteDesign(String designId) async {}

  @override
  Future<Uint8List> downloadPdf(
    String designId,
    DesignDrawingType type,
    int floorNumber,
  ) async => Uint8List.fromList([1, 2, 3]);

  @override
  Future<DesignRecord> fetchDesign(String designId) async => _design;

  @override
  Future<DesignStudioData> fetchStudio() async => data;

  @override
  Future<DesignRecord> generate(DesignBrief brief) async => _design;

  @override
  Future<DesignRecord> generateTechnical(
    String designId,
    DesignDrawingType type,
  ) async => _design;

  @override
  Future<DesignRecord> generateThreeD(String designId, int floorNumber) async =>
      _design;

  @override
  Future<DesignPurchaseRequest> requestCredits({
    required String pack,
    required String utr,
    String? note,
  }) async => const DesignPurchaseRequest(
    id: 'purchase-1',
    pack: 'starter',
    credits: 50,
    amount: 199,
    utr: 'UTR-1',
    status: 'PENDING',
    createdAt: null,
  );
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
