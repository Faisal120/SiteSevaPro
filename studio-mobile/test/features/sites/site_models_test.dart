import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Site models', () {
    test('parses summary fields and clamps progress', () {
      final site = SiteSummary.fromJson({
        'id': 'site-1',
        'name': 'Orchid Residence',
        'location': 'Gurugram',
        'status': 'ON_HOLD',
        'progress': 140,
        'supervisor_names': ['Anita Rao'],
        'client_name': 'Meera Shah',
      });

      expect(site.status, SiteStatus.onHold);
      expect(site.progress, 100);
      expect(site.supervisorNames, ['Anita Rao']);
      expect(site.clientName, 'Meera Shah');
    });

    test('filters only by values returned in the site summary', () {
      final collection = SiteCollection(
        sites: [
          SiteSummary.fromJson({
            'id': 'one',
            'name': 'Orchid Residence',
            'location': 'Gurugram',
            'status': 'ACTIVE',
            'progress': 64,
            'client_name': 'Meera Shah',
          }),
          SiteSummary.fromJson({
            'id': 'two',
            'name': 'Aravali Hub',
            'location': 'Faridabad',
            'status': 'COMPLETED',
            'progress': 100,
          }),
        ],
        fetchedAt: DateTime(2026, 8, 6),
        query: 'meera',
        filter: SiteStatus.active,
      );

      expect(collection.visibleSites.single.id, 'one');
      expect(collection.count(SiteStatus.completed), 1);
      expect(collection.averageProgress, 82);
    });

    test('emits the complete existing SiteIn API contract', () {
      final mutation = SiteMutation(
        name: '  Orchid Residence  ',
        location: '  Gurugram  ',
        budget: 8500000,
        startDate: DateTime(2026, 8, 6),
        endDate: DateTime(2027, 2, 6),
        description: '  Residential build  ',
        coverImage: '',
        floors: 3,
        hasBoring: true,
        hasSepticTank: true,
        hasSoakPit: false,
        hasMumty: true,
        supervisorIds: const ['supervisor-1'],
        clientId: 'client-1',
        status: SiteStatus.planning,
        progress: 120,
      );

      expect(mutation.toApiJson(), {
        'name': 'Orchid Residence',
        'location': 'Gurugram',
        'budget': 8500000,
        'start_date': '2026-08-06',
        'end_date': '2027-02-06',
        'description': 'Residential build',
        'cover_image': null,
        'floors': 3,
        'has_boring': true,
        'has_septic_tank': true,
        'has_soak_pit': false,
        'has_mumty': true,
        'supervisor_ids': ['supervisor-1'],
        'client_id': 'client-1',
        'status': 'PLANNING',
        'progress': 100,
      });
    });

    test('keeps team roles explicit for site assignment controls', () {
      final supervisor = SiteAssignee.fromJson({
        'id': 'supervisor-1',
        'full_name': 'Rohan Singh',
        'email': 'rohan@siteseva.test',
        'role': 'SUPERVISOR',
      });
      final client = SiteAssignee.fromJson({
        'id': 'client-1',
        'name': 'Kapoor Family',
        'role': 'CLIENT',
      });

      expect(supervisor.isSupervisor, isTrue);
      expect(supervisor.isClient, isFalse);
      expect(client.isClient, isTrue);
      expect(client.displayName, 'Kapoor Family');
    });
  });
}
