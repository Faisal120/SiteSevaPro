import 'dart:typed_data';

import '../../sites/models/site_models.dart';

enum ReportsWorkspace { logbook, insights, media }

enum ReportsPeriod {
  all('All time', null),
  sevenDays('7 days', 7),
  thirtyDays('30 days', 30);

  const ReportsPeriod(this.label, this.days);

  final String label;
  final int? days;
}

class ReportMedia {
  const ReportMedia({required this.url, required this.type, this.publicId});

  factory ReportMedia.fromJson(Map<String, dynamic> json) => ReportMedia(
    url: '${json['url'] ?? json['secure_url'] ?? ''}'.trim(),
    publicId: _nullableString(json['public_id']),
    type: '${json['type'] ?? json['resource_type'] ?? 'image'}'
        .trim()
        .toLowerCase(),
  );

  final String url;
  final String? publicId;
  final String type;

  bool get isImage => type == 'image';

  Map<String, dynamic> toJson() => {
    'url': url,
    'public_id': publicId,
    'type': type,
  };
}

class DailyReport {
  const DailyReport({
    required this.id,
    required this.companyId,
    required this.siteId,
    required this.date,
    required this.progress,
    required this.issues,
    required this.completedTasks,
    required this.media,
    this.weather,
    this.notes,
    this.nextDayPlan,
    this.createdBy,
    this.createdAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    id: '${json['id'] ?? ''}',
    companyId: '${json['company_id'] ?? ''}',
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
        .map((item) => ReportMedia.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false),
    createdBy: _nullableString(json['created_by']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String companyId;
  final String siteId;
  final DateTime date;
  final int progress;
  final String? weather;
  final String? notes;
  final List<String> issues;
  final List<String> completedTasks;
  final String? nextDayPlan;
  final List<ReportMedia> media;
  final String? createdBy;
  final DateTime? createdAt;

  String get narrative {
    if (notes?.isNotEmpty == true) return notes!;
    if (completedTasks.isNotEmpty) return completedTasks.first;
    if (issues.isNotEmpty) return issues.first;
    return 'Field report submitted without a narrative.';
  }

  bool get hasIssues => issues.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'site_id': siteId,
    'date': apiReportDate(date),
    'progress': progress,
    'weather': weather,
    'notes': notes,
    'issues': issues,
    'completed_tasks': completedTasks,
    'next_day_plan': nextDayPlan,
    'media_urls': media.map((item) => item.toJson()).toList(growable: false),
    'created_by': createdBy,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class DailyReportBrief {
  const DailyReportBrief({
    required this.siteId,
    required this.date,
    required this.progress,
    required this.currentSiteProgress,
    required this.weather,
    required this.notes,
    required this.issues,
    required this.completedTasks,
    required this.nextDayPlan,
    required this.media,
    required this.referenceDate,
  });

  factory DailyReportBrief.initial({
    SiteSummary? site,
    required DateTime referenceDate,
  }) => DailyReportBrief(
    siteId: site?.id ?? '',
    date: _day(referenceDate),
    progress: site?.progress ?? 0,
    currentSiteProgress: site?.progress ?? 0,
    weather: '',
    notes: '',
    issues: const [],
    completedTasks: const [],
    nextDayPlan: '',
    media: const [],
    referenceDate: _day(referenceDate),
  );

  final String siteId;
  final DateTime date;
  final int progress;
  final int currentSiteProgress;
  final String weather;
  final String notes;
  final List<String> issues;
  final List<String> completedTasks;
  final String nextDayPlan;
  final List<ReportMedia> media;
  final DateTime referenceDate;

  String? get validationMessage {
    if (siteId.isEmpty) return 'Choose the project site.';
    if (_day(date).isAfter(_day(referenceDate))) {
      return 'A daily report cannot be dated in the future.';
    }
    if (progress < 0 || progress > 100) {
      return 'Project progress must be between 0 and 100 percent.';
    }
    if (progress < currentSiteProgress) {
      return 'Progress cannot be lower than the current site progress.';
    }
    if (notes.trim().isEmpty &&
        issues.isEmpty &&
        completedTasks.isEmpty &&
        media.isEmpty) {
      return 'Add completed work, an issue, site notes, or photo evidence.';
    }
    if (issues.length > 20 || completedTasks.length > 20) {
      return 'A report can contain up to 20 work items and 20 issues.';
    }
    if (media.length > 8) return 'A report can contain up to 8 photos.';
    if (media.any((item) {
      final uri = Uri.tryParse(item.url);
      return uri == null || uri.scheme != 'https' || uri.host.isEmpty;
    })) {
      return 'Every report photo must use a secure uploaded URL.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'site_id': siteId,
    'date': apiReportDate(date),
    'progress': progress,
    'weather': _optional(weather),
    'notes': _optional(notes),
    'issues': _cleanList(issues),
    'completed_tasks': _cleanList(completedTasks),
    'next_day_plan': _optional(nextDayPlan),
    'media_urls': media.map((item) => item.toJson()).toList(growable: false),
  };

  DailyReportBrief copyWith({
    String? siteId,
    DateTime? date,
    int? progress,
    int? currentSiteProgress,
    String? weather,
    String? notes,
    List<String>? issues,
    List<String>? completedTasks,
    String? nextDayPlan,
    List<ReportMedia>? media,
    DateTime? referenceDate,
  }) => DailyReportBrief(
    siteId: siteId ?? this.siteId,
    date: date == null ? this.date : _day(date),
    progress: progress ?? this.progress,
    currentSiteProgress: currentSiteProgress ?? this.currentSiteProgress,
    weather: weather ?? this.weather,
    notes: notes ?? this.notes,
    issues: issues ?? this.issues,
    completedTasks: completedTasks ?? this.completedTasks,
    nextDayPlan: nextDayPlan ?? this.nextDayPlan,
    media: media ?? this.media,
    referenceDate: referenceDate ?? this.referenceDate,
  );
}

class ReportPhotoUpload {
  const ReportPhotoUpload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  String? get validationMessage {
    if (bytes.isEmpty) return 'The selected photo is empty.';
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      return 'Choose a photo smaller than 10 MB.';
    }
    final normalized = filename.toLowerCase();
    if (!normalized.endsWith('.jpg') &&
        !normalized.endsWith('.jpeg') &&
        !normalized.endsWith('.png') &&
        !normalized.endsWith('.webp') &&
        !normalized.endsWith('.heic')) {
      return 'Choose a JPG, PNG, WEBP, or HEIC image.';
    }
    return null;
  }
}

class ReportEvidence {
  const ReportEvidence({
    required this.report,
    required this.media,
    required this.siteName,
  });

  final DailyReport report;
  final ReportMedia media;
  final String siteName;
}

class ReportTrendPoint {
  const ReportTrendPoint({
    required this.date,
    required this.progress,
    required this.siteId,
  });

  final DateTime date;
  final int progress;
  final String siteId;
}

class SiteReportActivity {
  const SiteReportActivity({
    required this.site,
    required this.reportCount,
    required this.issueCount,
    required this.latestProgress,
    this.lastReportAt,
  });

  final SiteSummary site;
  final int reportCount;
  final int issueCount;
  final int latestProgress;
  final DateTime? lastReportAt;
}

class ReportsStudioData {
  const ReportsStudioData({
    required this.reports,
    required this.sites,
    required this.fetchedAt,
    required this.referenceDate,
    required this.canCreate,
    this.isOffline = false,
    this.workspace = ReportsWorkspace.logbook,
    this.period = ReportsPeriod.thirtyDays,
    this.query = '',
    this.siteFilter,
  });

  final List<DailyReport> reports;
  final List<SiteSummary> sites;
  final DateTime fetchedAt;
  final DateTime referenceDate;
  final bool canCreate;
  final bool isOffline;
  final ReportsWorkspace workspace;
  final ReportsPeriod period;
  final String query;
  final String? siteFilter;

  SiteSummary? site(String siteId) {
    for (final item in sites) {
      if (item.id == siteId) return item;
    }
    return null;
  }

  String siteName(String siteId) => site(siteId)?.name ?? 'Project site';

  List<DailyReport> get scopedReports {
    final start = period.days == null
        ? null
        : _day(referenceDate).subtract(Duration(days: period.days! - 1));
    final result = reports.where((report) {
      if (siteFilter != null && report.siteId != siteFilter) return false;
      if (start != null && _day(report.date).isBefore(start)) return false;
      return true;
    }).toList();
    result.sort(_newestFirst);
    return result;
  }

  List<DailyReport> get visibleReports {
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    if (tokens.isEmpty) return scopedReports;
    return scopedReports
        .where((report) {
          final haystack = [
            siteName(report.siteId),
            report.weather ?? '',
            report.notes ?? '',
            report.nextDayPlan ?? '',
            ...report.completedTasks,
            ...report.issues,
            apiReportDate(report.date),
          ].join(' ').toLowerCase();
          return tokens.every(haystack.contains);
        })
        .toList(growable: false);
  }

  DailyReport? get latestReport =>
      scopedReports.isEmpty ? null : scopedReports.first;

  int get issueCount =>
      scopedReports.fold(0, (total, report) => total + report.issues.length);

  int get completedWorkCount => scopedReports.fold(
    0,
    (total, report) => total + report.completedTasks.length,
  );

  int get photoCount =>
      scopedReports.fold(0, (total, report) => total + report.media.length);

  int get latestProgress => latestReport?.progress ?? 0;

  int get reportsToday => scopedReports
      .where((report) => _sameDay(report.date, referenceDate))
      .length;

  int get sevenDayCoverage {
    final start = _day(referenceDate).subtract(const Duration(days: 6));
    final days = reports
        .where((report) {
          if (siteFilter != null && report.siteId != siteFilter) return false;
          return !_day(report.date).isBefore(start) &&
              !_day(report.date).isAfter(_day(referenceDate));
        })
        .map((report) => apiReportDate(report.date))
        .toSet()
        .length;
    return ((days / 7) * 100).round();
  }

  List<ReportEvidence> get evidence {
    final values = <ReportEvidence>[];
    for (final report in scopedReports) {
      for (final media in report.media) {
        values.add(
          ReportEvidence(
            report: report,
            media: media,
            siteName: siteName(report.siteId),
          ),
        );
      }
    }
    return values;
  }

  List<ReportTrendPoint> get trend {
    final values = scopedReports
        .map(
          (report) => ReportTrendPoint(
            date: report.date,
            progress: report.progress,
            siteId: report.siteId,
          ),
        )
        .toList();
    values.sort((a, b) => a.date.compareTo(b.date));
    return values;
  }

  List<SiteReportActivity> get siteActivity {
    final activitySites = siteFilter == null
        ? sites
        : sites.where((site) => site.id == siteFilter);
    final values = activitySites.map((site) {
      final siteReports =
          scopedReports.where((report) => report.siteId == site.id).toList()
            ..sort(_newestFirst);
      return SiteReportActivity(
        site: site,
        reportCount: siteReports.length,
        issueCount: siteReports.fold(
          0,
          (total, report) => total + report.issues.length,
        ),
        latestProgress: siteReports.isEmpty
            ? site.progress
            : siteReports.first.progress,
        lastReportAt: siteReports.isEmpty ? null : siteReports.first.date,
      );
    }).toList();
    values.sort((a, b) {
      if (a.lastReportAt == null && b.lastReportAt == null) {
        return a.site.name.compareTo(b.site.name);
      }
      if (a.lastReportAt == null) return 1;
      if (b.lastReportAt == null) return -1;
      return b.lastReportAt!.compareTo(a.lastReportAt!);
    });
    return values;
  }

  bool containsReportFor(String siteId, DateTime date) => reports.any(
    (report) => report.siteId == siteId && _sameDay(report.date, date),
  );

  Map<String, dynamic> toCacheJson() => {
    'reports': reports.map((report) => report.toJson()).toList(growable: false),
    'sites': sites.map((site) => site.toJson()).toList(growable: false),
  };

  ReportsStudioData copyWith({
    List<DailyReport>? reports,
    List<SiteSummary>? sites,
    DateTime? fetchedAt,
    DateTime? referenceDate,
    bool? canCreate,
    bool? isOffline,
    ReportsWorkspace? workspace,
    ReportsPeriod? period,
    String? query,
    String? siteFilter,
    bool clearSite = false,
  }) => ReportsStudioData(
    reports: reports ?? this.reports,
    sites: sites ?? this.sites,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    referenceDate: referenceDate ?? this.referenceDate,
    canCreate: canCreate ?? this.canCreate,
    isOffline: isOffline ?? this.isOffline,
    workspace: workspace ?? this.workspace,
    period: period ?? this.period,
    query: query ?? this.query,
    siteFilter: clearSite ? null : siteFilter ?? this.siteFilter,
  );
}

String apiReportDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

int _newestFirst(DailyReport a, DailyReport b) {
  final date = b.date.compareTo(a.date);
  if (date != 0) return date;
  return (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date);
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value')?.toLocal();
}

String? _nullableString(Object? value) {
  final normalized = '$value'.trim();
  return value == null || normalized.isEmpty || normalized == 'null'
      ? null
      : normalized;
}

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

List<String> _stringList(Object? value) => value is List
    ? _cleanList(value.map((item) => '$item').toList())
    : const [];

List<String> _cleanList(List<String> values) {
  final seen = <String>{};
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
      .toList(growable: false);
}
