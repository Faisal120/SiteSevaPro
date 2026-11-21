import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/sites/models/site_models.dart';
import 'package:siteseva/features/sites/presentation/widgets/site_detail_sections.dart';

void main() {
  test('contractor receives the complete supported site workspace', () {
    expect(siteTabsFor(_user('CONTRACTOR')), SiteWorkspaceTab.values);
  });

  test('supervisor workspace excludes project payments', () {
    expect(
      siteTabsFor(_user('SUPERVISOR')),
      isNot(contains(SiteWorkspaceTab.payments)),
    );
    expect(
      siteTabsFor(_user('SUPERVISOR')),
      contains(SiteWorkspaceTab.attendance),
    );
  });

  test('client workspace exposes only overview, reports, and payments', () {
    expect(siteTabsFor(_user('CLIENT')), [
      SiteWorkspaceTab.overview,
      SiteWorkspaceTab.reports,
      SiteWorkspaceTab.payments,
    ]);
  });

  testWidgets('supervisor overview does not render project finance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SiteOverviewSection(
              site: SiteDetail.fromJson(_detail),
              user: _user('SUPERVISOR'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Approved budget'), findsNothing);
    expect(find.text('Project value'), findsNothing);
    expect(find.text('DELIVERY WINDOW'), findsOneWidget);
  });

  testWidgets('client overview labels backend budget as project value', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SiteOverviewSection(
              site: SiteDetail.fromJson(_detail),
              user: _user('CLIENT'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('PROJECT VALUE'), findsOneWidget);
    expect(find.text('INR 85 L'), findsOneWidget);
  });
}

AuthUser _user(String role) => AuthUser(
  id: 'user-1',
  email: 'user@siteseva.test',
  fullName: 'Site User',
  role: role,
  siteIds: const ['site-1'],
  blocked: false,
);

const _detail = <String, dynamic>{
  'id': 'site-1',
  'company_id': 'company-1',
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
  'name': 'Orchid Residence',
  'location': 'Gurugram',
  'budget': 8500000,
  'start_date': '2026-08-06',
  'end_date': '2027-02-06',
  'status': 'ACTIVE',
  'progress': 64,
  'floors': 3,
  'has_boring': true,
  'has_septic_tank': true,
  'has_soak_pit': true,
  'has_mumty': true,
  'supervisor_ids': ['supervisor-1'],
  'supervisor_names': ['Anita Rao'],
  'client_ids': ['client-1'],
  'client_name': 'Meera Shah',
};
