import '../../sites/models/site_models.dart';

enum DesignStatus {
  queued('QUEUED', 'Queued'),
  processing('PROCESSING', 'Processing'),
  completed('COMPLETED', 'Ready'),
  failed('FAILED', 'Failed');

  const DesignStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DesignStatus fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return DesignStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => DesignStatus.failed,
    );
  }
}

enum DesignDrawingType {
  floor('FLOOR', 'Floor plan', 0),
  electrical('ELECTRICAL', 'Electrical', 5),
  plumbing('PLUMBING', 'Plumbing', 5),
  column('COLUMN', 'Column grid', 5),
  structural('STRUCTURAL', 'Structural', 5),
  foundation('FOUNDATION', 'Foundation', 5),
  doorWindow('DOOR_WINDOW', 'Door & window', 5);

  const DesignDrawingType(this.apiValue, this.label, this.creditCost);

  final String apiValue;
  final String label;
  final int creditCost;

  bool get isTechnical => this != DesignDrawingType.floor;

  static DesignDrawingType fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return DesignDrawingType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => DesignDrawingType.floor,
    );
  }
}

class DesignRoom {
  const DesignRoom({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DesignRoom.fromJson(Map<String, dynamic> json) => DesignRoom(
    name: '${json['name'] ?? 'Room'}',
    x: _double(json['x']),
    y: _double(json['y']),
    width: _double(json['width']),
    height: _double(json['height'] ?? json['length']),
  );

  final String name;
  final double x;
  final double y;
  final double width;
  final double height;

  double get area => width * height;
}

class DesignLayout {
  const DesignLayout({
    required this.svg,
    required this.plotWidth,
    required this.plotLength,
    required this.facing,
    required this.rooms,
  });

  factory DesignLayout.fromJson(Map<String, dynamic> json) {
    final plot = _map(json['plot']);
    return DesignLayout(
      svg: '${json['svg'] ?? ''}',
      plotWidth: _double(plot['width']),
      plotLength: _double(plot['length']),
      facing: '${plot['facing'] ?? ''}',
      rooms: _maps(
        json['rooms'],
      ).map(DesignRoom.fromJson).toList(growable: false),
    );
  }

  final String svg;
  final double plotWidth;
  final double plotLength;
  final String facing;
  final List<DesignRoom> rooms;

  double get plotArea => plotWidth * plotLength;
}

class DesignFloorPlan {
  const DesignFloorPlan({
    required this.floorNumber,
    required this.label,
    required this.layout,
  });

  factory DesignFloorPlan.fromJson(Map<String, dynamic> json) =>
      DesignFloorPlan(
        floorNumber: _int(json['floor_number'], fallback: 1),
        label: '${json['label'] ?? 'Floor'}',
        layout: DesignLayout.fromJson(_map(json['layout'])),
      );

  final int floorNumber;
  final String label;
  final DesignLayout layout;
}

class DesignTechnicalDrawing {
  const DesignTechnicalDrawing({
    required this.type,
    required this.title,
    required this.svg,
  });

  factory DesignTechnicalDrawing.fromJson(
    DesignDrawingType fallback,
    Map<String, dynamic> json,
  ) => DesignTechnicalDrawing(
    type: DesignDrawingType.fromApi(json['type'] ?? fallback.apiValue),
    title: '${json['title'] ?? fallback.label}',
    svg: '${json['svg'] ?? ''}',
  );

  final DesignDrawingType type;
  final String title;
  final String svg;
}

class DesignThreeDConcept {
  const DesignThreeDConcept({
    required this.floorNumber,
    required this.label,
    required this.svg,
  });

  factory DesignThreeDConcept.fromJson(Map<String, dynamic> json) =>
      DesignThreeDConcept(
        floorNumber: _int(json['floor_number'], fallback: 1),
        label: '${json['label'] ?? '3D concept'}',
        svg: '${json['svg'] ?? ''}',
      );

  final int floorNumber;
  final String label;
  final String svg;
}

class DesignOutputs {
  const DesignOutputs({
    required this.baseSvg,
    required this.layout,
    required this.floorPlans,
    required this.technicalDrawings,
    required this.threeD,
  });

  factory DesignOutputs.fromJson(Map<String, dynamic> json) {
    final layout = DesignLayout.fromJson(_map(json['layout']));
    final technical = <DesignDrawingType, DesignTechnicalDrawing>{};
    _map(json['technical_drawings']).forEach((key, value) {
      if (value is! Map) return;
      final type = DesignDrawingType.fromApi(key);
      if (type.isTechnical) {
        technical[type] = DesignTechnicalDrawing.fromJson(type, _map(value));
      }
    });
    final concepts = <int, DesignThreeDConcept>{};
    _map(json['three_d']).forEach((key, value) {
      if (value is! Map) return;
      final concept = DesignThreeDConcept.fromJson(_map(value));
      concepts[concept.floorNumber] = concept;
    });
    final floors = _maps(
      json['floor_plans'],
    ).map(DesignFloorPlan.fromJson).toList(growable: false);
    return DesignOutputs(
      baseSvg: '${json['svg'] ?? layout.svg}',
      layout: layout,
      floorPlans: floors.isEmpty && layout.svg.isNotEmpty
          ? [
              DesignFloorPlan(
                floorNumber: 1,
                label: 'Ground Floor',
                layout: layout,
              ),
            ]
          : floors,
      technicalDrawings: technical,
      threeD: concepts,
    );
  }

  final String baseSvg;
  final DesignLayout layout;
  final List<DesignFloorPlan> floorPlans;
  final Map<DesignDrawingType, DesignTechnicalDrawing> technicalDrawings;
  final Map<int, DesignThreeDConcept> threeD;

  String svgFor(DesignDrawingType type, int floorNumber) {
    if (type.isTechnical) return technicalDrawings[type]?.svg ?? '';
    return floorPlans
            .where((floor) => floor.floorNumber == floorNumber)
            .map((floor) => floor.layout.svg)
            .firstOrNull ??
        baseSvg;
  }
}

class DesignRecord {
  const DesignRecord({
    required this.id,
    required this.projectName,
    required this.siteId,
    required this.designType,
    required this.status,
    required this.creditsUsed,
    required this.inputs,
    required this.outputs,
    required this.createdAt,
    required this.updatedAt,
    this.error,
  });

  factory DesignRecord.fromJson(Map<String, dynamic> json) => DesignRecord(
    id: '${json['id'] ?? ''}',
    projectName: '${json['project_name'] ?? 'Untitled project'}',
    siteId: '${json['site_id'] ?? ''}',
    designType: '${json['design_type'] ?? json['type'] ?? '2D'}',
    status: DesignStatus.fromApi(json['status']),
    creditsUsed: _int(json['credits_used']),
    inputs: _map(json['inputs']),
    outputs: DesignOutputs.fromJson(_map(json['outputs'])),
    error: json['error'] as String?,
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

  final String id;
  final String projectName;
  final String siteId;
  final String designType;
  final DesignStatus status;
  final int creditsUsed;
  final Map<String, dynamic> inputs;
  final DesignOutputs outputs;
  final String? error;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isReady =>
      status == DesignStatus.completed && outputs.baseSvg.isNotEmpty;
  int get floorCount => outputs.floorPlans.length;
}

class DesignFloorRequirement {
  const DesignFloorRequirement({
    required this.floorNumber,
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.living = true,
    this.dining = true,
    this.kitchen = true,
    this.staircase = true,
    this.parking = false,
    this.balcony = false,
    this.poojaRoom = false,
    this.studyRoom = false,
    this.storeRoom = false,
    this.utilityRoom = false,
    this.lift = false,
  });

  final int floorNumber;
  final int bedrooms;
  final int bathrooms;
  final bool living;
  final bool dining;
  final bool kitchen;
  final bool staircase;
  final bool parking;
  final bool balcony;
  final bool poojaRoom;
  final bool studyRoom;
  final bool storeRoom;
  final bool utilityRoom;
  final bool lift;

  String get label =>
      floorNumber == 1 ? 'Ground Floor' : 'Floor ${floorNumber - 1}';

  DesignFloorRequirement copyWith({
    int? bedrooms,
    int? bathrooms,
    bool? living,
    bool? dining,
    bool? kitchen,
    bool? staircase,
    bool? parking,
    bool? balcony,
    bool? poojaRoom,
    bool? studyRoom,
    bool? storeRoom,
    bool? utilityRoom,
    bool? lift,
  }) => DesignFloorRequirement(
    floorNumber: floorNumber,
    bedrooms: bedrooms ?? this.bedrooms,
    bathrooms: bathrooms ?? this.bathrooms,
    living: living ?? this.living,
    dining: dining ?? this.dining,
    kitchen: kitchen ?? this.kitchen,
    staircase: staircase ?? this.staircase,
    parking: parking ?? this.parking,
    balcony: balcony ?? this.balcony,
    poojaRoom: poojaRoom ?? this.poojaRoom,
    studyRoom: studyRoom ?? this.studyRoom,
    storeRoom: storeRoom ?? this.storeRoom,
    utilityRoom: utilityRoom ?? this.utilityRoom,
    lift: lift ?? this.lift,
  );

  Map<String, dynamic> toApiJson() => {
    'floor_number': floorNumber,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'living': living,
    'dining': dining,
    'kitchen': kitchen,
    'staircase': staircase,
    'parking': parking,
    'balcony': balcony,
    'pooja_room': poojaRoom,
    'study_room': studyRoom,
    'store_room': storeRoom,
    'utility_room': utilityRoom,
    'lift': lift,
  };
}

class DesignBrief {
  const DesignBrief({
    required this.siteId,
    required this.projectName,
    required this.plotWidth,
    required this.plotLength,
    required this.facing,
    required this.floors,
    required this.variation,
    required this.floorRequirements,
    this.garden = false,
  });

  factory DesignBrief.initial() => const DesignBrief(
    siteId: '',
    projectName: '',
    plotWidth: 30,
    plotLength: 50,
    facing: 'East',
    floors: 1,
    variation: 0,
    floorRequirements: [DesignFloorRequirement(floorNumber: 1)],
  );

  factory DesignBrief.fromDesign(DesignRecord design) {
    final input = design.inputs;
    final floors = _int(input['floors'], fallback: 1).clamp(1, 12);
    final requirementPayload = _maps(input['floor_requirements']);
    final requirements = List.generate(floors, (index) {
      final floorNumber = index + 1;
      final raw = requirementPayload.where(
        (item) => _int(item['floor_number']) == floorNumber,
      );
      final item = raw.isEmpty ? input : raw.first;
      return DesignFloorRequirement(
        floorNumber: floorNumber,
        bedrooms: _int(item['bedrooms'], fallback: 2),
        bathrooms: _int(item['bathrooms'], fallback: 2),
        living: item['living'] != false,
        dining: item['dining'] != false,
        kitchen: item['kitchen'] != false,
        staircase: item['staircase'] != false,
        parking: floorNumber == 1 && item['parking'] == true,
        balcony: item['balcony'] == true,
        poojaRoom: item['pooja_room'] == true,
        studyRoom: item['study_room'] == true,
        storeRoom: item['store_room'] == true,
        utilityRoom: item['utility_room'] == true,
        lift: item['lift'] == true,
      );
    });
    return DesignBrief(
      siteId: design.siteId,
      projectName: design.projectName,
      plotWidth: _double(input['plot_width'], fallback: 30),
      plotLength: _double(input['plot_length'], fallback: 50),
      facing: '${input['facing'] ?? 'East'}',
      floors: floors,
      variation: _int(input['variation']) + 1,
      garden: input['garden'] == true,
      floorRequirements: requirements,
    );
  }

  final String siteId;
  final String projectName;
  final double plotWidth;
  final double plotLength;
  final String facing;
  final int floors;
  final int variation;
  final bool garden;
  final List<DesignFloorRequirement> floorRequirements;

  String? get validationMessage {
    if (siteId.isEmpty) return 'Choose a site for this design.';
    if (projectName.trim().isEmpty) return 'Enter a project name.';
    if (plotWidth <= 0 || plotLength <= 0)
      return 'Enter valid plot dimensions.';
    if (floors < 1 || floorRequirements.length != floors) {
      return 'Configure every floor before generating.';
    }
    if (floorRequirements.any(
      (floor) => floor.bedrooms < 0 || floor.bathrooms < 0,
    )) {
      return 'Room counts cannot be negative.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() {
    final ground = floorRequirements.first;
    return {
      'site_id': siteId,
      'project_name': projectName.trim(),
      'plot_width': plotWidth,
      'plot_length': plotLength,
      'facing': facing,
      'bedrooms': ground.bedrooms,
      'bathrooms': ground.bathrooms,
      'floors': floors,
      'type': '2D',
      'variation': variation,
      'parking': ground.parking,
      'balcony': ground.balcony,
      'living': ground.living,
      'dining': ground.dining,
      'kitchen': ground.kitchen,
      'pooja_room': ground.poojaRoom,
      'study_room': ground.studyRoom,
      'store_room': ground.storeRoom,
      'utility_room': ground.utilityRoom,
      'lift': ground.lift,
      'staircase': ground.staircase,
      'garden': garden,
      'floor_requirements': floorRequirements
          .map((floor) => floor.toApiJson())
          .toList(growable: false),
    };
  }

  DesignBrief copyWith({
    String? siteId,
    String? projectName,
    double? plotWidth,
    double? plotLength,
    String? facing,
    int? floors,
    int? variation,
    bool? garden,
    List<DesignFloorRequirement>? floorRequirements,
  }) => DesignBrief(
    siteId: siteId ?? this.siteId,
    projectName: projectName ?? this.projectName,
    plotWidth: plotWidth ?? this.plotWidth,
    plotLength: plotLength ?? this.plotLength,
    facing: facing ?? this.facing,
    floors: floors ?? this.floors,
    variation: variation ?? this.variation,
    garden: garden ?? this.garden,
    floorRequirements: floorRequirements ?? this.floorRequirements,
  );
}

class DesignWallet {
  const DesignWallet({required this.companyId, required this.credits});

  factory DesignWallet.fromJson(Map<String, dynamic> json) => DesignWallet(
    companyId: '${json['company_id'] ?? ''}',
    credits: _int(json['credits']),
  );

  final String companyId;
  final int credits;
}

class DesignTransaction {
  const DesignTransaction({
    required this.id,
    required this.type,
    required this.credits,
    required this.description,
    required this.createdAt,
  });

  factory DesignTransaction.fromJson(Map<String, dynamic> json) =>
      DesignTransaction(
        id: '${json['id'] ?? ''}',
        type: '${json['type'] ?? ''}',
        credits: _int(json['credits']),
        description: '${json['description'] ?? 'Design credits'}',
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String type;
  final int credits;
  final String description;
  final DateTime? createdAt;
}

class DesignCreditPack {
  const DesignCreditPack({
    required this.code,
    required this.credits,
    required this.amount,
  });

  final String code;
  final int credits;
  final int amount;
}

class DesignPurchaseConfig {
  const DesignPurchaseConfig({
    required this.upiId,
    required this.payeeName,
    required this.packs,
  });

  factory DesignPurchaseConfig.fromJson(Map<String, dynamic> json) {
    final packs = <DesignCreditPack>[];
    _map(json['packs']).forEach((key, value) {
      final item = _map(value);
      packs.add(
        DesignCreditPack(
          code: key,
          credits: _int(item['credits']),
          amount: _int(item['amount']),
        ),
      );
    });
    return DesignPurchaseConfig(
      upiId: '${json['upi_id'] ?? ''}',
      payeeName: '${json['payee_name'] ?? 'Site Seva Pro'}',
      packs: packs,
    );
  }

  final String upiId;
  final String payeeName;
  final List<DesignCreditPack> packs;
}

class DesignPurchaseRequest {
  const DesignPurchaseRequest({
    required this.id,
    required this.pack,
    required this.credits,
    required this.amount,
    required this.utr,
    required this.status,
    required this.createdAt,
  });

  factory DesignPurchaseRequest.fromJson(Map<String, dynamic> json) =>
      DesignPurchaseRequest(
        id: '${json['id'] ?? ''}',
        pack: '${json['pack'] ?? ''}',
        credits: _int(json['credits']),
        amount: _int(json['amount']),
        utr: '${json['utr'] ?? ''}',
        status: '${json['status'] ?? 'PENDING'}',
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String pack;
  final int credits;
  final int amount;
  final String utr;
  final String status;
  final DateTime? createdAt;
}

class DesignStudioData {
  const DesignStudioData({
    required this.sites,
    required this.designs,
    required this.transactions,
    required this.purchases,
    required this.fetchedAt,
    this.wallet,
    this.purchaseConfig,
    this.isOffline = false,
    this.query = '',
    this.statusFilter,
  });

  final List<SiteSummary> sites;
  final List<DesignRecord> designs;
  final DesignWallet? wallet;
  final List<DesignTransaction> transactions;
  final DesignPurchaseConfig? purchaseConfig;
  final List<DesignPurchaseRequest> purchases;
  final DateTime fetchedAt;
  final bool isOffline;
  final String query;
  final DesignStatus? statusFilter;

  List<DesignRecord> get visibleDesigns {
    final normalized = query.trim().toLowerCase();
    return designs
        .where((design) {
          if (statusFilter != null && design.status != statusFilter)
            return false;
          if (normalized.isEmpty) return true;
          final site = siteFor(design.siteId);
          return '${design.projectName} ${site?.name ?? ''} ${site?.location ?? ''} ${design.designType}'
              .toLowerCase()
              .contains(normalized);
        })
        .toList(growable: false);
  }

  SiteSummary? siteFor(String siteId) =>
      sites.where((site) => site.id == siteId).firstOrNull;

  int count(DesignStatus status) =>
      designs.where((design) => design.status == status).length;

  DesignStudioData copyWith({
    String? query,
    DesignStatus? statusFilter,
    bool clearStatus = false,
  }) => DesignStudioData(
    sites: sites,
    designs: designs,
    wallet: wallet,
    transactions: transactions,
    purchaseConfig: purchaseConfig,
    purchases: purchases,
    fetchedAt: fetchedAt,
    isOffline: isOffline,
    query: query ?? this.query,
    statusFilter: clearStatus ? null : statusFilter ?? this.statusFilter,
  );
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry('$key', value))
    : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map(_map).toList(growable: false)
    : const [];

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double _double(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();
