import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/wallet/models/ai_wallet_models.dart';

void main() {
  test('purchase configuration only parses backend-supplied packs', () {
    final config = AiCreditPurchaseConfig.fromJson({
      'upi_id': 'siteseva@upi',
      'payee_name': 'SiteSeva Pro',
      'packs': {
        'PRO_50': {'credits': 50, 'amount': 1999},
      },
    });

    expect(config.upiId, 'siteseva@upi');
    expect(config.packs, hasLength(1));
    expect(config.packs.single.code, 'PRO_50');
    expect(config.packs.single.credits, 50);
  });

  test('supervisor sees a restricted wallet rather than a fake balance', () {
    const supervisor = AuthUser(
      id: 'supervisor-1',
      email: 'supervisor@siteseva.test',
      fullName: 'Site Supervisor',
      role: 'SUPERVISOR',
      siteIds: [],
      blocked: false,
    );

    final data = AiWalletData.restricted(supervisor);

    expect(data.isRestricted, isTrue);
    expect(data.wallet, isNull);
    expect(data.message, contains('contractor'));
  });

  test('purchase input validates UTR before the network request', () {
    const invalid = AiCreditPurchaseInput(pack: 'PRO_50', utr: '12');
    const valid = AiCreditPurchaseInput(pack: 'PRO_50', utr: 'UPI1234');

    expect(invalid.validationMessage, isNotNull);
    expect(valid.validationMessage, isNull);
  });
}
