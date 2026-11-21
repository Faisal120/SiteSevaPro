import '../../sites/models/site_models.dart';

enum EstimateConstructionType {
  residential('RESIDENTIAL', 'Residential'),
  commercial('COMMERCIAL', 'Commercial'),
  semiCommercial('SEMI_COMMERCIAL', 'Semi-commercial'),
  industrial('INDUSTRIAL', 'Industrial');

  const EstimateConstructionType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static EstimateConstructionType fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return EstimateConstructionType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => EstimateConstructionType.residential,
    );
  }
}

enum EstimateQuality {
  economy('ECONOMY', 'Economy'),
  basic('BASIC', 'Basic'),
  standard('STANDARD', 'Standard'),
  premium('PREMIUM', 'Premium'),
  luxury('LUXURY', 'Luxury');

  const EstimateQuality(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static EstimateQuality fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return EstimateQuality.values.firstWhere(
      (quality) => quality.apiValue == normalized,
      orElse: () => EstimateQuality.standard,
    );
  }
}

class EstimateInput {
  const EstimateInput({
    required this.siteId,
    required this.name,
    required this.plotAreaSqft,
    required this.floors,
    required this.basement,
    required this.constructionType,
    required this.quality,
    required this.budget,
  });

  factory EstimateInput.fromJson(Map<String, dynamic> json) => EstimateInput(
    siteId: _nullableString(json['site_id']),
    name: '${json['name'] ?? ''}'.trim(),
    plotAreaSqft: _double(json['plot_area_sqft']),
    floors: _int(json['floors'], fallback: 1),
    basement: json['basement'] == true,
    constructionType: EstimateConstructionType.fromApi(
      json['construction_type'],
    ),
    quality: EstimateQuality.fromApi(json['quality']),
    budget: _double(json['budget']),
  );

  final String? siteId;
  final String name;
  final double plotAreaSqft;
  final int floors;
  final bool basement;
  final EstimateConstructionType constructionType;
  final EstimateQuality quality;
  final double budget;
}

class EstimateMaterials {
  const EstimateMaterials({
    required this.cementBags,
    required this.steelKg,
    required this.sandCft,
    required this.aggregateCft,
    required this.bricksPcs,
  });

  factory EstimateMaterials.fromJson(Map<String, dynamic> json) =>
      EstimateMaterials(
        cementBags: _double(json['cement_bags']),
        steelKg: _double(json['steel_kg']),
        sandCft: _double(json['sand_cft']),
        aggregateCft: _double(json['aggregate_cft']),
        bricksPcs: _double(json['bricks_pcs']),
      );

  final double cementBags;
  final double steelKg;
  final double sandCft;
  final double aggregateCft;
  final double bricksPcs;

  List<EstimateMaterialLine> get lines => [
    EstimateMaterialLine(name: 'Cement', quantity: cementBags, unit: 'bags'),
    EstimateMaterialLine(name: 'Steel', quantity: steelKg, unit: 'kg'),
    EstimateMaterialLine(name: 'Sand', quantity: sandCft, unit: 'cft'),
    EstimateMaterialLine(
      name: 'Aggregate',
      quantity: aggregateCft,
      unit: 'cft',
    ),
    EstimateMaterialLine(name: 'Bricks', quantity: bricksPcs, unit: 'pcs'),
  ];
}

class EstimateMaterialLine {
  const EstimateMaterialLine({
    required this.name,
    required this.quantity,
    required this.unit,
  });
  final String name;
  final double quantity;
  final String unit;
}

class EstimateDocument {
  const EstimateDocument({
    required this.id,
    required this.companyId,
    required this.siteId,
    required this.name,
    required this.input,
    required this.builtupSqft,
    required this.ratePerSqft,
    required this.quality,
    required this.typeFactor,
    required this.materials,
    required this.materialCost,
    required this.labourCost,
    required this.overhead,
    required this.total,
    required this.createdBy,
    required this.createdAt,
  });

  factory EstimateDocument.fromJson(Map<String, dynamic> json) {
    final input = EstimateInput.fromJson(_map(json['input']));
    return EstimateDocument(
      id: '${json['id'] ?? ''}',
      companyId: '${json['company_id'] ?? ''}',
      siteId: _nullableString(json['site_id'] ?? input.siteId),
      name: '${json['name'] ?? input.name}'.trim(),
      input: input,
      builtupSqft: _double(json['builtup_sqft']),
      ratePerSqft: _double(json['rate_per_sqft']),
      quality: EstimateQuality.fromApi(
        json['quality_band'] ?? input.quality.apiValue,
      ),
      typeFactor: _double(json['type_factor'], fallback: 1),
      materials: EstimateMaterials.fromJson(_map(json['materials'])),
      materialCost: _double(json['material_cost']),
      labourCost: _double(json['labour_cost']),
      overhead: _double(json['overhead']),
      total: _double(json['total']),
      createdBy: '${json['created_by'] ?? ''}',
      createdAt: _date(json['created_at']),
    );
  }

  final String id;
  final String companyId;
  final String? siteId;
  final String name;
  final EstimateInput input;
  final double builtupSqft;
  final double ratePerSqft;
  final EstimateQuality quality;
  final double typeFactor;
  final EstimateMaterials materials;
  final double materialCost;
  final double labourCost;
  final double overhead;
  final double total;
  final String createdBy;
  final DateTime? createdAt;

  double get calculatedTotal => materialCost + labourCost + overhead;
  bool get hasCostMismatch => (calculatedTotal - total).abs() > .01;
  bool get isIssued => id.isNotEmpty && total > 0;
  double materialShare() => total <= 0 ? 0 : materialCost / total;
  double labourShare() => total <= 0 ? 0 : labourCost / total;
  double overheadShare() => total <= 0 ? 0 : overhead / total;
}

class EstimateBranding {
  const EstimateBranding({
    required this.companyName,
    required this.logo,
    required this.quotationLogo,
    required this.stamp,
    required this.signature,
    required this.website,
    required this.email,
    required this.phone,
    required this.gstNumber,
    required this.address,
  });

  factory EstimateBranding.fromJson(Map<String, dynamic> json) =>
      EstimateBranding(
        companyName: '${json['company_name'] ?? ''}'.trim(),
        logo: _nullableString(json['logo']),
        quotationLogo: _nullableString(json['quotation_logo']),
        stamp: _nullableString(json['stamp']),
        signature: _nullableString(json['signature']),
        website: _nullableString(json['website']),
        email: _nullableString(json['email']),
        phone: _nullableString(json['phone']),
        gstNumber: _nullableString(json['gst_number']),
        address: _nullableString(json['address']),
      );

  final String companyName;
  final String? logo;
  final String? quotationLogo;
  final String? stamp;
  final String? signature;
  final String? website;
  final String? email;
  final String? phone;
  final String? gstNumber;
  final String? address;

  String? get preferredLogo => quotationLogo ?? logo;
  bool get hasSignature => signature?.isNotEmpty == true;
  bool get hasStamp => stamp?.isNotEmpty == true;
}

class EstimateBrief {
  const EstimateBrief({
    required this.siteId,
    required this.name,
    required this.plotAreaSqft,
    required this.floors,
    required this.basement,
    required this.constructionType,
    required this.quality,
    required this.budget,
  });

  factory EstimateBrief.initial() => const EstimateBrief(
    siteId: '',
    name: '',
    plotAreaSqft: 0,
    floors: 1,
    basement: false,
    constructionType: EstimateConstructionType.residential,
    quality: EstimateQuality.standard,
    budget: 0,
  );

  final String siteId;
  final String name;
  final double plotAreaSqft;
  final int floors;
  final bool basement;
  final EstimateConstructionType constructionType;
  final EstimateQuality quality;
  final double budget;

  String? get validationMessage {
    if (siteId.isEmpty) return 'Choose the project site.';
    if (name.trim().isEmpty) return 'Enter an estimate name.';
    if (plotAreaSqft <= 0) return 'Enter a valid plot area.';
    if (floors < 1 || floors > 200) return 'Enter between 1 and 200 floors.';
    if (budget <= 0) return 'Enter a valid project budget.';
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'site_id': siteId,
    'name': name.trim(),
    'plot_area_sqft': plotAreaSqft,
    'floors': floors,
    'basement': basement,
    'construction_type': constructionType.apiValue,
    'quality': quality.apiValue,
    'budget': budget,
  };

  EstimateBrief copyWith({
    String? siteId,
    String? name,
    double? plotAreaSqft,
    int? floors,
    bool? basement,
    EstimateConstructionType? constructionType,
    EstimateQuality? quality,
    double? budget,
  }) => EstimateBrief(
    siteId: siteId ?? this.siteId,
    name: name ?? this.name,
    plotAreaSqft: plotAreaSqft ?? this.plotAreaSqft,
    floors: floors ?? this.floors,
    basement: basement ?? this.basement,
    constructionType: constructionType ?? this.constructionType,
    quality: quality ?? this.quality,
    budget: budget ?? this.budget,
  );
}

class EstimateStudioData {
  const EstimateStudioData({
    required this.estimates,
    required this.sites,
    required this.branding,
    required this.fetchedAt,
    this.isOffline = false,
    this.query = '',
    this.siteFilter,
    this.qualityFilter,
  });

  final List<EstimateDocument> estimates;
  final List<SiteSummary> sites;
  final EstimateBranding branding;
  final DateTime fetchedAt;
  final bool isOffline;
  final String query;
  final String? siteFilter;
  final EstimateQuality? qualityFilter;

  List<EstimateDocument> get visibleEstimates {
    final normalized = query.trim().toLowerCase();
    return estimates
        .where((estimate) {
          if (siteFilter != null && estimate.siteId != siteFilter) return false;
          if (qualityFilter != null && estimate.quality != qualityFilter) {
            return false;
          }
          if (normalized.isEmpty) return true;
          final site = siteFor(estimate.siteId);
          return '${estimate.name} ${site?.name ?? ''} ${site?.location ?? ''} ${estimate.quality.label} ${estimate.input.constructionType.label}'
              .toLowerCase()
              .contains(normalized);
        })
        .toList(growable: false);
  }

  double get portfolioValue =>
      estimates.fold(0, (sum, estimate) => sum + estimate.total);
  double get averageRate => estimates.isEmpty
      ? 0
      : estimates.fold(0.0, (sum, estimate) => sum + estimate.ratePerSqft) /
            estimates.length;
  int get linkedSiteCount => estimates
      .map((estimate) => estimate.siteId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;

  SiteSummary? siteFor(String? siteId) =>
      sites.where((site) => site.id == siteId).firstOrNull;

  EstimateStudioData copyWith({
    String? query,
    String? siteFilter,
    bool clearSite = false,
    EstimateQuality? qualityFilter,
    bool clearQuality = false,
  }) => EstimateStudioData(
    estimates: estimates,
    sites: sites,
    branding: branding,
    fetchedAt: fetchedAt,
    isOffline: isOffline,
    query: query ?? this.query,
    siteFilter: clearSite ? null : siteFilter ?? this.siteFilter,
    qualityFilter: clearQuality ? null : qualityFilter ?? this.qualityFilter,
  );
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry('$key', value))
    : <String, dynamic>{};

double _double(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

String? _nullableString(Object? value) {
  final normalized = '${value ?? ''}'.trim();
  return normalized.isEmpty || normalized == 'null' ? null : normalized;
}

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();
