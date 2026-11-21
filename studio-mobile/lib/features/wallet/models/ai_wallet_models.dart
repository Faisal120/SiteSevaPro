import '../../auth/models/auth_user.dart';

class AiCreditWallet {
  const AiCreditWallet({required this.companyId, required this.credits});

  factory AiCreditWallet.fromJson(Map<String, dynamic> json) => AiCreditWallet(
    companyId: '${json['company_id'] ?? ''}',
    credits: _int(json['credits']),
  );

  final String companyId;
  final int credits;
}

class AiCreditTransaction {
  const AiCreditTransaction({
    required this.id,
    required this.type,
    required this.credits,
    required this.description,
    required this.createdAt,
  });

  factory AiCreditTransaction.fromJson(Map<String, dynamic> json) =>
      AiCreditTransaction(
        id: '${json['id'] ?? ''}',
        type: '${json['type'] ?? ''}',
        credits: _int(json['credits']),
        description: '${json['description'] ?? 'AI design credits'}',
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String type;
  final int credits;
  final String description;
  final DateTime? createdAt;

  bool get isCredit => credits > 0;
}

class AiCreditPack {
  const AiCreditPack({
    required this.code,
    required this.credits,
    required this.amount,
  });

  final String code;
  final int credits;
  final int amount;
}

class AiCreditPurchaseConfig {
  const AiCreditPurchaseConfig({
    required this.upiId,
    required this.payeeName,
    required this.packs,
  });

  factory AiCreditPurchaseConfig.fromJson(Map<String, dynamic> json) {
    final packs = <AiCreditPack>[];
    _map(json['packs']).forEach((code, value) {
      final item = _map(value);
      packs.add(AiCreditPack(
        code: code,
        credits: _int(item['credits']),
        amount: _int(item['amount']),
      ));
    });
    return AiCreditPurchaseConfig(
      upiId: '${json['upi_id'] ?? ''}',
      payeeName: '${json['payee_name'] ?? 'SiteSeva Pro'}',
      packs: packs,
    );
  }

  final String upiId;
  final String payeeName;
  final List<AiCreditPack> packs;
}

class AiCreditPurchaseRequest {
  const AiCreditPurchaseRequest({
    required this.id,
    required this.pack,
    required this.credits,
    required this.amount,
    required this.utr,
    required this.status,
    required this.createdAt,
  });

  factory AiCreditPurchaseRequest.fromJson(Map<String, dynamic> json) =>
      AiCreditPurchaseRequest(
        id: '${json['id'] ?? ''}',
        pack: '${json['pack'] ?? ''}',
        credits: _int(json['credits']),
        amount: _int(json['amount']),
        utr: '${json['utr'] ?? ''}',
        status: '${json['status'] ?? 'PENDING'}',
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String pack;
  final int credits;
  final int amount;
  final String utr;
  final String status;
  final DateTime? createdAt;

  bool get isPending => status.toUpperCase() == 'PENDING';
}

class AiWalletData {
  const AiWalletData({
    required this.user,
    required this.transactions,
    required this.purchases,
    required this.fetchedAt,
    this.wallet,
    this.purchaseConfig,
    this.isOffline = false,
    this.isRestricted = false,
    this.apiAvailable = true,
    this.message,
  });

  factory AiWalletData.restricted(AuthUser user) => AiWalletData(
    user: user,
    transactions: const [],
    purchases: const [],
    fetchedAt: DateTime.now(),
    isRestricted: true,
    message: 'AI credits are managed by the contractor for this workspace.',
  );

  final AuthUser user;
  final AiCreditWallet? wallet;
  final List<AiCreditTransaction> transactions;
  final AiCreditPurchaseConfig? purchaseConfig;
  final List<AiCreditPurchaseRequest> purchases;
  final DateTime fetchedAt;
  final bool isOffline;
  final bool isRestricted;
  final bool apiAvailable;
  final String? message;

  bool get canManage => user.isContractor || user.isSuperAdmin;
}

class AiCreditPurchaseInput {
  const AiCreditPurchaseInput({
    required this.pack,
    required this.utr,
    this.note,
  });

  final String pack;
  final String utr;
  final String? note;

  String? get validationMessage {
    if (pack.trim().isEmpty) return 'Choose a credit pack.';
    if (utr.trim().length < 4) return 'Enter the UPI transaction reference.';
    return null;
  }

  Map<String, dynamic> toJson() => {
    'pack': pack.trim(),
    'utr': utr.trim(),
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  };
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, item) => MapEntry('$key', item))
    : <String, dynamic>{};

List<Map<String, dynamic>> maps(Object? value) => value is List
    ? value.whereType<Map>().map(_map).toList(growable: false)
    : const [];

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();
