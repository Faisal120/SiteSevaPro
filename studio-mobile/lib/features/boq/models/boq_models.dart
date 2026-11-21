import '../../sites/models/site_models.dart';

class BoqItem {
  const BoqItem({
    required this.description,
    required this.unit,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory BoqItem.fromJson(Map<String, dynamic> json) => BoqItem(
    description: '${json['desc'] ?? json['description'] ?? 'Untitled item'}'
        .trim(),
    unit: '${json['unit'] ?? ''}'.trim(),
    quantity: _double(json['qty'] ?? json['quantity']),
    rate: _double(json['rate']),
    amount: _double(json['amount']),
  );

  final String description;
  final String unit;
  final double quantity;
  final double rate;
  final double amount;

  double get calculatedAmount => quantity * rate;
  bool get hasRateMismatch => (calculatedAmount - amount).abs() > .01;
}

class BoqSection {
  const BoqSection({
    required this.name,
    required this.items,
    required this.subtotal,
  });

  factory BoqSection.fromJson(Map<String, dynamic> json) => BoqSection(
    name: '${json['name'] ?? 'Uncategorized'}'.trim(),
    items: _maps(json['items']).map(BoqItem.fromJson).toList(growable: false),
    subtotal: _double(json['subtotal']),
  );

  final String name;
  final List<BoqItem> items;
  final double subtotal;

  double shareOf(double total) => total <= 0 ? 0 : subtotal / total;
}

class BoqDocument {
  const BoqDocument({
    required this.id,
    required this.name,
    required this.siteId,
    required this.estimateId,
    required this.builtupSqft,
    required this.sections,
    required this.total,
    required this.createdBy,
    required this.createdAt,
  });

  factory BoqDocument.fromJson(Map<String, dynamic> json) => BoqDocument(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? 'Untitled BOQ'}'.trim(),
    siteId: _nullableString(json['site_id']),
    estimateId: _nullableString(json['estimate_id']),
    builtupSqft: _double(json['builtup_sqft']),
    sections: _maps(
      json['sections'],
    ).map(BoqSection.fromJson).toList(growable: false),
    total: _double(json['total']),
    createdBy: '${json['created_by'] ?? ''}',
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String name;
  final String? siteId;
  final String? estimateId;
  final double builtupSqft;
  final List<BoqSection> sections;
  final double total;
  final String createdBy;
  final DateTime? createdAt;

  int get itemCount =>
      sections.fold(0, (sum, section) => sum + section.items.length);
  int get rateMismatchCount => sections.fold(
    0,
    (sum, section) =>
        sum + section.items.where((item) => item.hasRateMismatch).length,
  );
  bool get isIssued => id.isNotEmpty && sections.isNotEmpty;
}

class BoqEstimateSummary {
  const BoqEstimateSummary({
    required this.id,
    required this.name,
    required this.siteId,
    required this.builtupSqft,
    required this.total,
    required this.qualityBand,
    required this.createdAt,
  });

  factory BoqEstimateSummary.fromJson(Map<String, dynamic> json) =>
      BoqEstimateSummary(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? 'Untitled estimate'}'.trim(),
        siteId: _nullableString(json['site_id']),
        builtupSqft: _double(json['builtup_sqft']),
        total: _double(json['total']),
        qualityBand: '${json['quality_band'] ?? ''}'.trim(),
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String name;
  final String? siteId;
  final double builtupSqft;
  final double total;
  final String qualityBand;
  final DateTime? createdAt;
}

class BoqVendorSummary {
  const BoqVendorSummary({
    required this.id,
    required this.name,
    required this.contact,
    required this.gst,
    required this.categories,
  });

  factory BoqVendorSummary.fromJson(Map<String, dynamic> json) =>
      BoqVendorSummary(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? 'Unnamed vendor'}'.trim(),
        contact: _nullableString(json['contact']),
        gst: _nullableString(json['gst']),
        categories: (json['categories'] as List? ?? const [])
            .map((category) => '$category')
            .where((category) => category.isNotEmpty)
            .toList(growable: false),
      );

  final String id;
  final String name;
  final String? contact;
  final String? gst;
  final List<String> categories;
}

enum BoqGenerationSource { estimate, measuredArea }

class BoqGenerationBrief {
  const BoqGenerationBrief({
    required this.name,
    required this.siteId,
    required this.source,
    required this.estimateId,
    required this.builtupSqft,
  });

  factory BoqGenerationBrief.initial() => const BoqGenerationBrief(
    name: '',
    siteId: '',
    source: BoqGenerationSource.estimate,
    estimateId: '',
    builtupSqft: 0,
  );

  final String name;
  final String siteId;
  final BoqGenerationSource source;
  final String estimateId;
  final double builtupSqft;

  String? get validationMessage {
    if (name.trim().isEmpty) return 'Enter a BOQ name.';
    if (siteId.isEmpty) return 'Choose the project site.';
    if (source == BoqGenerationSource.estimate && estimateId.isEmpty) {
      return 'Choose a source estimate.';
    }
    if (source == BoqGenerationSource.measuredArea && builtupSqft <= 0) {
      return 'Enter a valid built-up area.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'name': name.trim(),
    'site_id': siteId,
    if (source == BoqGenerationSource.estimate) 'estimate_id': estimateId,
    if (source == BoqGenerationSource.measuredArea) 'builtup_sqft': builtupSqft,
  };

  BoqGenerationBrief copyWith({
    String? name,
    String? siteId,
    BoqGenerationSource? source,
    String? estimateId,
    double? builtupSqft,
  }) => BoqGenerationBrief(
    name: name ?? this.name,
    siteId: siteId ?? this.siteId,
    source: source ?? this.source,
    estimateId: estimateId ?? this.estimateId,
    builtupSqft: builtupSqft ?? this.builtupSqft,
  );
}

class BoqStudioData {
  const BoqStudioData({
    required this.boqs,
    required this.sites,
    required this.estimates,
    required this.vendors,
    required this.fetchedAt,
    this.isOffline = false,
    this.query = '',
    this.siteFilter,
  });

  final List<BoqDocument> boqs;
  final List<SiteSummary> sites;
  final List<BoqEstimateSummary> estimates;
  final List<BoqVendorSummary> vendors;
  final DateTime fetchedAt;
  final bool isOffline;
  final String query;
  final String? siteFilter;

  List<BoqDocument> get visibleBoqs {
    final normalized = query.trim().toLowerCase();
    return boqs
        .where((boq) {
          if (siteFilter != null && boq.siteId != siteFilter) return false;
          if (normalized.isEmpty) return true;
          final site = siteFor(boq.siteId);
          final estimate = estimateFor(boq.estimateId);
          return '${boq.name} ${site?.name ?? ''} ${site?.location ?? ''} ${estimate?.name ?? ''}'
              .toLowerCase()
              .contains(normalized);
        })
        .toList(growable: false);
  }

  double get documentedValue => boqs.fold(0, (sum, boq) => sum + boq.total);
  int get totalItems => boqs.fold(0, (sum, boq) => sum + boq.itemCount);
  int get linkedSiteCount => boqs
      .map((boq) => boq.siteId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;

  SiteSummary? siteFor(String? siteId) =>
      sites.where((site) => site.id == siteId).firstOrNull;
  BoqEstimateSummary? estimateFor(String? estimateId) =>
      estimates.where((estimate) => estimate.id == estimateId).firstOrNull;

  List<BoqEstimateSummary> estimatesForSite(String siteId) => estimates
      .where((estimate) => estimate.siteId == siteId)
      .toList(growable: false);

  BoqStudioData copyWith({
    String? query,
    String? siteFilter,
    bool clearSite = false,
  }) => BoqStudioData(
    boqs: boqs,
    sites: sites,
    estimates: estimates,
    vendors: vendors,
    fetchedAt: fetchedAt,
    isOffline: isOffline,
    query: query ?? this.query,
    siteFilter: clearSite ? null : siteFilter ?? this.siteFilter,
  );
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry('$key', value))
    : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map(_map).toList(growable: false)
    : const [];

double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String? _nullableString(Object? value) {
  final normalized = '${value ?? ''}'.trim();
  return normalized.isEmpty || normalized == 'null' ? null : normalized;
}

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();
