import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/reports/data/reports_cache.dart';
import 'package:siteseva/features/reports/data/reports_remote_data_source.dart';
import 'package:siteseva/features/reports/data/reports_repository_impl.dart';
import 'package:siteseva/features/reports/models/report_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('ReportsRepositoryImpl', () {
    test('loads and caches the contractor report workspace', () async {
      final remote = _FakeReportsRemote();
      final cache = _MemoryReportsCache();
      final repository = _repository(remote: remote, cache: cache);

      final data = await repository.fetchStudio();

      expect(data.reports.single.id, 'report-1');
      expect(data.sites.single.name, 'Orchid Residence');
      expect(data.canCreate, isTrue);
      expect(remote.unscopedReportRequests, 1);
      expect(cache.studios['user-1'], isNotNull);
    });

    test(
      'supervisor/client fetch reports per assigned site and filter leaks',
      () async {
        final remote = _FakeReportsRemote(
          sites: [_sitePayload, _secondSitePayload],
          includeUnassignedReport: true,
        );
        final repository = _repository(
          remote: remote,
          cache: _MemoryReportsCache(),
          restrict: true,
        );

        final data = await repository.fetchStudio();

        expect(remote.unscopedReportRequests, 0);
        expect(remote.siteReportRequests, ['site-1', 'site-2']);
        expect(
          data.reports.map((item) => item.siteId),
          isNot(contains('site-x')),
        );
      },
    );

    test('uses cached reports only for connectivity failures', () async {
      final cache = _MemoryReportsCache()
        ..studios['user-1'] = CachedReportsStudio(
          payload: {
            'sites': [_sitePayload],
            'reports': [_reportPayload],
          },
          cachedAt: DateTime(2026, 8, 7, 8),
        );
      final repository = _repository(
        remote: _FakeReportsRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      );

      final data = await repository.fetchStudio();

      expect(data.isOffline, isTrue);
      expect(data.reports.single.id, 'report-1');
      expect(data.fetchedAt, DateTime(2026, 8, 7, 8));
    });

    test('does not hide authorization errors behind cached reports', () async {
      final cache = _MemoryReportsCache()
        ..studios['user-1'] = CachedReportsStudio(
          payload: {
            'sites': [_sitePayload],
            'reports': [_reportPayload],
          },
          cachedAt: DateTime(2026, 8, 7),
        );
      final repository = _repository(
        remote: _FakeReportsRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
      );

      expect(repository.fetchStudio(), throwsA(isA<ApiException>()));
    });

    test(
      'validates assignment and submits exact DailyReportIn payload',
      () async {
        final remote = _FakeReportsRemote(reports: const []);
        final repository = _repository(
          remote: remote,
          cache: _MemoryReportsCache(),
        );
        final brief =
            DailyReportBrief.initial(
              site: SiteSummary.fromJson(_sitePayload),
              referenceDate: DateTime(2026, 8, 7),
            ).copyWith(
              notes: 'Slab reinforcement inspected before casting.',
              completedTasks: ['Slab reinforcement completed'],
            );

        final created = await repository.createReport(brief);

        expect(created.id, 'report-created');
        expect(remote.lastCreatedReport, brief.toApiJson());
        expect(
          repository.createReport(brief.copyWith(siteId: 'site-unknown')),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test(
      'blocks duplicate day and progress regression before mutation',
      () async {
        final duplicateRepository = _repository(
          remote: _FakeReportsRemote(),
          cache: _MemoryReportsCache(),
        );
        final brief = _validBrief();

        expect(
          duplicateRepository.createReport(brief),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'code',
              409,
            ),
          ),
        );
        final regressionRemote = _FakeReportsRemote(reports: const []);
        final regressionRepository = _repository(
          remote: regressionRemote,
          cache: _MemoryReportsCache(),
        );
        expect(
          regressionRepository.createReport(brief.copyWith(progress: 50)),
          throwsA(isA<ApiException>()),
        );
        expect(regressionRemote.lastCreatedReport, isNull);
      },
    );

    test('uploads photo through the signed media contract', () async {
      final remote = _FakeReportsRemote();
      final repository = _repository(
        remote: remote,
        cache: _MemoryReportsCache(),
      );
      final upload = ReportPhotoUpload(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'progress.jpg',
      );

      final media = await repository.uploadPhoto(upload);

      expect(media.url, startsWith('https://'));
      expect(remote.lastUpload?.filename, 'progress.jpg');
    });

    test(
      'client can view assigned reports but cannot create or upload',
      () async {
        final repository = _repository(
          remote: _FakeReportsRemote(),
          cache: _MemoryReportsCache(),
          canCreate: false,
          restrict: true,
        );

        final data = await repository.fetchStudio();

        expect(data.canCreate, isFalse);
        expect(
          repository.createReport(_validBrief()),
          throwsA(isA<ApiException>()),
        );
        expect(
          repository.uploadPhoto(
            ReportPhotoUpload(
              bytes: Uint8List.fromList([1]),
              filename: 'photo.jpg',
            ),
          ),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });
}

ReportsRepositoryImpl _repository({
  required ReportsRemoteDataSource remote,
  required ReportsCache cache,
  bool canView = true,
  bool canCreate = true,
  bool restrict = false,
}) => ReportsRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'user-1',
  canView: canView,
  canCreate: canCreate,
  restrictToAssignedSites: restrict,
  clock: () => DateTime(2026, 8, 7, 12),
);

DailyReportBrief _validBrief() =>
    DailyReportBrief.initial(
      site: SiteSummary.fromJson(_sitePayload),
      referenceDate: DateTime(2026, 8, 7),
    ).copyWith(
      notes: 'Slab reinforcement inspected before casting.',
      completedTasks: ['Slab reinforcement completed'],
    );

class _FakeReportsRemote implements ReportsRemoteDataSource {
  _FakeReportsRemote({
    this.error,
    this.sites = const [_sitePayload],
    this.reports = const [_reportPayload],
    this.includeUnassignedReport = false,
  });

  final ApiException? error;
  final List<Map<String, dynamic>> sites;
  final List<Map<String, dynamic>> reports;
  final bool includeUnassignedReport;
  int unscopedReportRequests = 0;
  final siteReportRequests = <String>[];
  Map<String, dynamic>? lastCreatedReport;
  ReportPhotoUpload? lastUpload;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastCreatedReport = payload;
    return {
      'id': 'report-created',
      'company_id': 'company-1',
      'created_by': 'user-1',
      'created_at': '2026-08-07T12:00:00Z',
      ...payload,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReports({String? siteId}) async {
    _throwIfNeeded();
    if (siteId == null) {
      unscopedReportRequests++;
    } else {
      siteReportRequests.add(siteId);
    }
    final values = reports
        .where((report) => siteId == null || report['site_id'] == siteId)
        .map(Map<String, dynamic>.from)
        .toList();
    if (includeUnassignedReport) {
      values.add({..._reportPayload, 'id': 'report-x', 'site_id': 'site-x'});
    }
    return values;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return sites.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<Map<String, dynamic>> uploadPhoto(ReportPhotoUpload upload) async {
    _throwIfNeeded();
    lastUpload = upload;
    return {
      'secure_url': 'https://res.cloudinary.com/site/image/upload/photo.jpg',
      'public_id': 'siteseva/reports/photo-1',
      'resource_type': 'image',
    };
  }
}

class _MemoryReportsCache implements ReportsCache {
  final studios = <String, CachedReportsStudio>{};

  @override
  Future<CachedReportsStudio?> readStudio(String userId) async =>
      studios[userId];

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedReportsStudio(
      payload: payload,
      cachedAt: DateTime(2026, 8, 7, 12),
    );
  }
}

const _sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const _secondSitePayload = <String, dynamic>{
  'id': 'site-2',
  'name': 'Aster Heights',
  'location': 'Noida, Uttar Pradesh',
  'status': 'ACTIVE',
  'progress': 35,
};

const _reportPayload = <String, dynamic>{
  'id': 'report-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'date': '2026-08-07',
  'progress': 64,
  'weather': 'Cloudy',
  'notes': 'Slab reinforcement inspected before casting.',
  'issues': ['Concrete delivery delayed by 90 minutes'],
  'completed_tasks': ['Slab reinforcement completed'],
  'next_day_plan': 'Start slab casting at 7 AM.',
  'media_urls': <Map<String, dynamic>>[],
  'created_by': 'supervisor-1',
  'created_at': '2026-08-07T12:00:00Z',
};
