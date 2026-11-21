enum SiteStatus {
  planning('PLANNING', 'Planning'),
  active('ACTIVE', 'Active'),
  onHold('ON_HOLD', 'On hold'),
  completed('COMPLETED', 'Completed');

  const SiteStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SiteStatus fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return SiteStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => SiteStatus.active,
    );
  }
}

class SiteAssignee {
  const SiteAssignee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory SiteAssignee.fromJson(Map<String, dynamic> json) => SiteAssignee(
    id: '${json['id'] ?? json['user_id'] ?? ''}'.trim(),
    name: '${json['full_name'] ?? json['name'] ?? json['username'] ?? ''}'
        .trim(),
    email: '${json['email'] ?? ''}'.trim(),
    role: '${json['role'] ?? ''}'.trim().toUpperCase(),
  );

  final String id;
  final String name;
  final String email;
  final String role;

  bool get isSupervisor => role == 'SUPERVISOR';
  bool get isClient => role == 'CLIENT';
  String get displayName => name.isNotEmpty ? name : email;
}

class SiteSummary {
  const SiteSummary({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.progress,
    required this.supervisorNames,
    this.coverImage,
    this.clientName,
    this.lastActivity,
  });

  factory SiteSummary.fromJson(Map<String, dynamic> json) => SiteSummary(
    id: '${json['id'] ?? json['_id'] ?? ''}',
    name: '${json['name'] ?? ''}'.trim(),
    location: '${json['location'] ?? ''}'.trim(),
    status: SiteStatus.fromApi(json['status']),
    progress: _progress(json['progress'] ?? json['completion_percentage']),
    coverImage: _nullableString(json['cover_image']),
    supervisorNames: _stringList(
      json['supervisor_names'] ?? json['assigned_supervisors'],
    ),
    clientName: _nullableString(json['client_name'] ?? json['assigned_client_name']),
    lastActivity: _date(json['last_activity']),
  );

  final String id;
  final String name;
  final String location;
  final SiteStatus status;
  final int progress;
  final String? coverImage;
  final List<String> supervisorNames;
  final String? clientName;
  final DateTime? lastActivity;

  bool get hasCover => coverImage?.isNotEmpty ?? false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'status': status.apiValue,
    'progress': progress,
    'cover_image': coverImage,
    'supervisor_names': supervisorNames,
    'client_name': clientName,
    'last_activity': lastActivity?.toUtc().toIso8601String(),
  };
}

class SiteDetail {
  const SiteDetail({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.name,
    required this.location,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progress,
    required this.floors,
    required this.hasBoring,
    required this.hasSepticTank,
    required this.hasSoakPit,
    required this.hasMumty,
    required this.supervisorIds,
    required this.supervisorNames,
    required this.clientIds,
    required this.createdAt,
    required this.labourCount,
    required this.todayAttendance,
    required this.completedTasks,
    required this.pendingTasks,
    required this.materialCost,
    required this.labourCost,
    required this.otherCost,
    required this.totalCost,
    this.contractorId,
    this.ownerId,
    this.updatedAt,
    this.description,
    this.coverImage,
    this.lastActivity,
    this.clientId,
    this.clientName,
    this.clientEmail,
  });

  factory SiteDetail.fromJson(Map<String, dynamic> json) => SiteDetail(
    id: '${json['id'] ?? json['_id'] ?? ''}',
    companyId: '${json['company_id'] ?? ''}',
    contractorId: _nullableString(json['contractor_id']),
    createdBy: '${json['created_by'] ?? ''}',
    ownerId: _nullableString(json['owner_id']),
    createdAt:
        _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: _date(json['updated_at']),
    name: '${json['name'] ?? ''}'.trim(),
    location: '${json['location'] ?? ''}'.trim(),
    budget: _double(json['budget']),
    startDate:
        _date(json['start_date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    endDate: _date(json['end_date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    description: _nullableString(json['description']),
    coverImage: _nullableString(json['cover_image']),
    status: SiteStatus.fromApi(json['status']),
    progress: _progress(json['progress'] ?? json['completion_percentage']),
    lastActivity: _date(json['last_activity']),
    floors: _int(json['floors'], fallback: 1).clamp(1, 200),
    hasBoring: json['has_boring'] == true,
    hasSepticTank: json['has_septic_tank'] != false,
    hasSoakPit: json['has_soak_pit'] != false,
    hasMumty: json['has_mumty'] != false,
    supervisorIds: _stringList(json['supervisor_ids'] ?? json['assigned_supervisor_ids']),
    supervisorNames: _stringList(
      json['supervisor_names'] ?? json['assigned_supervisors'],
    ),
    clientId: _nullableString(json['client_id']),
    clientIds: _stringList(json['client_ids']),
    clientName: _nullableString(json['client_name'] ?? json['assigned_client_name']),
    clientEmail: _nullableString(json['client_email']),
    labourCount: _int(json['labour_count'] ?? json['active_labours']),
    todayAttendance: _int(json['today_attendance'] ?? json['attendance_today']),
    completedTasks: _int(json['completed_tasks'] ?? json['tasks_completed']),
    pendingTasks: _int(json['pending_tasks'] ?? json['tasks_pending']),
    materialCost: _double(json['material_cost'] ?? json['materials_value']),
    labourCost: _double(json['labour_cost']),
    otherCost: _double(json['other_cost']),
    totalCost: _double(json['total_cost'] ?? json['expense']),
  );

  final String id;
  final String companyId;
  final String? contractorId;
  final String createdBy;
  final String? ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String name;
  final String location;
  final double budget;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? coverImage;
  final SiteStatus status;
  final int progress;
  final DateTime? lastActivity;
  final int floors;
  final bool hasBoring;
  final bool hasSepticTank;
  final bool hasSoakPit;
  final bool hasMumty;
  final List<String> supervisorIds;
  final List<String> supervisorNames;
  final String? clientId;
  final List<String> clientIds;
  final String? clientName;
  final String? clientEmail;
  final int labourCount;
  final int todayAttendance;
  final int completedTasks;
  final int pendingTasks;
  final double materialCost;
  final double labourCost;
  final double otherCost;
  final double totalCost;

  SiteSummary get summary => SiteSummary(
    id: id,
    name: name,
    location: location,
    status: status,
    progress: progress,
    coverImage: coverImage,
    supervisorNames: supervisorNames,
    clientName: clientName,
    lastActivity: lastActivity,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'contractor_id': contractorId,
    'created_by': createdBy,
    'owner_id': ownerId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
    'name': name,
    'location': location,
    'budget': budget,
    'start_date': _apiDate(startDate),
    'end_date': _apiDate(endDate),
    'description': description,
    'cover_image': coverImage,
    'status': status.apiValue,
    'progress': progress,
    'last_activity': lastActivity?.toUtc().toIso8601String(),
    'floors': floors,
    'has_boring': hasBoring,
    'has_septic_tank': hasSepticTank,
    'has_soak_pit': hasSoakPit,
    'has_mumty': hasMumty,
    'supervisor_ids': supervisorIds,
    'supervisor_names': supervisorNames,
    'client_id': clientId,
    'client_ids': clientIds,
    'client_name': clientName,
    'client_email': clientEmail,
    'labour_count': labourCount,
    'today_attendance': todayAttendance,
    'completed_tasks': completedTasks,
    'pending_tasks': pendingTasks,
    'material_cost': materialCost,
    'labour_cost': labourCost,
    'other_cost': otherCost,
    'total_cost': totalCost,
  };
}

class SiteMutation {
  const SiteMutation({
    required this.name,
    required this.location,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.floors,
    required this.hasBoring,
    required this.hasSepticTank,
    required this.hasSoakPit,
    required this.hasMumty,
    required this.status,
    required this.progress,
    required this.supervisorIds,
    this.description,
    this.coverImage,
    this.clientId,
  });

  factory SiteMutation.fromDetail(SiteDetail detail) => SiteMutation(
    name: detail.name,
    location: detail.location,
    budget: detail.budget,
    startDate: detail.startDate,
    endDate: detail.endDate,
    description: detail.description,
    coverImage: detail.coverImage,
    floors: detail.floors,
    hasBoring: detail.hasBoring,
    hasSepticTank: detail.hasSepticTank,
    hasSoakPit: detail.hasSoakPit,
    hasMumty: detail.hasMumty,
    supervisorIds: detail.supervisorIds,
    clientId: detail.clientId,
    status: detail.status,
    progress: detail.progress,
  );

  final String name;
  final String location;
  final double budget;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? coverImage;
  final int floors;
  final bool hasBoring;
  final bool hasSepticTank;
  final bool hasSoakPit;
  final bool hasMumty;
  final List<String> supervisorIds;
  final String? clientId;
  final SiteStatus status;
  final int progress;

  Map<String, dynamic> toApiJson() => {
    'name': name.trim(),
    'location': location.trim(),
    'budget': budget,
    'start_date': _apiDate(startDate),
    'end_date': _apiDate(endDate),
    'description': _cleanOptional(description),
    'cover_image': _cleanOptional(coverImage),
    'floors': floors,
    'has_boring': hasBoring,
    'has_septic_tank': hasSepticTank,
    'has_soak_pit': hasSoakPit,
    'has_mumty': hasMumty,
    'supervisor_ids': supervisorIds,
    'client_id': _cleanOptional(clientId),
    'status': status.apiValue,
    'progress': progress.clamp(0, 100),
  };
}

class SiteCollection {
  const SiteCollection({
    required this.sites,
    required this.fetchedAt,
    this.query = '',
    this.filter,
    this.isOffline = false,
  });

  final List<SiteSummary> sites;
  final DateTime fetchedAt;
  final String query;
  final SiteStatus? filter;
  final bool isOffline;

  List<SiteSummary> get visibleSites {
    final normalized = query.trim().toLowerCase();
    return sites
        .where((site) {
          final matchesStatus = filter == null || site.status == filter;
          final matchesQuery =
              normalized.isEmpty ||
              site.name.toLowerCase().contains(normalized) ||
              site.location.toLowerCase().contains(normalized) ||
              (site.clientName?.toLowerCase().contains(normalized) ?? false) ||
              site.supervisorNames.any(
                (name) => name.toLowerCase().contains(normalized),
              );
          return matchesStatus && matchesQuery;
        })
        .toList(growable: false);
  }

  int count(SiteStatus status) =>
      sites.where((site) => site.status == status).length;

  double get averageProgress => sites.isEmpty
      ? 0
      : sites.fold<int>(0, (sum, site) => sum + site.progress) / sites.length;

  SiteCollection copyWith({
    List<SiteSummary>? sites,
    DateTime? fetchedAt,
    String? query,
    SiteStatus? filter,
    bool clearFilter = false,
    bool? isOffline,
  }) => SiteCollection(
    sites: sites ?? this.sites,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    query: query ?? this.query,
    filter: clearFilter ? null : filter ?? this.filter,
    isOffline: isOffline ?? this.isOffline,
  );
}

int _progress(Object? value) => _int(value).clamp(0, 100);

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

DateTime? _date(Object? value) {
  final parsed = DateTime.tryParse('${value ?? ''}');
  return parsed?.toLocal();
}

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

String _apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String? _cleanOptional(String? value) {
  final result = value?.trim();
  return result == null || result.isEmpty ? null : result;
}
