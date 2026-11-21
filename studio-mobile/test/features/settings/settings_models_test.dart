import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/settings/models/settings_models.dart';

void main() {
  const contractor = AuthUser(
    id: 'contractor-1',
    email: 'contractor@siteseva.test',
    fullName: 'Aarav Mehta',
    role: 'CONTRACTOR',
    plan: 'PRO',
    siteIds: [],
    blocked: false,
  );

  test('subscription snapshot uses backend fields and account plan fallback', () {
    final data = SettingsWorkspaceData.fromResponses(
      userPayload: contractor.toJson(),
      subscriptionPayload: {
        'status': 'ACTIVE',
        'renews_at': '2026-10-01T00:00:00Z',
        'ai_credits_remaining': 120,
      },
    );

    expect(data.subscription.plan, 'PRO');
    expect(data.subscription.status, 'ACTIVE');
    expect(data.subscription.aiCreditsRemaining, 120);
    expect(data.permissions.canManageSubscription, isTrue);
  });

  test('unavailable subscription does not manufacture subscription details', () {
    final data = SettingsWorkspaceData.offline(contractor);

    expect(data.subscription.apiAvailable, isFalse);
    expect(data.subscription.aiCreditsRemaining, isNull);
    expect(data.subscription.apiMessage, contains('could not be reached'));
  });
}
