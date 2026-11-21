import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/materials/models/material_models.dart';
import 'package:siteseva/features/materials/presentation/screens/material_detail_screen.dart';
import 'package:siteseva/features/materials/presentation/screens/materials_screen.dart';
import 'package:siteseva/features/materials/providers/materials_provider.dart';
import 'package:siteseva/features/materials/repository/materials_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets('desktop stock portfolio renders live inventory intelligence', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      data: _studioData,
      child: const MaterialsScreen(),
    );

    expect(find.text('Materials & Stock'), findsOneWidget);
    expect(find.text('Connected stock workflow'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Movements'), findsOneWidget);
    expect(find.text('Vendors'), findsOneWidget);
    expect(find.text('OPC 53 Grade Cement'), findsWidgets);
    expect(find.text('Record movement'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('mobile inventory settles without responsive overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _contractor,
      data: _studioData,
      child: const MaterialsScreen(),
    );

    expect(find.text('Materials & Stock'), findsOneWidget);
    expect(find.byTooltip('Add material'), findsOneWidget);
    expect(find.text('LIVE SITE INVENTORY'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('movement workspace renders server receipt history', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      data: _studioData.copyWith(workspace: MaterialsWorkspace.movements),
      child: const MaterialsScreen(),
    );

    expect(
      find.text('Stock receipt  |  Orchid Residence  |  Shree Cement Supply'),
      findsOneWidget,
    );
    expect(find.text('+50 bags'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('supervisor stock UI excludes contractor vendor controls', (
    tester,
  ) async {
    final supervisorData = MaterialsStudioData(
      materials: _studioData.materials,
      movements: _studioData.movements,
      vendors: const [],
      sites: _studioData.sites,
      fetchedAt: _studioData.fetchedAt,
      canManageVendors: false,
    );
    await _pump(
      tester,
      size: const Size(390, 844),
      user: _supervisor,
      data: supervisorData,
      child: const MaterialsScreen(),
    );

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Movements'), findsOneWidget);
    expect(find.text('Vendors'), findsNothing);
    expect(find.text('Add vendor'), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('material detail renders stock controls and ledger', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      user: _contractor,
      data: _studioData,
      child: const MaterialDetailScreen(materialId: 'material-1'),
    );

    expect(find.text('Material Detail'), findsOneWidget);
    expect(find.text('OPC 53 Grade Cement'), findsWidgets);
    expect(find.text('Stock control'), findsOneWidget);
    expect(find.text('Record identity'), findsOneWidget);
    expect(find.text('Catalogue edits unavailable'), findsOneWidget);
    expect(find.text('Movement ledger'), findsOneWidget);
    _expectNoFlutterException(tester);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required AuthUser user,
  required MaterialsStudioData data,
  required Widget child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(user),
        ),
        materialsRepositoryProvider.overrideWithValue(_repository),
        materialsStudioControllerProvider.overrideWith(
          (ref) => _LoadedMaterialsController(data, _repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 900));
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
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

const _supervisor = AuthUser(
  id: 'supervisor-1',
  email: 'supervisor@siteseva.test',
  fullName: 'Priya Sharma',
  role: 'SUPERVISOR',
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

final _material = MaterialItem.fromJson({
  'id': 'material-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'name': 'OPC 53 Grade Cement',
  'category': 'Cement',
  'unit': 'bags',
  'stock': 84,
  'low_stock_threshold': 10,
  'rate': 550,
  'created_at': '2026-08-01T08:00:00Z',
});

final _movement = MaterialMovement.fromJson({
  'id': 'movement-1',
  'company_id': 'company-1',
  'material_id': 'material-1',
  'site_id': 'site-1',
  'type': 'INWARD',
  'quantity': 50,
  'rate': 565,
  'vendor': 'Shree Cement Supply',
  'note': 'Gate receipt GR-108',
  'created_at': '2026-08-06T09:30:00Z',
});

final _vendor = MaterialVendor.fromJson({
  'id': 'vendor-1',
  'company_id': 'company-1',
  'name': 'Shree Cement Supply',
  'contact': '9876543210',
  'gst': '06ABCDE1234F1Z5',
  'payment_terms': 'Net 30 days',
  'categories': ['Cement'],
});

final _studioData = MaterialsStudioData(
  materials: [_material],
  movements: [_movement],
  vendors: [_vendor],
  sites: [_site],
  fetchedAt: DateTime(2026, 8, 6, 12),
  canManageVendors: true,
);

const _repository = _FakeMaterialsRepository();

class _LoadedMaterialsController extends MaterialsStudioController {
  _LoadedMaterialsController(
    MaterialsStudioData data,
    MaterialsRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _FakeMaterialsRepository implements MaterialsRepository {
  const _FakeMaterialsRepository();

  @override
  Future<MaterialItem> createMaterial(MaterialCreationBrief brief) async =>
      _material;

  @override
  Future<MaterialMovement> createMovement(MaterialMovementBrief brief) async =>
      _movement;

  @override
  Future<MaterialVendor> createVendor(MaterialVendorBrief brief) async =>
      _vendor;

  @override
  Future<void> deleteVendor(String vendorId) async {}

  @override
  Future<MaterialsStudioData> fetchStudio() async => _studioData;
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
