import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/dashboard/models/dashboard_data.dart';
import 'package:siteseva/features/dashboard/models/dashboard_experience.dart';

void main() {
  test('parses role-specific collections without fabricated defaults', () {
    final dashboard = DashboardData.fromJson({
      'company': {'name': 'SiteSeva Company'},
      'stats': {'total_sites': 1, 'active_sites': 1},
      'sites': [
        {
          'id': 'site-1',
          'name': 'Live Project',
          'location': 'Delhi',
          'status': 'IN_PROGRESS',
          'progress': 37.5,
        },
      ],
      'todayAttendance': [
        {'id': 'a-1', 'status': 'PRESENT', 'labour_name': 'Worker One'},
        {'id': 'a-2', 'status': 'ABSENT', 'labour_name': 'Worker Two'},
      ],
    });

    expect(dashboard.stats.totalSites, 1);
    expect(dashboard.todayPresent, 1);
    expect(dashboard.payments, isEmpty);
    expect(dashboard.photos, isEmpty);
  });

  test(
    'derives progress chart only from real site progress when chart is absent',
    () {
      final dashboard = DashboardData.fromJson({
        'sites': [
          {'id': 'site-1', 'name': 'Site One', 'progress': 28},
          {'id': 'site-2', 'name': 'Site Two', 'progress': 76},
        ],
      });

      expect(dashboard.projectProgress, hasLength(2));
      expect(dashboard.projectProgress.last.progress, 76);
    },
  );

  test('clamps invalid progress values to the supported chart range', () {
    final dashboard = DashboardData.fromJson({
      'sites': [
        {'id': 'site-1', 'name': 'Site One', 'progress': 140},
      ],
      'charts': {
        'site_progress': [
          {'name': 'Site One', 'progress': -20},
        ],
      },
    });

    expect(dashboard.sites.single.progress, 100);
    expect(dashboard.projectProgress.single.progress, 0);
  });

  test('parses backend campaigns and rejects untrusted action URLs', () {
    final dashboard = DashboardData.fromJson({
      'campaigns': [
        {
          'id': 'campaign-safe',
          'title': 'Open site portfolio',
          'action_key': 'SITES',
          'roles': ['CONTRACTOR'],
        },
        {
          'id': 'campaign-unsafe',
          'title': 'Untrusted destination',
          'action_url': 'https://example.com/collect-token',
        },
      ],
    });

    expect(dashboard.campaigns.first.actionPath, '/sites');
    expect(dashboard.campaigns.last.actionPath, isNull);
    expect(dashboard.campaigns.first.supportsRole('CONTRACTOR'), isTrue);
    expect(dashboard.campaigns.first.supportsRole('CLIENT'), isFalse);
  });

  test('role experience exposes only authorized feature destinations', () {
    final contractor = DashboardExperience.featuresFor('CONTRACTOR');
    final supervisor = DashboardExperience.featuresFor('SUPERVISOR');
    final client = DashboardExperience.featuresFor('CLIENT');

    expect(contractor.map((item) => item.path), contains('/expenses'));
    expect(supervisor.map((item) => item.path), isNot(contains('/payments')));
    expect(client.map((item) => item.path), isNot(contains('/attendance')));
  });

  test('portfolio insights use real progress and deadline records', () {
    final dashboard = DashboardData.fromJson({
      'stats': {'active_sites': 2, 'today_labours': 8},
      'sites': [
        {
          'id': 'site-1',
          'progress': 40,
          'end_date': '2026-08-20',
          'status': 'ACTIVE',
        },
        {
          'id': 'site-2',
          'progress': 80,
          'end_date': '2027-02-20',
          'status': 'ACTIVE',
        },
      ],
    });

    final insights = DashboardExperience.insightsFor(
      dashboard,
      'CONTRACTOR',
      DateTime(2026, 8, 7),
    );

    expect(insights.first.value, '60%');
    expect(
      insights
          .singleWhere((item) => item.kind == DashboardInsightKind.deadline)
          .value,
      '1',
    );
  });
}
