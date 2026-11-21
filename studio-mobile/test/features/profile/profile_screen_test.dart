import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';
import 'package:siteseva/features/profile/models/profile_models.dart';
import 'package:siteseva/features/profile/presentation/screens/profile_company_screen.dart';
import 'package:siteseva/features/profile/presentation/widgets/profile_company_widgets.dart';
import 'package:siteseva/features/profile/providers/profile_company_provider.dart';
import 'package:siteseva/features/profile/repository/profile_company_repository.dart';

void main() {
  testWidgets('contractor can manage connected company branding', (tester) async {
    await _pump(
      tester,
      user: _contractor,
      child: const ProfileCompanyScreen(initialTab: ProfileCompanyTab.company),
    );

    expect(find.text('Company branding'), findsOneWidget);
    expect(find.text('Editable'), findsOneWidget);
    expect(find.text('Save branding'), findsOneWidget);
    expect(find.text('Change logo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supervisor receives a read-only company workspace', (tester) async {
    await _pump(
      tester,
      user: _supervisor,
      child: const ProfileCompanyScreen(initialTab: ProfileCompanyTab.company),
    );

    expect(find.text('Company branding'), findsOneWidget);
    expect(find.text('Read only'), findsOneWidget);
    expect(find.text('Save branding'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile hero remains within a narrow mobile card', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(
      tester,
      user: _contractor,
      child: const ProfileCompanyScreen(),
    );

    expect(find.text('Aarav Mehta'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AuthUser user,
  required Widget child,
}) async {
  final data = ProfileCompanyData.fromResponses(
    userPayload: user.toJson(),
    brandingPayload: const {
      'company_name': 'Buildcraft Projects',
      'logo_url': 'https://cdn.example/logo.png',
      'email': 'office@buildcraft.example',
      'phone': '+91 99999 00000',
      'address': 'Sector 57, Gurugram',
      'primary_color': '#2563EB',
      'secondary_color': '#0A0E17',
      'accent_color': '#4F8CFF',
      'font': 'Sora',
    },
  );
  final repository = _FakeProfileRepository(data);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedController(user),
        ),
        profileCompanyRepositoryProvider.overrideWithValue(repository),
        profileCompanyControllerProvider.overrideWith(
          (ref) => _LoadedProfileController(data, repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

const _contractor = AuthUser(
  id: 'contractor-1',
  email: 'contractor@buildcraft.example',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  plan: 'PRO',
  siteIds: ['site-1'],
  blocked: false,
);

const _supervisor = AuthUser(
  id: 'supervisor-1',
  email: 'supervisor@buildcraft.example',
  fullName: 'Rohit Singh',
  role: 'SUPERVISOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: ['site-1'],
  blocked: false,
);

class _LoadedProfileController extends ProfileCompanyController {
  _LoadedProfileController(
    ProfileCompanyData data,
    ProfileCompanyRepository repository,
  ) : super(repository) {
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

class _FakeProfileRepository implements ProfileCompanyRepository {
  _FakeProfileRepository(this.data);

  final ProfileCompanyData data;

  @override
  Future<ProfileCompanyData> fetchWorkspace() async => data;

  @override
  Future<ProfileCompanyData> saveBranding(BrandingUpdate input) async => data;

  @override
  Future<ProfileCompanyData> uploadLogo({
    required Uint8List bytes,
    required String filename,
  }) async => data;
}
