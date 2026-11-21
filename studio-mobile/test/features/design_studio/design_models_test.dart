import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/design_studio/models/design_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Design models', () {
    test('parses multi-floor, technical, and furnished 3D outputs', () {
      final design = DesignRecord.fromJson(_designPayload);

      expect(design.status, DesignStatus.completed);
      expect(design.floorCount, 2);
      expect(design.outputs.floorPlans.last.label, 'First Floor');
      expect(
        design.outputs.technicalDrawings[DesignDrawingType.electrical]?.title,
        'Electrical layout',
      );
      expect(design.outputs.threeD[1]?.label, 'Ground Floor furnished 3D');
      expect(design.outputs.layout.rooms.single.area, 180);
      expect(design.isReady, isTrue);
    });

    test('serializes the complete existing multi-floor API contract', () {
      const brief = DesignBrief(
        siteId: 'site-1',
        projectName: 'Orchid Residence',
        plotWidth: 40,
        plotLength: 60,
        facing: 'North',
        floors: 2,
        variation: 3,
        garden: true,
        floorRequirements: [
          DesignFloorRequirement(
            floorNumber: 1,
            bedrooms: 2,
            bathrooms: 2,
            parking: true,
            poojaRoom: true,
          ),
          DesignFloorRequirement(
            floorNumber: 2,
            bedrooms: 3,
            bathrooms: 3,
            balcony: true,
            studyRoom: true,
            lift: true,
          ),
        ],
      );

      final json = brief.toApiJson();

      expect(json['site_id'], 'site-1');
      expect(json['type'], '2D');
      expect(json['variation'], 3);
      expect(json['garden'], isTrue);
      expect(json['bedrooms'], 2);
      final floors = json['floor_requirements'] as List<dynamic>;
      expect(floors, hasLength(2));
      expect((floors.last as Map<String, dynamic>)['study_room'], isTrue);
      expect((floors.last as Map<String, dynamic>)['lift'], isTrue);
    });

    test('creates the next governed version from a design', () {
      final brief = DesignBrief.fromDesign(
        DesignRecord.fromJson(_designPayload),
      );

      expect(brief.siteId, 'site-1');
      expect(brief.projectName, 'Orchid Residence');
      expect(brief.floors, 2);
      expect(brief.variation, 3);
      expect(brief.floorRequirements.last.bedrooms, 3);
      expect(brief.floorRequirements.last.balcony, isTrue);
    });

    test('filters portfolio by status, project, and site name', () {
      final design = DesignRecord.fromJson(_designPayload);
      final data = DesignStudioData(
        sites: [SiteSummary.fromJson(_sitePayload)],
        designs: [design],
        transactions: const [],
        purchases: const [],
        fetchedAt: DateTime(2026, 8, 6),
      );

      expect(data.copyWith(query: 'Gurugram').visibleDesigns, [design]);
      expect(data.copyWith(query: 'Orchid').visibleDesigns, [design]);
      expect(
        data.copyWith(statusFilter: DesignStatus.failed).visibleDesigns,
        isEmpty,
      );
    });
  });
}

const _sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const _designPayload = <String, dynamic>{
  'id': 'design-1',
  'site_id': 'site-1',
  'project_name': 'Orchid Residence',
  'design_type': '2D',
  'status': 'COMPLETED',
  'credits_used': 10,
  'created_at': '2026-08-06T09:00:00Z',
  'updated_at': '2026-08-06T09:02:00Z',
  'inputs': {
    'plot_width': 40,
    'plot_length': 60,
    'facing': 'North',
    'floors': 2,
    'variation': 2,
    'garden': true,
    'floor_requirements': [
      {
        'floor_number': 1,
        'bedrooms': 2,
        'bathrooms': 2,
        'parking': true,
        'pooja_room': true,
      },
      {
        'floor_number': 2,
        'bedrooms': 3,
        'bathrooms': 3,
        'balcony': true,
        'study_room': true,
        'lift': true,
      },
    ],
  },
  'outputs': {
    'svg': '<svg viewBox="0 0 400 600"></svg>',
    'layout': {
      'svg': '<svg viewBox="0 0 400 600"></svg>',
      'plot': {'width': 40, 'length': 60, 'facing': 'North'},
      'rooms': [
        {'name': 'Living', 'x': 0, 'y': 0, 'width': 15, 'height': 12},
      ],
    },
    'floor_plans': [
      {
        'floor_number': 1,
        'label': 'Ground Floor',
        'layout': {
          'svg':
              '<svg viewBox="0 0 400 600"><rect width="400" height="600"/></svg>',
          'plot': {'width': 40, 'length': 60, 'facing': 'North'},
          'rooms': [],
        },
      },
      {
        'floor_number': 2,
        'label': 'First Floor',
        'layout': {
          'svg': '<svg viewBox="0 0 400 600"><circle r="20"/></svg>',
          'plot': {'width': 40, 'length': 60, 'facing': 'North'},
          'rooms': [],
        },
      },
    ],
    'technical_drawings': {
      'ELECTRICAL': {
        'type': 'ELECTRICAL',
        'title': 'Electrical layout',
        'svg': '<svg viewBox="0 0 400 600"></svg>',
      },
    },
    'three_d': {
      '1': {
        'floor_number': 1,
        'label': 'Ground Floor furnished 3D',
        'svg': '<svg viewBox="0 0 400 600"></svg>',
      },
    },
  },
};
