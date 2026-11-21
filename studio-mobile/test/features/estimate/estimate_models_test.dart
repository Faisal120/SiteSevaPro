import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/estimate/models/estimate_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Estimate models', () {
    test('parses the live estimate calculation response contract', () {
      final document = EstimateDocument.fromJson(estimatePayload);

      expect(document.name, 'Orchid Premium Feasibility');
      expect(document.input.plotAreaSqft, 2400);
      expect(document.input.basement, isTrue);
      expect(document.builtupSqft, 6840);
      expect(document.quality, EstimateQuality.premium);
      expect(document.materials.lines, hasLength(5));
      expect(document.materials.steelKg, 30096);
      expect(document.calculatedTotal, 8500000);
      expect(document.hasCostMismatch, isFalse);
      expect(document.isIssued, isTrue);
    });

    test('falls back to input quality and flags inconsistent cost totals', () {
      final document = EstimateDocument.fromJson({
        ...estimatePayload,
        'quality_band': null,
        'overhead': 1100000,
      });

      expect(document.quality, EstimateQuality.premium);
      expect(document.hasCostMismatch, isTrue);
      expect(document.total, 8500000);
    });

    test('serializes the exact EstimateIn request shape', () {
      const brief = EstimateBrief(
        siteId: 'site-1',
        name: 'Orchid Premium Feasibility',
        plotAreaSqft: 2400,
        floors: 2,
        basement: true,
        constructionType: EstimateConstructionType.residential,
        quality: EstimateQuality.premium,
        budget: 8500000,
      );

      expect(brief.toApiJson(), {
        'site_id': 'site-1',
        'name': 'Orchid Premium Feasibility',
        'plot_area_sqft': 2400,
        'floors': 2,
        'basement': true,
        'construction_type': 'RESIDENTIAL',
        'quality': 'PREMIUM',
        'budget': 8500000,
      });
      expect(brief.validationMessage, isNull);
    });

    test('validates site, geometry, floor, and budget inputs', () {
      expect(
        EstimateBrief.initial().validationMessage,
        'Choose the project site.',
      );
      final missingName = EstimateBrief.initial().copyWith(siteId: 'site-1');
      expect(missingName.validationMessage, 'Enter an estimate name.');
      final invalidArea = missingName.copyWith(name: 'Plan');
      expect(invalidArea.validationMessage, 'Enter a valid plot area.');
      final invalidFloors = invalidArea.copyWith(plotAreaSqft: 1000, floors: 0);
      expect(
        invalidFloors.validationMessage,
        'Enter between 1 and 200 floors.',
      );
      final invalidBudget = invalidFloors.copyWith(floors: 1);
      expect(invalidBudget.validationMessage, 'Enter a valid project budget.');
    });

    test('filters the live portfolio and derives server-backed metrics', () {
      final document = EstimateDocument.fromJson(estimatePayload);
      final data = EstimateStudioData(
        estimates: [document],
        sites: [SiteSummary.fromJson(sitePayload)],
        branding: EstimateBranding.fromJson(brandingPayload),
        fetchedAt: DateTime(2026, 8, 6),
      );

      expect(data.copyWith(query: 'Gurugram').visibleEstimates, [document]);
      expect(data.copyWith(query: 'Premium').visibleEstimates, [document]);
      expect(
        data.copyWith(qualityFilter: EstimateQuality.economy).visibleEstimates,
        isEmpty,
      );
      expect(
        data.copyWith(siteFilter: 'site-hidden').visibleEstimates,
        isEmpty,
      );
      expect(data.portfolioValue, 8500000);
      expect(data.averageRate, 1242.69);
      expect(data.linkedSiteCount, 1);
      expect(data.branding.hasSignature, isTrue);
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

const brandingPayload = <String, dynamic>{
  'company_name': 'Buildcraft Projects',
  'email': 'projects@buildcraft.test',
  'phone': '9876543210',
  'gst_number': '06ABCDE1234F1Z5',
  'signature': 'https://cdn.example.test/signature.png',
  'address': 'Sector 57, Gurugram',
};

const estimatePayload = <String, dynamic>{
  'id': 'estimate-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'name': 'Orchid Premium Feasibility',
  'input': {
    'site_id': 'site-1',
    'name': 'Orchid Premium Feasibility',
    'plot_area_sqft': 2400,
    'floors': 2,
    'basement': true,
    'construction_type': 'RESIDENTIAL',
    'quality': 'PREMIUM',
    'budget': 8500000,
  },
  'builtup_sqft': 6840,
  'rate_per_sqft': 1242.69,
  'quality_band': 'PREMIUM',
  'type_factor': 1,
  'materials': {
    'cement_bags': 2900.16,
    'steel_kg': 30096,
    'sand_cft': 5814,
    'aggregate_cft': 4446,
    'bricks_pcs': 54720,
  },
  'material_cost': 5100000,
  'labour_cost': 2210000,
  'overhead': 1190000,
  'total': 8500000,
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
};
