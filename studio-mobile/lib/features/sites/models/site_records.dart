class SiteLabour {
  const SiteLabour({
    required this.id,
    required this.siteId,
    required this.fullName,
    required this.trade,
    required this.dailyWage,
    required this.active,
    this.mobile,
    this.createdAt,
  });

  factory SiteLabour.fromJson(Map<String, dynamic> json) => SiteLabour(
    id: '${json['id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    fullName: '${json['full_name'] ?? ''}'.trim(),
    mobile: _nullableString(json['mobile']),
    trade: '${json['trade'] ?? 'Unassigned trade'}'.trim(),
    dailyWage: _double(json['daily_wage']),
    active: json['active'] != false,
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String siteId;
  final String fullName;
  final String? mobile;
  final String trade;
  final double dailyWage;
  final bool active;
  final DateTime? createdAt;
}

class SiteMaterial {
  const SiteMaterial({
    required this.id,
    required this.siteId,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.lowStockThreshold,
    required this.rate,
    this.createdAt,
  });

  factory SiteMaterial.fromJson(Map<String, dynamic> json) => SiteMaterial(
    id: '${json['id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    name: '${json['name'] ?? ''}'.trim(),
    category: '${json['category'] ?? 'Other'}'.trim(),
    unit: '${json['unit'] ?? ''}'.trim(),
    stock: _double(json['stock']),
    lowStockThreshold: _double(json['low_stock_threshold'], fallback: 10),
    rate: _double(json['rate']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String siteId;
  final String name;
  final String category;
  final String unit;
  final double stock;
  final double lowStockThreshold;
  final double rate;
  final DateTime? createdAt;

  bool get isLowStock => stock <= lowStockThreshold;
  double get stockValue => stock * rate;
}

class SitePayment {
  const SitePayment({
    required this.id,
    required this.siteId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.party,
    this.invoiceUrl,
    this.createdAt,
  });

  factory SitePayment.fromJson(Map<String, dynamic> json) => SitePayment(
    id: '${json['id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    type: '${json['type'] ?? ''}'.trim().toUpperCase(),
    amount: _double(json['amount']),
    description: '${json['description'] ?? ''}'.trim(),
    date: _date(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    party: _nullableString(json['party']),
    invoiceUrl: _nullableString(json['invoice_url']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String siteId;
  final String type;
  final double amount;
  final String description;
  final DateTime date;
  final String? party;
  final String? invoiceUrl;
  final DateTime? createdAt;

  bool get isIncome => type == 'CLIENT_RECEIVED';
}

class SiteReportMedia {
  const SiteReportMedia({required this.url, required this.type});

  factory SiteReportMedia.fromJson(Map<String, dynamic> json) =>
      SiteReportMedia(
        url: '${json['url'] ?? ''}'.trim(),
        type: '${json['type'] ?? 'image'}'.trim().toLowerCase(),
      );

  final String url;
  final String type;
}

class SiteReport {
  const SiteReport({
    required this.id,
    required this.siteId,
    required this.date,
    required this.progress,
    required this.issues,
    required this.completedTasks,
    required this.media,
    this.weather,
    this.notes,
    this.nextDayPlan,
    this.createdAt,
  });

  factory SiteReport.fromJson(Map<String, dynamic> json) => SiteReport(
    id: '${json['id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    date: _date(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    progress: _int(json['progress']).clamp(0, 100),
    weather: _nullableString(json['weather']),
    notes: _nullableString(json['notes']),
    issues: _stringList(json['issues']),
    completedTasks: _stringList(json['completed_tasks']),
    nextDayPlan: _nullableString(json['next_day_plan']),
    media: (json['media_urls'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => SiteReportMedia.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String siteId;
  final DateTime date;
  final int progress;
  final String? weather;
  final String? notes;
  final List<String> issues;
  final List<String> completedTasks;
  final String? nextDayPlan;
  final List<SiteReportMedia> media;
  final DateTime? createdAt;
}

class SiteAttendanceEntry {
  const SiteAttendanceEntry({
    required this.labourId,
    required this.status,
    required this.overtimeHours,
    required this.advance,
  });

  factory SiteAttendanceEntry.fromJson(Map<String, dynamic> json) =>
      SiteAttendanceEntry(
        labourId: '${json['labour_id'] ?? ''}',
        status: '${json['status'] ?? ''}'.trim().toUpperCase(),
        overtimeHours: _double(json['overtime_hours']),
        advance: _double(json['advance']),
      );

  final String labourId;
  final String status;
  final double overtimeHours;
  final double advance;

  bool get isPresent => status == 'PRESENT' || status == 'HALF_DAY';
}

class SiteAttendanceDay {
  const SiteAttendanceDay({
    required this.id,
    required this.siteId,
    required this.date,
    required this.entries,
    this.markedBy,
    this.createdAt,
  });

  factory SiteAttendanceDay.fromJson(
    Map<String, dynamic> json,
  ) => SiteAttendanceDay(
    id: '${json['id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    date: _date(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    entries: (json['entries'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) =>
              SiteAttendanceEntry.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false),
    markedBy: _nullableString(json['marked_by']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String siteId;
  final DateTime date;
  final List<SiteAttendanceEntry> entries;
  final String? markedBy;
  final DateTime? createdAt;

  int get present => entries.where((entry) => entry.isPresent).length;
  int get absent => entries.where((entry) => entry.status == 'ABSENT').length;
  double get overtimeHours =>
      entries.fold(0, (total, entry) => total + entry.overtimeHours);
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _double(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();

String? _nullableString(Object? value) {
  final result = '${value ?? ''}'.trim();
  return result.isEmpty || result == 'null' ? null : result;
}

List<String> _stringList(Object? value) => value is List
    ? value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];
