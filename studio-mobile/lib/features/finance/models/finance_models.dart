import '../../sites/models/site_models.dart';

enum FinanceAudience { contractor, supervisor, client }

enum FinanceWorkspace { overview, payments, expenses }

enum FinancePeriod {
  all('All time', null),
  thirtyDays('30 days', 30),
  ninetyDays('90 days', 90),
  currentMonth('This month', 0);

  const FinancePeriod(this.label, this.days);
  final String label;
  final int? days;
}

enum PaymentType {
  clientReceived('CLIENT_RECEIVED', 'Client receipt'),
  expense('EXPENSE', 'Site expense'),
  labour('LABOUR', 'Labour payment'),
  material('MATERIAL', 'Material payment'),
  unknown('UNKNOWN', 'Other payment');

  const PaymentType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  bool get isInflow => this == PaymentType.clientReceived;

  static PaymentType fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return PaymentType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => PaymentType.unknown,
    );
  }
}

enum ExpenseCategory {
  fuel('FUEL', 'Fuel'),
  transport('TRANSPORT', 'Transport'),
  equipment('EQUIPMENT', 'Equipment'),
  food('FOOD', 'Food'),
  misc('MISC', 'Miscellaneous'),
  unknown('UNKNOWN', 'Other');

  const ExpenseCategory(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ExpenseCategory fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return ExpenseCategory.values.firstWhere(
      (category) => category.apiValue == normalized,
      orElse: () => ExpenseCategory.unknown,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.companyId,
    required this.siteId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.party,
    this.invoiceUrl,
    this.createdBy,
    this.createdAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: '${json['id'] ?? json['_id'] ?? ''}',
    companyId: '${json['company_id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    type: PaymentType.fromApi(json['type']),
    amount: _double(json['amount'] ?? json['value'] ?? json['total']),
    description: '${json['description'] ?? ''}'.trim(),
    date: _date(json['date'] ?? json['payment_date'] ?? json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    party: _nullableString(json['party']),
    invoiceUrl: _nullableString(json['invoice_url']),
    createdBy: _nullableString(json['created_by']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String companyId;
  final String siteId;
  final PaymentType type;
  final double amount;
  final String description;
  final DateTime date;
  final String? party;
  final String? invoiceUrl;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isInflow => type.isInflow;
  bool get hasAttachment => invoiceUrl?.startsWith('https://') == true;
  String get displayDescription =>
      description.isEmpty ? type.label : description;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'site_id': siteId,
    'type': type.apiValue,
    'amount': amount,
    'description': description,
    'date': apiFinanceDate(date),
    'party': party,
    'invoice_url': invoiceUrl,
    'created_by': createdBy,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.companyId,
    required this.siteId,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.paidBy,
    this.receiptUrl,
    this.createdBy,
    this.createdAt,
  });

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) => ExpenseRecord(
    id: '${json['id'] ?? json['_id'] ?? ''}',
    companyId: '${json['company_id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    category: ExpenseCategory.fromApi(json['category']),
    amount: _double(json['amount'] ?? json['value'] ?? json['total']),
    description: '${json['description'] ?? ''}'.trim(),
    date: _date(json['date'] ?? json['expense_date'] ?? json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    paidBy: _nullableString(json['paid_by']),
    receiptUrl: _nullableString(json['receipt_url']),
    createdBy: _nullableString(json['created_by']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String companyId;
  final String siteId;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String? paidBy;
  final String? receiptUrl;
  final String? createdBy;
  final DateTime? createdAt;

  bool get hasReceipt => receiptUrl?.startsWith('https://') == true;
  String get displayDescription =>
      description.isEmpty ? category.label : description;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'site_id': siteId,
    'category': category.apiValue,
    'amount': amount,
    'description': description,
    'date': apiFinanceDate(date),
    'paid_by': paidBy,
    'receipt_url': receiptUrl,
    'created_by': createdBy,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class PaymentBrief {
  const PaymentBrief({
    required this.siteId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.party,
    required this.invoiceUrl,
  });

  factory PaymentBrief.initial({required DateTime referenceDate}) =>
      PaymentBrief(
        siteId: '',
        type: PaymentType.clientReceived,
        amount: 0,
        description: '',
        date: _day(referenceDate),
        party: '',
        invoiceUrl: '',
      );

  final String siteId;
  final PaymentType type;
  final double amount;
  final String description;
  final DateTime date;
  final String party;
  final String invoiceUrl;

  String? validationMessage(DateTime referenceDate) {
    if (siteId.isEmpty) return 'Choose a project site.';
    if (type == PaymentType.unknown) return 'Choose a payment type.';
    if (!amount.isFinite || amount <= 0)
      return 'Enter an amount greater than zero.';
    if (description.trim().length < 3)
      return 'Add a clear payment description.';
    if (_day(date).isAfter(_day(referenceDate)))
      return 'Payment date cannot be in the future.';
    if (invoiceUrl.isNotEmpty && !_secureUrl(invoiceUrl)) {
      return 'The invoice attachment must use a secure HTTPS URL.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'site_id': siteId,
    'type': type.apiValue,
    'amount': amount,
    'description': description.trim(),
    'date': apiFinanceDate(date),
    if (party.trim().isNotEmpty) 'party': party.trim(),
    if (invoiceUrl.trim().isNotEmpty) 'invoice_url': invoiceUrl.trim(),
  };

  PaymentBrief copyWith({
    String? siteId,
    PaymentType? type,
    double? amount,
    String? description,
    DateTime? date,
    String? party,
    String? invoiceUrl,
  }) => PaymentBrief(
    siteId: siteId ?? this.siteId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    date: date ?? this.date,
    party: party ?? this.party,
    invoiceUrl: invoiceUrl ?? this.invoiceUrl,
  );
}

class ExpenseBrief {
  const ExpenseBrief({
    required this.siteId,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.paidBy,
    required this.receiptUrl,
  });

  factory ExpenseBrief.initial({required DateTime referenceDate}) =>
      ExpenseBrief(
        siteId: '',
        category: ExpenseCategory.misc,
        amount: 0,
        description: '',
        date: _day(referenceDate),
        paidBy: '',
        receiptUrl: '',
      );

  final String siteId;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String paidBy;
  final String receiptUrl;

  String? validationMessage(DateTime referenceDate) {
    if (siteId.isEmpty) return 'Choose a project site.';
    if (category == ExpenseCategory.unknown)
      return 'Choose an expense category.';
    if (!amount.isFinite || amount <= 0)
      return 'Enter an amount greater than zero.';
    if (description.trim().length < 3)
      return 'Add a clear expense description.';
    if (_day(date).isAfter(_day(referenceDate)))
      return 'Expense date cannot be in the future.';
    if (receiptUrl.isNotEmpty && !_secureUrl(receiptUrl)) {
      return 'The receipt attachment must use a secure HTTPS URL.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'site_id': siteId,
    'category': category.apiValue,
    'amount': amount,
    'description': description.trim(),
    'date': apiFinanceDate(date),
    if (paidBy.trim().isNotEmpty) 'paid_by': paidBy.trim(),
    if (receiptUrl.trim().isNotEmpty) 'receipt_url': receiptUrl.trim(),
  };

  ExpenseBrief copyWith({
    String? siteId,
    ExpenseCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    String? paidBy,
    String? receiptUrl,
  }) => ExpenseBrief(
    siteId: siteId ?? this.siteId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    date: date ?? this.date,
    paidBy: paidBy ?? this.paidBy,
    receiptUrl: receiptUrl ?? this.receiptUrl,
  );
}

class ExpenseCategorySummary {
  const ExpenseCategorySummary({
    required this.category,
    required this.total,
    required this.count,
  });

  factory ExpenseCategorySummary.fromJson(Map<String, dynamic> json) =>
      ExpenseCategorySummary(
        category: ExpenseCategory.fromApi(json['_id'] ?? json['category']),
        total: _double(json['total']),
        count: _int(json['count']),
      );

  final ExpenseCategory category;
  final double total;
  final int count;

  Map<String, dynamic> toJson() => {
    '_id': category.apiValue,
    'total': total,
    'count': count,
  };
}

class MonthlyExpenseSummary {
  const MonthlyExpenseSummary({required this.month, required this.total});

  factory MonthlyExpenseSummary.fromJson(Map<String, dynamic> json) =>
      MonthlyExpenseSummary(
        month: '${json['_id'] ?? json['month'] ?? ''}',
        total: _double(json['total']),
      );

  final String month;
  final double total;

  Map<String, dynamic> toJson() => {'_id': month, 'total': total};
}

class ExpenseReport {
  const ExpenseReport({required this.byCategory, required this.monthly});

  factory ExpenseReport.empty() =>
      const ExpenseReport(byCategory: [], monthly: []);

  factory ExpenseReport.fromJson(Map<String, dynamic> json) => ExpenseReport(
    byCategory: _maps(
      json['by_category'],
    ).map(ExpenseCategorySummary.fromJson).toList(growable: false),
    monthly: _maps(
      json['monthly'],
    ).map(MonthlyExpenseSummary.fromJson).toList(growable: false),
  );

  final List<ExpenseCategorySummary> byCategory;
  final List<MonthlyExpenseSummary> monthly;

  Map<String, dynamic> toJson() => {
    'by_category': byCategory.map((item) => item.toJson()).toList(),
    'monthly': monthly.map((item) => item.toJson()).toList(),
  };
}

class FinanceTrendPoint {
  const FinanceTrendPoint({
    required this.date,
    required this.inflow,
    required this.outflow,
  });
  final DateTime date;
  final double inflow;
  final double outflow;
}

class FinanceStudioData {
  const FinanceStudioData({
    required this.payments,
    required this.expenses,
    required this.expenseReport,
    required this.sites,
    required this.audience,
    required this.fetchedAt,
    required this.referenceDate,
    this.isOffline = false,
    this.workspace = FinanceWorkspace.overview,
    this.period = FinancePeriod.thirtyDays,
    this.query = '',
    this.siteFilter,
    this.paymentTypeFilter,
    this.expenseCategoryFilter,
  });

  final List<PaymentRecord> payments;
  final List<ExpenseRecord> expenses;
  final ExpenseReport expenseReport;
  final List<SiteSummary> sites;
  final FinanceAudience audience;
  final DateTime fetchedAt;
  final DateTime referenceDate;
  final bool isOffline;
  final FinanceWorkspace workspace;
  final FinancePeriod period;
  final String query;
  final String? siteFilter;
  final PaymentType? paymentTypeFilter;
  final ExpenseCategory? expenseCategoryFilter;

  bool get isContractor => audience == FinanceAudience.contractor;
  bool get isSupervisor => audience == FinanceAudience.supervisor;
  bool get isClient => audience == FinanceAudience.client;
  bool get canCreatePayment => isContractor && !isOffline;
  bool get canCreateExpense => !isClient && !isOffline;
  List<FinanceWorkspace> get availableWorkspaces => switch (audience) {
    FinanceAudience.contractor => FinanceWorkspace.values,
    FinanceAudience.supervisor => const [
      FinanceWorkspace.overview,
      FinanceWorkspace.expenses,
    ],
    FinanceAudience.client => const [FinanceWorkspace.payments],
  };

  SiteSummary? site(String siteId) {
    for (final item in sites) {
      if (item.id == siteId) return item;
    }
    return null;
  }

  String siteName(String siteId) => site(siteId)?.name ?? 'Project site';

  bool _withinPeriod(DateTime date) {
    final value = _day(date);
    final reference = _day(referenceDate);
    if (value.isAfter(reference)) return false;
    if (period == FinancePeriod.all) return true;
    if (period == FinancePeriod.currentMonth) {
      return value.year == reference.year && value.month == reference.month;
    }
    return !value.isBefore(
      reference.subtract(Duration(days: period.days! - 1)),
    );
  }

  List<PaymentRecord> get visiblePayments {
    final normalized = query.trim().toLowerCase();
    final result = payments
        .where((payment) {
          if (siteFilter != null && payment.siteId != siteFilter) return false;
          if (paymentTypeFilter != null && payment.type != paymentTypeFilter)
            return false;
          if (!_withinPeriod(payment.date)) return false;
          if (normalized.isEmpty) return true;
          return payment.displayDescription.toLowerCase().contains(
                normalized,
              ) ||
              (payment.party ?? '').toLowerCase().contains(normalized) ||
              siteName(payment.siteId).toLowerCase().contains(normalized);
        })
        .toList(growable: false);
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<ExpenseRecord> get visibleExpenses {
    final normalized = query.trim().toLowerCase();
    final result = expenses
        .where((expense) {
          if (siteFilter != null && expense.siteId != siteFilter) return false;
          if (expenseCategoryFilter != null &&
              expense.category != expenseCategoryFilter) {
            return false;
          }
          if (!_withinPeriod(expense.date)) return false;
          if (normalized.isEmpty) return true;
          return expense.displayDescription.toLowerCase().contains(
                normalized,
              ) ||
              (expense.paidBy ?? '').toLowerCase().contains(normalized) ||
              siteName(expense.siteId).toLowerCase().contains(normalized);
        })
        .toList(growable: false);
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  double get recordedInflow => visiblePayments
      .where((payment) => payment.isInflow)
      .fold(0, (total, payment) => total + payment.amount);

  double get recordedOutflow => isSupervisor
      ? visibleExpenses.fold(0, (total, expense) => total + expense.amount)
      : visiblePayments
            .where((payment) => !payment.isInflow)
            .fold(0, (total, payment) => total + payment.amount);

  double get netRecordedCashflow => recordedInflow - recordedOutflow;

  List<ExpenseCategorySummary> get visibleCategorySummary {
    final totals = <ExpenseCategory, double>{};
    final counts = <ExpenseCategory, int>{};
    for (final expense in visibleExpenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
      counts.update(expense.category, (value) => value + 1, ifAbsent: () => 1);
    }
    final result = totals.entries
        .map(
          (entry) => ExpenseCategorySummary(
            category: entry.key,
            total: entry.value,
            count: counts[entry.key] ?? 0,
          ),
        )
        .toList();
    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  List<FinanceTrendPoint> get trend {
    final days = period == FinancePeriod.currentMonth
        ? referenceDate.day
        : (period.days ?? 90).clamp(7, 90);
    final bucketSize = days > 31 ? 7 : 1;
    final count = (days / bucketSize).ceil();
    final start = _day(referenceDate).subtract(Duration(days: days - 1));
    return List.generate(count, (index) {
      final bucketStart = start.add(Duration(days: index * bucketSize));
      final bucketEnd = bucketStart.add(Duration(days: bucketSize));
      final paymentsInBucket = visiblePayments.where((payment) {
        final date = _day(payment.date);
        return !date.isBefore(bucketStart) && date.isBefore(bucketEnd);
      });
      final expensesInBucket = visibleExpenses.where((expense) {
        final date = _day(expense.date);
        return !date.isBefore(bucketStart) && date.isBefore(bucketEnd);
      });
      final inflow = paymentsInBucket
          .where((payment) => payment.isInflow)
          .fold<double>(0, (total, payment) => total + payment.amount);
      final outflow = isSupervisor
          ? expensesInBucket.fold<double>(
              0,
              (total, expense) => total + expense.amount,
            )
          : paymentsInBucket
                .where((payment) => !payment.isInflow)
                .fold<double>(0, (total, payment) => total + payment.amount);
      return FinanceTrendPoint(
        date: bucketStart,
        inflow: inflow,
        outflow: outflow,
      );
    });
  }

  FinanceStudioData copyWith({
    List<PaymentRecord>? payments,
    List<ExpenseRecord>? expenses,
    ExpenseReport? expenseReport,
    List<SiteSummary>? sites,
    FinanceAudience? audience,
    DateTime? fetchedAt,
    DateTime? referenceDate,
    bool? isOffline,
    FinanceWorkspace? workspace,
    FinancePeriod? period,
    String? query,
    String? siteFilter,
    bool clearSite = false,
    PaymentType? paymentTypeFilter,
    bool clearPaymentType = false,
    ExpenseCategory? expenseCategoryFilter,
    bool clearExpenseCategory = false,
  }) => FinanceStudioData(
    payments: payments ?? this.payments,
    expenses: expenses ?? this.expenses,
    expenseReport: expenseReport ?? this.expenseReport,
    sites: sites ?? this.sites,
    audience: audience ?? this.audience,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    referenceDate: referenceDate ?? this.referenceDate,
    isOffline: isOffline ?? this.isOffline,
    workspace: workspace ?? this.workspace,
    period: period ?? this.period,
    query: query ?? this.query,
    siteFilter: clearSite ? null : siteFilter ?? this.siteFilter,
    paymentTypeFilter: clearPaymentType
        ? null
        : paymentTypeFilter ?? this.paymentTypeFilter,
    expenseCategoryFilter: clearExpenseCategory
        ? null
        : expenseCategoryFilter ?? this.expenseCategoryFilter,
  );
}

String apiFinanceDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value')?.toLocal();
}

double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String? _nullableString(Object? value) {
  final normalized = '$value'.trim();
  return value == null || normalized.isEmpty || normalized == 'null'
      ? null
      : normalized;
}

bool _secureUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];
