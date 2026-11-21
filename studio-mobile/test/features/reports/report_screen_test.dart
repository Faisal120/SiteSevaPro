import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/reports/models/report_models.dart';
import 'package:siteseva/features/reports/presentation/screens/report_detail_screen.dart';
import 'package:siteseva/features/reports/presentation/screens/reports_screen.dart';
import 'package:siteseva/features/reports/providers/reports_provider.dart';
import 'package:siteseva/features/reports/repository/reports_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets('desktop report logbook renders live field intelligence', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      data: _studio,
      child: const ReportsScreen(),
    );

    expect(find.text('Daily Reports'), findsOneWidget);
    expect(find.text('VERIFIED FIELD RECORD'), findsOneWidget);
    expect(find.text('Logbook'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Evidence'), findsOneWidget);
    expect(find.text('Orchid Residence'), findsWidgets);
    expect(
      find.text('Slab reinforcement inspected before casting.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Create daily report'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('mobile report logbook settles without responsive overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      data: _studio,
      child: const ReportsScreen(),
    );

    expect(find.text('Daily Reports'), findsOneWidget);
    expect(find.textContaining('Every site day'), findsOneWidget);
    expect(find.text('64%'), findsWidgets);
    _expectNoFlutterException(tester);
  });

  testWidgets('insights workspace renders only derived report metrics', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1000),
      data: _studio.copyWith(workspace: ReportsWorkspace.insights),
      child: const ReportsScreen(),
    );

    expect(find.text('Reported progress'), findsOneWidget);
    expect(find.text('Project activity'), findsOneWidget);
    expect(find.text('Issue register'), findsOneWidget);
    expect(find.text('ISSUE MENTIONS'), findsOneWidget);
    expect(find.text('PHOTO EVIDENCE'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('client review mode hides report creation controls', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      data: _studio.copyWith(canCreate: false),
      child: const ReportsScreen(),
    );

    expect(find.text('Orchid Residence'), findsWidgets);
    expect(find.byTooltip('Create daily report'), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('report detail renders immutable narrative and field record', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1100),
      data: _studio,
      child: const ReportDetailScreen(reportId: 'report-1'),
    );

    expect(find.text('Report Detail'), findsOneWidget);
    expect(find.text('DAILY FIELD RECORD  |  7 AUG 2026'), findsOneWidget);
    expect(find.text('Site narrative'), findsOneWidget);
    expect(find.text('Record identity'), findsOneWidget);
    expect(find.text('Completed work'), findsOneWidget);
    expect(find.text('Issues recorded'), findsOneWidget);
    expect(find.textContaining('Immutable field record'), findsOneWidget);
    _expectNoFlutterException(tester);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required ReportsStudioData data,
  required Widget child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportsRepositoryProvider.overrideWithValue(_repository),
        reportsStudioControllerProvider.overrideWith(
          (ref) => _LoadedReportsController(data, _repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 900));
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
}

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

final _report = DailyReport.fromJson({
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
});

final _studio = ReportsStudioData(
  reports: [_report],
  sites: [_site],
  fetchedAt: DateTime(2026, 8, 7, 12),
  referenceDate: DateTime(2026, 8, 7),
  canCreate: true,
);

const _repository = _FakeReportsRepository();

class _LoadedReportsController extends ReportsStudioController {
  _LoadedReportsController(ReportsStudioData data, ReportsRepository repository)
    : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _FakeReportsRepository implements ReportsRepository {
  const _FakeReportsRepository();

  @override
  Future<DailyReport> createReport(DailyReportBrief brief) async => _report;

  @override
  Future<ReportsStudioData> fetchStudio() async => _studio;

  @override
  Future<ReportMedia> uploadPhoto(ReportPhotoUpload upload) async =>
      const ReportMedia(
        url: 'https://res.cloudinary.com/site/image/upload/photo.jpg',
        type: 'image',
      );
}
