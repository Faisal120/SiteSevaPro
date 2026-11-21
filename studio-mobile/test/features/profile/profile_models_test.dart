import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/profile/models/profile_models.dart';

void main() {
  const user = AuthUser(
    id: 'user-1',
    email: 'contractor@example.com',
    fullName: 'Aarav Mehta',
    role: 'CONTRACTOR',
    companyId: 'company-1',
    companyName: 'Buildcraft Projects',
    plan: 'PRO',
    siteIds: ['site-1'],
    blocked: false,
  );

  group('ProfileCompanyData', () {
    test('parses live user and branding values without losing fallbacks', () {
      final data = ProfileCompanyData.fromResponses(
        userPayload: user.toJson(),
        brandingPayload: {
          'company_name': 'Buildcraft Projects',
          'logo_url': 'https://cdn.example/logo.png',
          'email': 'office@example.com',
          'gst_number': 'GST-123',
          'city': 'Gurugram',
          'state': 'Haryana',
        },
      );

      expect(data.user.email, 'contractor@example.com');
      expect(data.company.name, 'Buildcraft Projects');
      expect(data.company.location, 'Gurugram, Haryana');
      expect(data.branding.logoUrl, 'https://cdn.example/logo.png');
      expect(data.company.gstNumber, 'GST-123');
      expect(data.permissions.canEditBranding, isTrue);
    });

    test('keeps unavailable subscription values honest', () {
      final data = ProfileCompanyData.unavailable(user: user);

      expect(data.apiAvailable, isFalse);
      expect(data.user.plan, 'PRO');
      expect(data.branding.logoUrl, isNull);
      expect(data.apiMessage, contains('not available'));
    });

    test('restricts branding writes to contractors and admins', () {
      final supervisor = AuthUser(
        id: 'supervisor-1',
        email: 'supervisor@example.com',
        fullName: 'Supervisor',
        role: 'SUPERVISOR',
        siteIds: const ['site-1'],
        blocked: false,
      );
      final client = AuthUser(
        id: 'client-1',
        email: 'client@example.com',
        fullName: 'Client',
        role: 'CLIENT',
        siteIds: const ['site-1'],
        blocked: false,
      );

      expect(ProfilePermissions.forUser(user).canEditBranding, isTrue);
      expect(ProfilePermissions.forUser(supervisor).isReadOnly, isTrue);
      expect(ProfilePermissions.forUser(supervisor).canEditBranding, isFalse);
      expect(ProfilePermissions.forUser(client).canUploadLogo, isFalse);
    });
  });
}
