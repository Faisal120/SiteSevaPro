import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/reports/models/report_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Daily report contracts', () {
    test('parses the complete backend report document', () {
      final report = DailyReport.fromJson(_reportPayload);

      expect(report.id, 'report-1');
      expect(report.siteId, 'site-1');
      expect(report.progress, 64);
      expect(report.weather, 'Cloudy');
      expect(report.completedTasks, ['Slab reinforcement completed']);
      expect(report.issues, ['Concrete delivery delayed by 90 minutes']);
      expect(report.media.single.publicId, 'siteseva/reports/photo-1');
      expect(report.createdBy, 'supervisor-1');
    });

    test('serializes only exact DailyReportIn fields', () {
      final brief =
          DailyReportBrief.initial(
            site: _site,
            referenceDate: DateTime(2026, 8, 7),
          ).copyWith(
            weather: ' Cloudy ',
            notes: ' Slab reinforcement inspected. ',
            completedTasks: [
              'Slab reinforcement completed',
              'slab reinforcement completed',
            ],
            issues: ['Concrete delivery delayed by 90 minutes'],
            nextDayPlan: ' Start slab casting ',
            media: const [
              ReportMedia(
                url: 'https://res.cloudinary.com/site/image/upload/photo.jpg',
                publicId: 'siteseva/reports/photo-1',
                type: 'image',
              ),
            ],
          );

      expect(brief.validationMessage, isNull);
      expect(brief.toApiJson(), {
        'site_id': 'site-1',
        'date': '2026-08-07',
        'progress': 64,
        'weather': 'Cloudy',
        'notes': 'Slab reinforcement inspected.',
        'issues': ['Concrete delivery delayed by 90 minutes'],
        'completed_tasks': ['Slab reinforcement completed'],
        'next_day_plan': 'Start slab casting',
        'media_urls': [
          {
            'url': 'https://res.cloudinary.com/site/image/upload/photo.jpg',
            'public_id': 'siteseva/reports/photo-1',
            'type': 'image',
          },
        ],
      });
    });

    test('rejects empty, future, regressive, and insecure reports', () {
      final empty = DailyReportBrief.initial(
        site: _site,
        referenceDate: DateTime(2026, 8, 7),
      );
      expect(empty.validationMessage, contains('completed work'));
      expect(
        empty.copyWith(date: DateTime(2026, 8, 8)).validationMessage,
        contains('future'),
      );
      expect(
        empty.copyWith(progress: 50, notes: 'Work continued').validationMessage,
        contains('lower'),
      );
      expect(
        empty
            .copyWith(
              notes: 'Work continued',
              media: const [
                ReportMedia(
                  url: 'http://example.test/photo.jpg',
                  type: 'image',
                ),
              ],
            )
            .validationMessage,
        contains('secure'),
      );
    });

    test('validates report photo size and supported extension', () {
      expect(
        ReportPhotoUpload(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'progress.jpg',
        ).validationMessage,
        isNull,
      );
      expect(
        ReportPhotoUpload(
          bytes: Uint8List.fromList([1]),
          filename: 'progress.txt',
        ).validationMessage,
        contains('JPG'),
      );
    });
  });

  group('ReportsStudioData', () {
    test('derives metrics only from returned report records', () {
      final data = _studio();

      expect(data.scopedReports.length, 2);
      expect(data.latestProgress, 64);
      expect(data.issueCount, 1);
      expect(data.completedWorkCount, 2);
      expect(data.photoCount, 1);
      expect(data.reportsToday, 1);
      expect(data.sevenDayCoverage, 29);
      expect(data.siteActivity.first.reportCount, 2);
      expect(data.evidence.single.report.id, 'report-1');
    });

    test('filters by project, period, and searchable report context', () {
      final data = _studio().copyWith(
        siteFilter: 'site-1',
        period: ReportsPeriod.sevenDays,
        query: 'concrete delayed',
      );

      expect(data.visibleReports.single.id, 'report-1');
      expect(data.copyWith(query: 'not present').visibleReports, isEmpty);
      expect(data.copyWith(clearSite: true, query: '').scopedReports.length, 2);
    });

    test('detects an existing site report for the same calendar day', () {
      final data = _studio();

      expect(
        data.containsReportFor('site-1', DateTime(2026, 8, 7, 23)),
        isTrue,
      );
      expect(data.containsReportFor('site-1', DateTime(2026, 8, 6)), isFalse);
    });
  });
}

ReportsStudioData _studio() => ReportsStudioData(
  reports: [
    DailyReport.fromJson(_reportPayload),
    DailyReport.fromJson({
      ..._reportPayload,
      'id': 'report-2',
      'date': '2026-08-05',
      'progress': 60,
      'issues': <String>[],
      'completed_tasks': ['Column shuttering completed'],
      'media_urls': <Map<String, dynamic>>[],
    }),
  ],
  sites: [_site],
  fetchedAt: DateTime(2026, 8, 7, 12),
  referenceDate: DateTime(2026, 8, 7),
  canCreate: true,
);

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

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
  'media_urls': [
    {
      'url': 'https://res.cloudinary.com/site/image/upload/photo.jpg',
      'public_id': 'siteseva/reports/photo-1',
      'type': 'image',
    },
  ],
  'created_by': 'supervisor-1',
  'created_at': '2026-08-07T12:00:00Z',
};
