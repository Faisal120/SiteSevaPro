import '../../sites/models/site_models.dart';

enum LabourLedgerType {
  earning('EARNING', 'Earning'),
  advance('ADVANCE', 'Advance'),
  payment('PAYMENT', 'Payment'),
  bonus('BONUS', 'Bonus'),
  deduction('DEDUCTION', 'Deduction'),
  unknown('UNKNOWN', 'Activity');

  const LabourLedgerType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static LabourLedgerType fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return LabourLedgerType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => LabourLedgerType.unknown,
    );
  }
}

enum LabourPaymentMode {
  cash('CASH', 'Cash'),
  upi('UPI', 'UPI'),
  bank('BANK', 'Bank transfer'),
  cheque('CHEQUE', 'Cheque');

  const LabourPaymentMode(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class WorkforceMember {
  const WorkforceMember({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.trade,
    required this.dailyWage,
    required this.siteId,
    required this.active,
    this.mobile,
    this.aadhaar,
    this.address,
    this.createdBy,
    this.createdAt,
  });

  factory WorkforceMember.fromJson(Map<String, dynamic> json) =>
      WorkforceMember(
        id: '${json['id'] ?? ''}',
        companyId: '${json['company_id'] ?? ''}',
        fullName: '${json['full_name'] ?? json['name'] ?? ''}'.trim(),
        mobile: _nullableString(json['mobile']),
        trade: '${json['trade'] ?? ''}'.trim(),
        dailyWage: _double(json['daily_wage']),
        siteId: '${json['site_id'] ?? ''}',
        aadhaar: _nullableString(json['aadhaar']),
        address: _nullableString(json['address']),
        createdBy: _nullableString(json['created_by']),
        createdAt: _date(json['created_at']),
        active: json['active'] != false,
      );

  final String id;
  final String companyId;
  final String fullName;
  final String? mobile;
  final String trade;
  final double dailyWage;
  final String siteId;
  final String? aadhaar;
  final String? address;
  final String? createdBy;
  final DateTime? createdAt;
  final bool active;

  String get displayName => fullName.isEmpty ? 'Workforce member' : fullName;
  String get displayTrade => trade.isEmpty ? 'Trade not specified' : trade;
  String get initials {
    final words = displayName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList(growable: false);
    return words.map((word) => word[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'full_name': fullName,
    'mobile': mobile,
    'trade': trade,
    'daily_wage': dailyWage,
    'site_id': siteId,
    'aadhaar': aadhaar,
    'address': address,
    'created_by': createdBy,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'active': active,
  };
}

class WorkforceCreationBrief {
  const WorkforceCreationBrief({
    required this.fullName,
    required this.mobile,
    required this.trade,
    required this.dailyWage,
    required this.siteId,
    required this.aadhaar,
    required this.address,
  });

  factory WorkforceCreationBrief.initial() => const WorkforceCreationBrief(
    fullName: '',
    mobile: '',
    trade: '',
    dailyWage: 0,
    siteId: '',
    aadhaar: '',
    address: '',
  );

  final String fullName;
  final String mobile;
  final String trade;
  final double dailyWage;
  final String siteId;
  final String aadhaar;
  final String address;

  String? get validationMessage {
    if (fullName.trim().length < 2) return 'Enter the worker full name.';
    if (trade.trim().isEmpty) return 'Enter the worker trade.';
    if (dailyWage <= 0) return 'Enter a valid daily wage.';
    if (siteId.isEmpty) return 'Choose the assigned project site.';
    if (mobile.isNotEmpty && mobile.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Enter a valid mobile number or leave it blank.';
    }
    if (aadhaar.isNotEmpty &&
        aadhaar.replaceAll(RegExp(r'\D'), '').length != 12) {
      return 'Aadhaar must contain 12 digits or remain blank.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'full_name': fullName.trim(),
    'mobile': _nullableString(mobile),
    'trade': trade.trim(),
    'daily_wage': dailyWage,
    'site_id': siteId,
    'aadhaar': _nullableString(aadhaar),
    'address': _nullableString(address),
  };

  WorkforceCreationBrief copyWith({
    String? fullName,
    String? mobile,
    String? trade,
    double? dailyWage,
    String? siteId,
    String? aadhaar,
    String? address,
  }) => WorkforceCreationBrief(
    fullName: fullName ?? this.fullName,
    mobile: mobile ?? this.mobile,
    trade: trade ?? this.trade,
    dailyWage: dailyWage ?? this.dailyWage,
    siteId: siteId ?? this.siteId,
    aadhaar: aadhaar ?? this.aadhaar,
    address: address ?? this.address,
  );
}

class LabourWallet {
  const LabourWallet({
    required this.labourId,
    required this.earned,
    required this.advance,
    required this.paid,
    required this.bonus,
    required this.deduction,
    required this.balance,
    this.id,
    this.companyId,
    this.siteId,
    this.updatedAt,
  });

  factory LabourWallet.fromJson(Map<String, dynamic> json) => LabourWallet(
    id: _nullableString(json['id']),
    companyId: _nullableString(json['company_id']),
    labourId: '${json['labour_id'] ?? ''}',
    siteId: _nullableString(json['site_id']),
    earned: _double(json['earned'] ?? json['total_earned']),
    advance: _double(json['advance']),
    paid: _double(json['paid'] ?? json['total_paid']),
    bonus: _double(json['bonus']),
    deduction: _double(json['deduction']),
    balance: _double(json['balance']),
    updatedAt: _date(json['updated_at']),
  );

  factory LabourWallet.empty(String labourId) => LabourWallet(
    labourId: labourId,
    earned: 0,
    advance: 0,
    paid: 0,
    bonus: 0,
    deduction: 0,
    balance: 0,
  );

  final String? id;
  final String? companyId;
  final String labourId;
  final String? siteId;
  final double earned;
  final double advance;
  final double paid;
  final double bonus;
  final double deduction;
  final double balance;
  final DateTime? updatedAt;

  double get totalOutflow => advance + paid + deduction;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'labour_id': labourId,
    'site_id': siteId,
    'earned': earned,
    'advance': advance,
    'paid': paid,
    'bonus': bonus,
    'deduction': deduction,
    'balance': balance,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };
}

class LabourLedgerEntry {
  const LabourLedgerEntry({
    required this.id,
    required this.labourId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.companyId,
    this.siteId,
    this.note,
    this.paymentMode,
    this.refType,
    this.refId,
  });

  factory LabourLedgerEntry.fromJson(Map<String, dynamic> json) =>
      LabourLedgerEntry(
        id: '${json['id'] ?? ''}',
        companyId: _nullableString(json['company_id']),
        labourId: '${json['labour_id'] ?? ''}',
        siteId: _nullableString(json['site_id']),
        type: LabourLedgerType.fromApi(json['type']),
        amount: _double(json['amount']),
        note: _nullableString(json['note']),
        paymentMode: _nullableString(json['payment_mode']),
        date: '${json['date'] ?? ''}',
        refType: _nullableString(json['ref_type']),
        refId: _nullableString(json['ref_id']),
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String? companyId;
  final String labourId;
  final String? siteId;
  final LabourLedgerType type;
  final double amount;
  final String? note;
  final String? paymentMode;
  final String date;
  final String? refType;
  final String? refId;
  final DateTime? createdAt;

  bool get addsToBalance =>
      type == LabourLedgerType.earning || type == LabourLedgerType.bonus;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'labour_id': labourId,
    'site_id': siteId,
    'type': type.apiValue,
    'amount': amount,
    'note': note,
    'payment_mode': paymentMode,
    'date': date,
    'ref_type': refType,
    'ref_id': refId,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class WorkforceDetail {
  const WorkforceDetail({
    required this.member,
    required this.wallet,
    required this.ledger,
    required this.fetchedAt,
    this.isOffline = false,
  });

  factory WorkforceDetail.fromJson(
    Map<String, dynamic> json, {
    required DateTime fetchedAt,
    bool isOffline = false,
  }) {
    final member = WorkforceMember.fromJson(_map(json['labour']));
    final walletPayload = _map(json['wallet']);
    return WorkforceDetail(
      member: member,
      wallet: walletPayload.isEmpty
          ? LabourWallet.empty(member.id)
          : LabourWallet.fromJson(walletPayload),
      ledger: _maps(
        json['ledger'],
      ).map(LabourLedgerEntry.fromJson).toList(growable: false),
      fetchedAt: fetchedAt,
      isOffline: isOffline,
    );
  }

  final WorkforceMember member;
  final LabourWallet wallet;
  final List<LabourLedgerEntry> ledger;
  final DateTime fetchedAt;
  final bool isOffline;

  double get ledgerEarnings => ledger
      .where((entry) => entry.addsToBalance)
      .fold(0, (sum, entry) => sum + entry.amount);
}

class WorkforceWalletRow {
  const WorkforceWalletRow({required this.member, required this.wallet});

  factory WorkforceWalletRow.fromJson(Map<String, dynamic> json) {
    final member = WorkforceMember.fromJson(json);
    final walletPayload = _map(json['wallet']);
    return WorkforceWalletRow(
      member: member,
      wallet: walletPayload.isEmpty
          ? LabourWallet.empty(member.id)
          : LabourWallet.fromJson({'labour_id': member.id, ...walletPayload}),
    );
  }

  final WorkforceMember member;
  final LabourWallet wallet;
}

class WorkforceWalletSummary {
  const WorkforceWalletSummary({
    required this.totalEarned,
    required this.totalPaid,
    required this.totalBalance,
    required this.rows,
  });

  factory WorkforceWalletSummary.fromJson(Map<String, dynamic> json) =>
      WorkforceWalletSummary(
        totalEarned: _double(json['total_earned']),
        totalPaid: _double(json['total_paid']),
        totalBalance: _double(json['total_balance']),
        rows: _maps(
          json['rows'],
        ).map(WorkforceWalletRow.fromJson).toList(growable: false),
      );

  factory WorkforceWalletSummary.empty() => const WorkforceWalletSummary(
    totalEarned: 0,
    totalPaid: 0,
    totalBalance: 0,
    rows: [],
  );

  final double totalEarned;
  final double totalPaid;
  final double totalBalance;
  final List<WorkforceWalletRow> rows;

  LabourWallet walletFor(String labourId) =>
      rows
          .where((row) => row.member.id == labourId)
          .map((row) => row.wallet)
          .firstOrNull ??
      LabourWallet.empty(labourId);
}

class WorkforceStudioData {
  const WorkforceStudioData({
    required this.members,
    required this.sites,
    required this.walletSummary,
    required this.fetchedAt,
    this.isOffline = false,
    this.query = '',
    this.siteFilter,
  });

  final List<WorkforceMember> members;
  final List<SiteSummary> sites;
  final WorkforceWalletSummary walletSummary;
  final DateTime fetchedAt;
  final bool isOffline;
  final String query;
  final String? siteFilter;

  List<WorkforceMember> get visibleMembers {
    final normalized = query.trim().toLowerCase();
    final terms = normalized
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    return members
        .where((member) {
          if (siteFilter != null && member.siteId != siteFilter) return false;
          if (terms.isEmpty) return true;
          final site = siteFor(member.siteId);
          final searchable =
              '${member.fullName} ${member.trade} ${member.mobile ?? ''} '
                      '${site?.name ?? ''} ${site?.location ?? ''}'
                  .toLowerCase();
          return terms.every(searchable.contains);
        })
        .toList(growable: false);
  }

  int get activeCount => members.where((member) => member.active).length;
  double get dailyWageExposure => members
      .where((member) => member.active)
      .fold(0, (sum, member) => sum + member.dailyWage);
  int get tradeCount => members
      .map((member) => member.trade.trim().toLowerCase())
      .where((trade) => trade.isNotEmpty)
      .toSet()
      .length;

  SiteSummary? siteFor(String siteId) =>
      sites.where((site) => site.id == siteId).firstOrNull;

  WorkforceStudioData copyWith({
    String? query,
    String? siteFilter,
    bool clearSite = false,
  }) => WorkforceStudioData(
    members: members,
    sites: sites,
    walletSummary: walletSummary,
    fetchedAt: fetchedAt,
    isOffline: isOffline,
    query: query ?? this.query,
    siteFilter: clearSite ? null : siteFilter ?? this.siteFilter,
  );
}

class WalletSettlementBrief {
  const WalletSettlementBrief({
    required this.labourId,
    required this.amount,
    required this.paymentMode,
    required this.remarks,
  });

  factory WalletSettlementBrief.initial(String labourId) =>
      WalletSettlementBrief(
        labourId: labourId,
        amount: 0,
        paymentMode: LabourPaymentMode.upi,
        remarks: '',
      );

  final String labourId;
  final double amount;
  final LabourPaymentMode paymentMode;
  final String remarks;

  String? get validationMessage {
    if (labourId.isEmpty) return 'Workforce member is unavailable.';
    if (amount <= 0) return 'Enter a settlement amount greater than zero.';
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'labour_id': labourId,
    'amount': amount,
    'payment_mode': paymentMode.apiValue,
    'remarks': _nullableString(remarks),
  };

  WalletSettlementBrief copyWith({
    double? amount,
    LabourPaymentMode? paymentMode,
    String? remarks,
  }) => WalletSettlementBrief(
    labourId: labourId,
    amount: amount ?? this.amount,
    paymentMode: paymentMode ?? this.paymentMode,
    remarks: remarks ?? this.remarks,
  );
}

class PayrollRecord {
  const PayrollRecord({
    required this.id,
    required this.labourId,
    required this.labourName,
    required this.month,
    required this.earned,
    required this.advance,
    required this.paid,
    required this.bonus,
    required this.deduction,
    required this.balance,
    this.companyId,
    this.generatedAt,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) => PayrollRecord(
    id: '${json['id'] ?? ''}',
    companyId: _nullableString(json['company_id']),
    labourId: '${json['labour_id'] ?? ''}',
    labourName: '${json['labour_name'] ?? 'Workforce member'}'.trim(),
    month: '${json['month'] ?? ''}',
    earned: _double(json['earned']),
    advance: _double(json['advance']),
    paid: _double(json['paid']),
    bonus: _double(json['bonus']),
    deduction: _double(json['deduction']),
    balance: _double(json['balance']),
    generatedAt: _date(json['generated_at']),
  );

  final String id;
  final String? companyId;
  final String labourId;
  final String labourName;
  final String month;
  final double earned;
  final double advance;
  final double paid;
  final double bonus;
  final double deduction;
  final double balance;
  final DateTime? generatedAt;
}

class PayrollData {
  const PayrollData({
    required this.month,
    required this.records,
    required this.members,
    required this.fetchedAt,
    this.isOffline = false,
  });

  final String month;
  final List<PayrollRecord> records;
  final List<WorkforceMember> members;
  final DateTime fetchedAt;
  final bool isOffline;

  double get totalEarned =>
      records.fold(0, (sum, record) => sum + record.earned);
  double get totalPaid => records.fold(0, (sum, record) => sum + record.paid);
  double get totalBalance =>
      records.fold(0, (sum, record) => sum + record.balance);
  Set<String> get generatedLabourIds =>
      records.map((record) => record.labourId).toSet();
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry('$key', value))
    : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map(_map).toList(growable: false)
    : const [];

double _double(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

String? _nullableString(Object? value) {
  final normalized = '${value ?? ''}'.trim();
  return normalized.isEmpty || normalized == 'null' ? null : normalized;
}

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();
