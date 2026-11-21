import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/materials/models/material_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Material contracts', () {
    test('parses stock health and computes server-backed valuation', () {
      final healthy = MaterialItem.fromJson(_cementPayload);
      final low = MaterialItem.fromJson({..._cementPayload, 'stock': 10});
      final depleted = MaterialItem.fromJson({..._cementPayload, 'stock': 0});

      expect(healthy.health, StockHealth.healthy);
      expect(healthy.stockValue, 46200);
      expect(low.health, StockHealth.low);
      expect(depleted.health, StockHealth.depleted);
    });

    test('serializes the exact MaterialIn contract', () {
      const brief = MaterialCreationBrief(
        siteId: 'site-1',
        name: '  OPC 53 Grade Cement ',
        category: MaterialCategory.cement,
        unit: ' bags ',
        openingStock: 84,
        lowStockThreshold: 10,
        rate: 550,
      );

      expect(brief.validationMessage, isNull);
      expect(brief.toApiJson(), {
        'site_id': 'site-1',
        'name': 'OPC 53 Grade Cement',
        'category': 'Cement',
        'unit': 'bags',
        'stock': 84.0,
        'low_stock_threshold': 10.0,
        'rate': 550.0,
      });
      expect(
        brief.copyWith(openingStock: -1).validationMessage,
        contains('cannot be negative'),
      );
    });

    test('serializes exact inward transaction and optional fields', () {
      final material = MaterialItem.fromJson(_cementPayload);
      final brief = MaterialMovementBrief.initial(material).copyWith(
        quantity: 50,
        rate: 565,
        vendor: 'Shree Cement Supply',
        note: 'Gate receipt GR-108',
        invoiceUrl: 'https://cdn.example.test/invoice-108.pdf',
      );

      expect(brief.validationMessage, isNull);
      expect(brief.toApiJson(), {
        'material_id': 'material-1',
        'site_id': 'site-1',
        'type': 'INWARD',
        'quantity': 50.0,
        'rate': 565.0,
        'vendor': 'Shree Cement Supply',
        'note': 'Gate receipt GR-108',
        'invoice_url': 'https://cdn.example.test/invoice-108.pdf',
      });
    });

    test('outward transaction strips receipt fields and protects stock', () {
      final material = MaterialItem.fromJson(_cementPayload);
      final valid = MaterialMovementBrief.initial(material).copyWith(
        type: MaterialMovementType.outward,
        quantity: 20,
        vendor: 'Must not leave device payload',
        invoiceUrl: 'https://cdn.example.test/unused.pdf',
        note: 'Issued to slab casting team',
      );
      final invalid = valid.copyWith(quantity: 85);

      expect(valid.validationMessage, isNull);
      expect(valid.toApiJson(), {
        'material_id': 'material-1',
        'site_id': 'site-1',
        'type': 'OUTWARD',
        'quantity': 20.0,
        'rate': null,
        'vendor': null,
        'note': 'Issued to slab casting team',
        'invoice_url': null,
      });
      expect(invalid.validationMessage, contains('available stock'));
    });

    test('validates and serializes exact VendorIn fields', () {
      const brief = MaterialVendorBrief(
        name: ' Shree Cement Supply ',
        contact: '9876543210',
        gst: '06abcde1234f1z5',
        address: 'Gurugram, Haryana',
        paymentTerms: 'Net 30 days',
        categories: ['Cement', 'Sand'],
      );

      expect(brief.validationMessage, isNull);
      expect(brief.toApiJson(), {
        'name': 'Shree Cement Supply',
        'contact': '9876543210',
        'gst': '06ABCDE1234F1Z5',
        'address': 'Gurugram, Haryana',
        'payment_terms': 'Net 30 days',
        'categories': ['Cement', 'Sand'],
      });
    });
  });

  group('Materials workspace intelligence', () {
    test('derives portfolio metrics exclusively from endpoint records', () {
      final data = _studio();

      expect(data.materials.length, 2);
      expect(data.lowStockCount, 1);
      expect(data.depletedCount, 0);
      expect(data.stockValue, 67000);
      expect(data.inwardValue, 28250);
      expect(data.stockedSiteCount, 2);
    });

    test('supports token search, project, category and low stock filters', () {
      final searched = _studio().copyWith(query: 'orchid cement');
      final filtered = _studio().copyWith(
        siteFilter: 'site-2',
        categoryFilter: MaterialCategory.steel,
        lowStockOnly: true,
      );

      expect(searched.visibleMaterials.single.id, 'material-1');
      expect(filtered.visibleMaterials.single.id, 'material-2');
      expect(
        filtered.copyWith(clearSite: true).visibleMaterials.single.id,
        'material-2',
      );
    });

    test('joins movement and vendor search with material context', () {
      final movementData = _studio().copyWith(
        workspace: MaterialsWorkspace.movements,
        query: 'cement gate',
      );
      final vendorData = _studio().copyWith(
        workspace: MaterialsWorkspace.vendors,
        query: 'cement 06abc',
      );

      expect(movementData.visibleMovements.single.id, 'movement-1');
      expect(vendorData.visibleVendors.single.id, 'vendor-1');
      expect(movementData.movementsFor('material-1').length, 1);
    });
  });
}

MaterialsStudioData _studio() => MaterialsStudioData(
  materials: [
    MaterialItem.fromJson(_cementPayload),
    MaterialItem.fromJson(_steelPayload),
  ],
  movements: [MaterialMovement.fromJson(_movementPayload)],
  vendors: [MaterialVendor.fromJson(_vendorPayload)],
  sites: [_site, _secondSite],
  fetchedAt: DateTime(2026, 8, 6),
  canManageVendors: true,
);

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});
final _secondSite = SiteSummary.fromJson({
  'id': 'site-2',
  'name': 'Lakeview Villas',
  'location': 'Noida Extension',
  'status': 'ACTIVE',
  'progress': 39,
});

const _cementPayload = <String, dynamic>{
  'id': 'material-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'name': 'OPC 53 Grade Cement',
  'category': 'Cement',
  'unit': 'bags',
  'stock': 84,
  'low_stock_threshold': 10,
  'rate': 550,
  'created_at': '2026-08-01T08:00:00Z',
};

const _steelPayload = <String, dynamic>{
  'id': 'material-2',
  'company_id': 'company-1',
  'site_id': 'site-2',
  'name': 'TMT Fe 500D Steel',
  'category': 'Steel',
  'unit': 'kg',
  'stock': 8,
  'low_stock_threshold': 10,
  'rate': 2600,
  'created_at': '2026-08-02T08:00:00Z',
};

const _movementPayload = <String, dynamic>{
  'id': 'movement-1',
  'company_id': 'company-1',
  'material_id': 'material-1',
  'site_id': 'site-1',
  'type': 'INWARD',
  'quantity': 50,
  'rate': 565,
  'vendor': 'Shree Cement Supply',
  'note': 'Gate receipt GR-108',
  'invoice_url': 'https://cdn.example.test/invoice-108.pdf',
  'created_by': 'supervisor-1',
  'created_at': '2026-08-06T09:30:00Z',
};

const _vendorPayload = <String, dynamic>{
  'id': 'vendor-1',
  'company_id': 'company-1',
  'name': 'Shree Cement Supply',
  'contact': '9876543210',
  'gst': '06ABCDE1234F1Z5',
  'address': 'Gurugram, Haryana',
  'payment_terms': 'Net 30 days',
  'categories': ['Cement', 'Sand'],
  'created_at': '2026-08-01T10:00:00Z',
};
