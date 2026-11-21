import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/boq/models/boq_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('BOQ models', () {
    test('parses the live section and line-item response contract', () {
      final document = BoqDocument.fromJson(boqPayload);

      expect(document.name, 'Orchid Residence Tender BOQ');
      expect(document.sections, hasLength(2));
      expect(document.itemCount, 3);
      expect(document.total, 433000);
      expect(document.sections.first.items.first.quantity, 12);
      expect(document.sections.first.items.first.calculatedAmount, 78000);
      expect(document.rateMismatchCount, 0);
      expect(document.isIssued, isTrue);
    });

    test('flags inconsistent server line amounts without changing them', () {
      final document = BoqDocument.fromJson({
        ...boqPayload,
        'sections': [
          {
            'name': 'Foundation',
            'subtotal': 78001,
            'items': [
              {
                'desc': 'PCC bed',
                'unit': 'cum',
                'qty': 12,
                'rate': 6500,
                'amount': 78001,
              },
            ],
          },
        ],
      });

      expect(document.rateMismatchCount, 1);
      expect(document.sections.single.items.single.amount, 78001);
    });

    test('serializes estimate-linked generation without measured area', () {
      const brief = BoqGenerationBrief(
        name: 'Estimate BOQ',
        siteId: 'site-1',
        source: BoqGenerationSource.estimate,
        estimateId: 'estimate-1',
        builtupSqft: 0,
      );

      final json = brief.toApiJson();

      expect(json['name'], 'Estimate BOQ');
      expect(json['site_id'], 'site-1');
      expect(json['estimate_id'], 'estimate-1');
      expect(json.containsKey('builtup_sqft'), isFalse);
      expect(brief.validationMessage, isNull);
    });

    test('serializes measured area without an estimate id', () {
      const brief = BoqGenerationBrief(
        name: 'Measured BOQ',
        siteId: 'site-1',
        source: BoqGenerationSource.measuredArea,
        estimateId: '',
        builtupSqft: 4650,
      );

      final json = brief.toApiJson();

      expect(json['builtup_sqft'], 4650);
      expect(json.containsKey('estimate_id'), isFalse);
      expect(brief.validationMessage, isNull);
    });

    test('filters issued BOQs by project, location, source, and site', () {
      final document = BoqDocument.fromJson(boqPayload);
      final data = BoqStudioData(
        boqs: [document],
        sites: [SiteSummary.fromJson(sitePayload)],
        estimates: [BoqEstimateSummary.fromJson(estimatePayload)],
        vendors: const [],
        fetchedAt: DateTime(2026, 8, 6),
      );

      expect(data.copyWith(query: 'Gurugram').visibleBoqs, [document]);
      expect(data.copyWith(query: 'Approved').visibleBoqs, [document]);
      expect(data.copyWith(siteFilter: 'site-hidden').visibleBoqs, isEmpty);
      expect(data.documentedValue, 433000);
      expect(data.linkedSiteCount, 1);
    });
  });
}

const sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const estimatePayload = <String, dynamic>{
  'id': 'estimate-1',
  'site_id': 'site-1',
  'name': 'Approved Premium Estimate',
  'builtup_sqft': 4650,
  'total': 8500000,
  'quality_band': 'PREMIUM',
  'created_at': '2026-08-05T09:00:00Z',
};

const vendorPayload = <String, dynamic>{
  'id': 'vendor-1',
  'name': 'Shree Buildmart',
  'contact': '9876543210',
  'gst': '06ABCDE1234F1Z5',
  'categories': ['Cement', 'Steel'],
};

const boqPayload = <String, dynamic>{
  'id': 'boq-1',
  'company_id': 'company-1',
  'estimate_id': 'estimate-1',
  'site_id': 'site-1',
  'name': 'Orchid Residence Tender BOQ',
  'builtup_sqft': 4650,
  'sections': [
    {
      'name': 'Foundation',
      'subtotal': 142000,
      'items': [
        {
          'desc': 'PCC bed',
          'unit': 'cum',
          'qty': 12,
          'rate': 6500,
          'amount': 78000,
        },
        {
          'desc': 'Earthwork excavation',
          'unit': 'cum',
          'qty': 200,
          'rate': 320,
          'amount': 64000,
        },
      ],
    },
    {
      'name': 'RCC Work',
      'subtotal': 291000,
      'items': [
        {
          'desc': 'Columns and beams',
          'unit': 'cum',
          'qty': 30,
          'rate': 9700,
          'amount': 291000,
        },
      ],
    },
  ],
  'total': 433000,
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
};
