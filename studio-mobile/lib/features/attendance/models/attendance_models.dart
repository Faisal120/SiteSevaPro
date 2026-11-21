import '../../sites/models/site_models.dart';
import 'workforce_models.dart';

enum AttendanceStatus {
  present('PRESENT', 'Present'),
  halfDay('HALF_DAY', 'Half day'),
  absent('ABSENT', 'Absent'),
  leave('LEAVE', 'Leave');

  const AttendanceStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AttendanceStatus fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return AttendanceStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => AttendanceStatus.present,
    );
  }
}

class AttendanceEntry {
  const AttendanceEntry({
    required this.labourId,
    required this.status,
    required this.overtimeHours,
    required this.advance,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) =>
      AttendanceEntry(
        labourId: '${json['labour_id'] ?? ''}',
        status: AttendanceStatus.fromApi(json['status']),
        overtimeHours: _double(json['overtime_hours']),
        advance: _double(json['advance']),
      );

  final String labourId;
  final AttendanceStatus status;
  final double overtimeHours;
  final double advance;

  Map<String, dynamic> toApiJson() => {
    'labour_id': labourId,
    'status': status.apiValue,
    'overtime_hours': overtimeHours,
    'advance': advance,
  };

  AttendanceEntry copyWith({
    AttendanceStatus? status,
    double? overtimeHours,
    double? advance,
  }) => AttendanceEntry(
    labourId: labourId,
    status: status ?? this.status,
    overtimeHours: overtimeHours ?? this.overtimeHours,
    advance: advance ?? this.advance,
  );
}

class AttendanceDocument {
  const AttendanceDocument({
    required this.siteId,
    required this.date,
    required this.entries,
    this.id,
    this.companyId,
    this.markedBy,
    this.createdAt,
  });

  factory AttendanceDocument.fromJson(Map<String, dynamic> json) =>
      AttendanceDocument(
        id: _nullableString(json['id']),
        companyId: _nullableString(json['company_id']),
        siteId: '${json['site_id'] ?? ''}',
        date: '${json['date'] ?? ''}',
        entries: _maps(
          json['entries'],
        ).map(AttendanceEntry.fromJson).toList(growable: false),
        markedBy: _nullableString(json['marked_by']),
        createdAt: _date(json['created_at']),
      );

  final String? id;
  final String? companyId;
  final String siteId;
  final String date;
  final List<AttendanceEntry> entries;
  final String? markedBy;
  final DateTime? createdAt;

  bool get isMarked => id?.isNotEmpty == true;
  int get presentCount =>
      entries.where((entry) => entry.status == AttendanceStatus.present).length;
  int get halfDayCount =>
      entries.where((entry) => entry.status == AttendanceStatus.halfDay).length;
  int get absentCount =>
      entries.where((entry) => entry.status == AttendanceStatus.absent).length;
  int get leaveCount =>
      entries.where((entry) => entry.status == AttendanceStatus.leave).length;
  int get checkedInCount => presentCount + halfDayCount;
  double get overtimeHours =>
      entries.fold(0, (sum, entry) => sum + entry.overtimeHours);
  double get advances => entries.fold(0, (sum, entry) => sum + entry.advance);
  double get attendanceRate =>
      entries.isEmpty ? 0 : checkedInCount / entries.length;

  AttendanceEntry? entryFor(String labourId) =>
      entries.where((entry) => entry.labourId == labourId).firstOrNull;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'site_id': siteId,
    'date': date,
    'entries': entries.map((entry) => entry.toApiJson()).toList(),
    'marked_by': markedBy,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class AttendanceDraft {
  const AttendanceDraft({
    required this.siteId,
    required this.date,
    required this.entries,
  });

  factory AttendanceDraft.fromBoard({
    required String siteId,
    required String date,
    required List<WorkforceMember> members,
    required AttendanceDocument document,
  }) {
    final memberIds = members.map((member) => member.id).toList();
    final documentedIds = document.entries.map((entry) => entry.labourId);
    final ids = {...memberIds, ...documentedIds};
    return AttendanceDraft(
      siteId: siteId,
      date: date,
      entries: {
        for (final id in ids)
          id:
              document.entryFor(id) ??
              AttendanceEntry(
                labourId: id,
                status: AttendanceStatus.present,
                overtimeHours: 0,
                advance: 0,
              ),
      },
    );
  }

  final String siteId;
  final String date;
  final Map<String, AttendanceEntry> entries;

  List<AttendanceEntry> get orderedEntries =>
      entries.values.toList(growable: false);
  int get presentCount => orderedEntries
      .where((entry) => entry.status == AttendanceStatus.present)
      .length;
  int get halfDayCount => orderedEntries
      .where((entry) => entry.status == AttendanceStatus.halfDay)
      .length;
  int get absentCount => orderedEntries
      .where((entry) => entry.status == AttendanceStatus.absent)
      .length;
  int get leaveCount => orderedEntries
      .where((entry) => entry.status == AttendanceStatus.leave)
      .length;
  int get checkedInCount => presentCount + halfDayCount;
  double get overtimeHours =>
      orderedEntries.fold(0, (sum, entry) => sum + entry.overtimeHours);
  double get advances =>
      orderedEntries.fold(0, (sum, entry) => sum + entry.advance);
  double get attendanceRate =>
      entries.isEmpty ? 0 : checkedInCount / entries.length;

  String? get validationMessage {
    if (siteId.isEmpty) return 'Choose a project site.';
    if (date.isEmpty) return 'Choose an attendance date.';
    if (entries.isEmpty) return 'No workforce entries are available to save.';
    if (orderedEntries.any((entry) => entry.labourId.isEmpty)) {
      return 'One or more workforce entries are invalid.';
    }
    if (orderedEntries.any(
      (entry) => entry.overtimeHours < 0 || entry.overtimeHours > 24,
    )) {
      return 'Overtime must be between 0 and 24 hours.';
    }
    if (orderedEntries.any((entry) => entry.advance < 0)) {
      return 'Daily advances cannot be negative.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'site_id': siteId,
    'date': date,
    'entries': orderedEntries.map((entry) => entry.toApiJson()).toList(),
  };

  AttendanceDraft updateStatus(String labourId, AttendanceStatus status) =>
      _replace(labourId, (entry) => entry.copyWith(status: status));

  AttendanceDraft updateOvertime(String labourId, double hours) =>
      _replace(labourId, (entry) => entry.copyWith(overtimeHours: hours));

  AttendanceDraft updateAdvance(String labourId, double amount) =>
      _replace(labourId, (entry) => entry.copyWith(advance: amount));

  AttendanceDraft markAll(AttendanceStatus status) => AttendanceDraft(
    siteId: siteId,
    date: date,
    entries: entries.map(
      (id, entry) => MapEntry(id, entry.copyWith(status: status)),
    ),
  );

  AttendanceDraft _replace(
    String labourId,
    AttendanceEntry Function(AttendanceEntry entry) update,
  ) {
    final current = entries[labourId];
    if (current == null) return this;
    return AttendanceDraft(
      siteId: siteId,
      date: date,
      entries: {...entries, labourId: update(current)},
    );
  }
}

class AttendanceBoardData {
  const AttendanceBoardData({
    required this.sites,
    required this.siteId,
    required this.date,
    required this.members,
    required this.document,
    required this.history,
    required this.draft,
    required this.fetchedAt,
    required this.canViewMemberDetails,
    this.isOffline = false,
  });

  final List<SiteSummary> sites;
  final String? siteId;
  final String date;
  final List<WorkforceMember> members;
  final AttendanceDocument? document;
  final List<AttendanceDocument> history;
  final AttendanceDraft? draft;
  final DateTime fetchedAt;
  final bool canViewMemberDetails;
  final bool isOffline;

  SiteSummary? get selectedSite =>
      sites.where((site) => site.id == siteId).firstOrNull;
  bool get hasSite => siteId?.isNotEmpty == true;
  bool get hasWorkforce => draft?.entries.isNotEmpty == true;
  bool get isMarked => document?.isMarked == true;
  WorkforceMember? memberFor(String labourId) =>
      members.where((member) => member.id == labourId).firstOrNull;

  AttendanceBoardData copyWith({AttendanceDraft? draft}) => AttendanceBoardData(
    sites: sites,
    siteId: siteId,
    date: date,
    members: members,
    document: document,
    history: history,
    draft: draft ?? this.draft,
    fetchedAt: fetchedAt,
    canViewMemberDetails: canViewMemberDetails,
    isOffline: isOffline,
  );
}

String attendanceApiDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
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
