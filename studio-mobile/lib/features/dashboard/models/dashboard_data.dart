class DashboardData {
  const DashboardData({
    required this.company,
    required this.stats,
    required this.sites,
    required this.charts,
    required this.activities,
    required this.alerts,
    required this.photos,
    required this.payments,
    required this.todayAttendance,
    required this.campaigns,
    required this.fetchedAt,
    this.isOffline = false,
  });

  factory DashboardData.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    bool isOffline = false,
  }) => DashboardData(
    company: DashboardCompany.fromJson(_map(json['company'])),
    stats: DashboardStats.fromJson(
      _mergeMaps(
        _map(json['financial_summary'] ?? json['finance']),
        _map(json['stats']),
      ),
    ),
    sites: _mapList(json['sites']).map(DashboardSite.fromJson).toList(),
    charts: DashboardCharts.fromJson(_map(json['charts'])),
    activities: _mapList(
      json['activities'],
    ).map(DashboardActivity.fromJson).toList(),
    alerts: _mapList(json['alerts']).map(DashboardAlert.fromJson).toList(),
    photos: _mapList(json['latestPhotos'] ?? json['latest_photos'])
        .map(DashboardPhoto.fromJson)
        .where((photo) => photo.url.isNotEmpty)
        .toList(),
    payments: _mapList(
      json['payments'],
    ).map(DashboardPayment.fromJson).toList(),
    todayAttendance: _mapList(
      json['todayAttendance'] ?? json['today_attendance'],
    ).map(DashboardAttendance.fromJson).toList(),
    campaigns: _mapList(
      json['campaigns'] ?? json['banners'] ?? json['carousel'],
    ).map(DashboardCampaign.fromJson).toList(),
    fetchedAt: fetchedAt ?? DateTime.now(),
    isOffline: isOffline,
  );

  final DashboardCompany company;
  final DashboardStats stats;
  final List<DashboardSite> sites;
  final DashboardCharts charts;
  final List<DashboardActivity> activities;
  final List<DashboardAlert> alerts;
  final List<DashboardPhoto> photos;
  final List<DashboardPayment> payments;
  final List<DashboardAttendance> todayAttendance;
  final List<DashboardCampaign> campaigns;
  final DateTime fetchedAt;
  final bool isOffline;

  int get todayPresent => todayAttendance
      .where((record) => record.status.toUpperCase() == 'PRESENT')
      .length;

  double get averageSiteProgress {
    if (sites.isEmpty) return 0;
    final total = sites.fold<double>(0, (sum, site) => sum + site.progress);
    return total / sites.length;
  }

  int deadlineWatch(DateTime now) => sites.where((site) {
    if (site.progress >= 100) return false;
    final status = site.status.toUpperCase();
    if (status == 'DELAYED' || status == 'ON_HOLD') return true;
    final endDate = site.endDate;
    if (endDate == null) return false;
    return !endDate.isAfter(now.add(const Duration(days: 30)));
  }).length;

  List<DashboardProgressPoint> get projectProgress =>
      charts.siteProgress.isNotEmpty
      ? charts.siteProgress
      : sites
            .map(
              (site) => DashboardProgressPoint(
                name: site.name,
                progress: site.progress,
              ),
            )
            .toList(growable: false);

  DashboardData copyWith({List<DashboardAlert>? alerts}) => DashboardData(
    company: company,
    stats: stats,
    sites: sites,
    charts: charts,
    activities: activities,
    alerts: alerts ?? this.alerts,
    photos: photos,
    payments: payments,
    todayAttendance: todayAttendance,
    campaigns: campaigns,
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );
}

class DashboardCompany {
  const DashboardCompany({
    required this.id,
    required this.name,
    this.logoUrl,
    this.city,
    this.state,
    this.plan,
  });

  factory DashboardCompany.fromJson(Map<String, dynamic> json) =>
      DashboardCompany(
        id: _string(json['id']),
        name: _string(json['name'] ?? json['company_name']),
        logoUrl: _nullableString(
          json['logo_url'] ?? json['logo'] ?? json['company_logo'],
        ),
        city: _nullableString(json['city']),
        state: _nullableString(json['state']),
        plan: _nullableString(json['plan'] ?? json['subscription_plan']),
      );

  final String id;
  final String name;
  final String? logoUrl;
  final String? city;
  final String? state;
  final String? plan;
}

class DashboardStats {
  const DashboardStats({
    required this.totalSites,
    required this.activeSites,
    required this.completedSites,
    required this.labours,
    required this.todayLabours,
    required this.pendingTasks,
    required this.completedTasks,
    required this.todayReports,
    required this.cashflow,
    required this.totalRevenue,
    required this.expense,
    required this.pendingPayments,
    required this.netProfit,
    required this.netLoss,
    required this.labourExpense,
    required this.materialExpense,
    required this.otherExpense,
    required this.totalBudget,
    required this.lowStock,
    required this.productivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalSites: _int(json['total_sites'] ?? json['sites_total']),
    activeSites: _int(json['active_sites'] ?? json['running_sites']),
    completedSites: _int(json['completed_sites'] ?? json['sites_completed']),
    labours: _int(json['labours'] ?? json['labour_count']),
    todayLabours: _int(json['today_labours'] ?? json['today_attendance']),
    pendingTasks: _int(json['pending_tasks']),
    completedTasks: _int(json['completed_tasks']),
    todayReports: _int(json['today_reports'] ?? json['todays_reports']),
    cashflow: _double(json['cashflow'] ?? json['net_cashflow']),
    totalRevenue: _double(json['total_revenue'] ?? json['revenue'] ?? json['income']),
    expense: _double(json['expense'] ?? json['total_expense'] ?? json['expenses']),
    pendingPayments: _double(json['pending_payments'] ?? json['outstanding']),
    netProfit: _double(json['net_profit'] ?? json['profit']),
    netLoss: _double(json['net_loss'] ?? json['loss']),
    labourExpense: _double(json['labour_expense'] ?? json['labour_cost']),
    materialExpense: _double(json['material_expense'] ?? json['material_cost'] ?? json['materials_value']),
    otherExpense: _double(json['other_expense'] ?? json['other_cost']),
    totalBudget: _double(json['total_budget'] ?? json['budget']),
    lowStock: _int(json['low_stock']),
    productivity: _double(json['productivity']),
  );

  final int totalSites;
  final int activeSites;
  final int completedSites;
  final int labours;
  final int todayLabours;
  final int pendingTasks;
  final int completedTasks;
  final int todayReports;
  final double cashflow;
  final double totalRevenue;
  final double expense;
  final double pendingPayments;
  final double netProfit;
  final double netLoss;
  final double labourExpense;
  final double materialExpense;
  final double otherExpense;
  final double totalBudget;
  final int lowStock;
  final double productivity;
}

class DashboardSite {
  const DashboardSite({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.progress,
    required this.budget,
    required this.supervisorNames,
    this.coverImage,
    this.clientName,
    this.endDate,
    this.lastActivity,
  });

  factory DashboardSite.fromJson(Map<String, dynamic> json) => DashboardSite(
    id: _string(json['id'] ?? json['_id']),
    name: _string(json['name']),
    location: _string(json['location']),
    status: _string(json['status']),
    progress: _double(json['progress'] ?? json['completion_percentage']).clamp(0, 100),
    budget: _double(json['budget']),
    coverImage: _nullableString(json['cover_image'] ?? json['image_url']),
    clientName: _nullableString(json['client_name'] ?? json['assigned_client_name']),
    supervisorNames: ((json['supervisor_names'] ?? json['assigned_supervisors']) as List? ?? const [])
        .map((name) => '$name')
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false),
    endDate: _date(json['end_date']),
    lastActivity: _date(json['last_activity']),
  );

  final String id;
  final String name;
  final String location;
  final String status;
  final double progress;
  final double budget;
  final String? coverImage;
  final String? clientName;
  final List<String> supervisorNames;
  final DateTime? endDate;
  final DateTime? lastActivity;
}

class DashboardCharts {
  const DashboardCharts({
    required this.siteProgress,
    required this.expenseBreakdown,
    required this.attendance,
    required this.cashflow,
  });

  factory DashboardCharts.fromJson(Map<String, dynamic> json) =>
      DashboardCharts(
        siteProgress: _mapList(
          json['site_progress'],
        ).map(DashboardProgressPoint.fromJson).toList(),
        expenseBreakdown: _mapList(
          json['expense_breakdown'],
        ).map(DashboardValuePoint.fromJson).toList(),
        attendance: _mapList(
          json['attendance'],
        ).map(DashboardAttendancePoint.fromJson).toList(),
        cashflow: _mapList(
          json['cashflow'],
        ).map(DashboardCashflowPoint.fromJson).toList(),
      );

  final List<DashboardProgressPoint> siteProgress;
  final List<DashboardValuePoint> expenseBreakdown;
  final List<DashboardAttendancePoint> attendance;
  final List<DashboardCashflowPoint> cashflow;
}

class DashboardProgressPoint {
  const DashboardProgressPoint({required this.name, required this.progress});

  factory DashboardProgressPoint.fromJson(Map<String, dynamic> json) =>
      DashboardProgressPoint(
        name: _string(json['name']),
        progress: _double(json['progress']).clamp(0, 100),
      );

  final String name;
  final double progress;
}

class DashboardValuePoint {
  const DashboardValuePoint({required this.name, required this.value});

  factory DashboardValuePoint.fromJson(Map<String, dynamic> json) =>
      DashboardValuePoint(
        name: _string(json['name']),
        value: _double(json['value']),
      );

  final String name;
  final double value;
}

class DashboardAttendancePoint {
  const DashboardAttendancePoint({
    required this.date,
    required this.present,
    required this.absent,
  });

  factory DashboardAttendancePoint.fromJson(Map<String, dynamic> json) =>
      DashboardAttendancePoint(
        date: _string(json['date']),
        present: _int(json['present']),
        absent: _int(json['absent']),
      );

  final String date;
  final int present;
  final int absent;
}

class DashboardCashflowPoint {
  const DashboardCashflowPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory DashboardCashflowPoint.fromJson(Map<String, dynamic> json) =>
      DashboardCashflowPoint(
        month: _string(json['month']),
        income: _double(json['income']),
        expense: _double(json['expense']),
      );

  final String month;
  final double income;
  final double expense;
}

class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.createdAt,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) =>
      DashboardActivity(
        id: _string(json['id']),
        type: _string(json['type']),
        title: _string(json['title']),
        description: _string(json['description']),
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime? createdAt;
}

class DashboardAlert {
  const DashboardAlert({
    required this.type,
    required this.severity,
    required this.title,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) => DashboardAlert(
    type: _string(json['type']),
    severity: _string(json['severity']),
    title: _string(json['title']),
  );

  final String type;
  final String severity;
  final String title;
}

class DashboardPhoto {
  const DashboardPhoto({
    required this.url,
    required this.thumbnail,
    required this.caption,
    required this.siteName,
    this.createdAt,
  });

  factory DashboardPhoto.fromJson(Map<String, dynamic> json) => DashboardPhoto(
    url: _string(json['url']),
    thumbnail: _string(json['thumbnail'] ?? json['url']),
    caption: _string(json['caption']),
    siteName: _string(json['site_name']),
    createdAt: _date(json['created_at']),
  );

  final String url;
  final String thumbnail;
  final String caption;
  final String siteName;
  final DateTime? createdAt;
}

class DashboardPayment {
  const DashboardPayment({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.party,
    this.createdAt,
  });

  factory DashboardPayment.fromJson(Map<String, dynamic> json) =>
      DashboardPayment(
        id: _string(json['id']),
        type: _string(json['payment_type'] ?? json['type']),
        amount: _double(json['amount']),
        description: _string(json['description']),
        party: _string(json['party']),
        createdAt: _date(json['created_at'] ?? json['date']),
      );

  final String id;
  final String type;
  final double amount;
  final String description;
  final String party;
  final DateTime? createdAt;
}

class DashboardAttendance {
  const DashboardAttendance({
    required this.id,
    required this.status,
    required this.labourName,
    required this.siteId,
  });

  factory DashboardAttendance.fromJson(Map<String, dynamic> json) =>
      DashboardAttendance(
        id: _string(json['id']),
        status: _string(json['status']),
        labourName: _string(json['labour_name'] ?? json['name']),
        siteId: _string(json['site_id']),
      );

  final String id;
  final String status;
  final String labourName;
  final String siteId;
}

class DashboardCampaign {
  const DashboardCampaign({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.actionPath,
    required this.tone,
    required this.roles,
    this.imageUrl,
    this.isPromoted = false,
  });

  factory DashboardCampaign.fromJson(Map<String, dynamic> json) {
    final actionKey = _string(json['action_key'] ?? json['action']);
    final rawPath = _string(json['action_path'] ?? json['action_url']);
    return DashboardCampaign(
      id: _string(json['id']),
      eyebrow: _string(json['eyebrow'] ?? json['badge']),
      title: _string(json['title']),
      body: _string(json['body'] ?? json['message'] ?? json['subtitle']),
      actionLabel: _string(json['action_label'] ?? json['cta_label']),
      actionPath: _safeCampaignPath(actionKey, rawPath),
      tone: _string(json['tone'] ?? json['theme']).toUpperCase(),
      roles: (json['roles'] as List? ?? const [])
          .map((role) => '$role'.trim().toUpperCase())
          .where((role) => role.isNotEmpty)
          .toList(growable: false),
      imageUrl: _nullableString(json['image_url'] ?? json['image']),
      isPromoted: json['is_promoted'] == true || json['is_ad'] == true,
    );
  }

  final String id;
  final String eyebrow;
  final String title;
  final String body;
  final String actionLabel;
  final String? actionPath;
  final String tone;
  final List<String> roles;
  final String? imageUrl;
  final bool isPromoted;

  bool supportsRole(String role) {
    if (roles.isEmpty) return true;
    return roles.contains(role.trim().toUpperCase());
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _mergeMaps(
  Map<String, dynamic> base,
  Map<String, dynamic> override,
) => {...base, ...override};

String _string(dynamic value) => value == null ? '' : '$value'.trim();

String? _nullableString(dynamic value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

DateTime? _date(dynamic value) {
  final text = _string(value);
  return text.isEmpty ? null : DateTime.tryParse(text)?.toLocal();
}

String? _safeCampaignPath(String actionKey, String rawPath) {
  final key = actionKey.trim().toUpperCase();
  final keyedPath = switch (key) {
    'SITES' || 'PROJECTS' => '/sites',
    'ATTENDANCE' => '/attendance',
    'LABOUR' || 'WORKFORCE' => '/labour',
    'MATERIALS' || 'STOCK' => '/materials',
    'PAYMENTS' => '/payments',
    'EXPENSES' => '/expenses',
    'ESTIMATES' || 'ESTIMATE' => '/estimates',
    'BOQ' => '/boq',
    'REPORTS' => '/reports',
    'AI_STUDIO' || 'DESIGN_STUDIO' => '/design-studio',
    'NOTIFICATIONS' => '/notifications',
    'SUBSCRIPTION' => '/subscription',
    'HELP' || 'SUPPORT' => '/help',
    _ => null,
  };
  if (keyedPath != null) return keyedPath;
  if (rawPath.isEmpty) return null;
  final uri = Uri.tryParse(rawPath);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  const allowed = {
    '/sites',
    '/attendance',
    '/labour',
    '/materials',
    '/payments',
    '/expenses',
    '/estimates',
    '/boq',
    '/reports',
    '/design-studio',
    '/notifications',
    '/subscription',
    '/help',
  };
  return allowed.contains(uri.path) ? uri.toString() : null;
}
