import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/crm/models/crm_models.dart';

void main() {
  group('CRM models', () {
    test('parses a live overview and separates generic contacts', () {
      final data = CrmWorkspaceData.fromJson({
        'metrics': {
          'lead_count': 3,
          'client_count': 2,
          'vendor_count': 4,
          'follow_up_count': 1,
          'pipeline_amount': 1250000,
          'quotation_count': 2,
        },
        'leads': [
          {
            'id': 'lead-1',
            'full_name': 'Ananya Rao',
            'company_name': 'Rao Developments',
            'status': 'QUALIFIED',
            'estimated_value': 850000,
            'created_at': '2026-08-01T09:00:00Z',
          },
        ],
        'contacts': [
          {'id': 'client-1', 'name': 'Ananya Rao', 'kind': 'CUSTOMER'},
          {'id': 'vendor-1', 'name': 'Buildmart', 'type': 'SUPPLIER'},
        ],
        'follow_ups': [
          {
            'id': 'activity-1',
            'type': 'CALL',
            'subject': 'Confirm site visit',
            'status': 'OPEN',
          },
        ],
        'quotes': [
          {
            'id': 'quote-1',
            'quote_no': 'QT-001',
            'client_name': 'Ananya Rao',
            'grand_total': 420000,
          },
        ],
      });

      expect(data.metrics.pipelineValue, 1250000);
      expect(data.leads.single.stage, CrmLeadStage.qualified);
      expect(data.clients.single.id, 'client-1');
      expect(data.vendors.single.id, 'vendor-1');
      expect(data.activities.single.kind, CrmActivityKind.call);
      expect(data.quotations.single.number, 'QT-001');
      expect(data.apiAvailable, isTrue);
    });

    test('searches only the selected CRM workspace', () {
      final data = CrmWorkspaceData.fromJson({
        'leads': [
          {
            'id': 'lead-1',
            'name': 'Neha Sharma',
            'company': 'Northstar Homes',
          },
          {'id': 'lead-2', 'name': 'Ravi Kumar', 'company': 'Buildline'},
        ],
      });

      expect(
        data.copyWith(query: 'northstar').visibleRecords.single,
        isA<CrmLead>(),
      );
      expect(data.copyWith(query: 'missing').visibleRecords, isEmpty);
      expect(
        data.copyWith(workspace: CrmWorkspace.clients).visibleRecords,
        isEmpty,
      );
    });

    test('serializes write contracts without sending empty optional strings', () {
      const lead = CrmLeadInput(
        name: 'Neha Sharma',
        company: 'Northstar Homes',
        email: '',
        phone: '9876543210',
        source: '',
        value: 750000,
      );
      const activity = CrmActivityInput(
        kind: CrmActivityKind.followUp,
        title: 'Call client',
        description: '',
        contactId: '',
        scheduledAt: null,
      );

      expect(lead.toJson(), {
        'name': 'Neha Sharma',
        'company': 'Northstar Homes',
        'email': null,
        'phone': '9876543210',
        'source': null,
        'estimated_value': 750000,
      });
      expect(activity.toJson(), {
        'kind': 'FOLLOWUP',
        'title': 'Call client',
        'description': null,
        'contact_id': null,
        'scheduled_at': null,
      });
    });

    test('keeps the unavailable state explicit and role permissions narrow', () {
      final unavailable = CrmWorkspaceData.unavailable(
        fetchedAt: DateTime(2026, 8, 8),
      );

      expect(unavailable.apiAvailable, isFalse);
      expect(unavailable.visibleRecords, isEmpty);
      expect(CrmPermissions(role: 'CONTRACTOR').canWriteQuotations, isTrue);
      expect(CrmPermissions(role: 'SUPERVISOR').canWriteActivities, isTrue);
      expect(CrmPermissions(role: 'SUPERVISOR').canWriteLeads, isFalse);
      expect(CrmPermissions(role: 'CLIENT').canWriteActivities, isFalse);
    });
  });
}
