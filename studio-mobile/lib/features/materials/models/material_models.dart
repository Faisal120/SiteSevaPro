import '../../sites/models/site_models.dart';

enum MaterialCategory {
  cement('Cement'),
  steel('Steel'),
  sand('Sand'),
  bricks('Bricks'),
  electrical('Electrical'),
  plumbing('Plumbing'),
  tiles('Tiles'),
  paint('Paint'),
  other('Other');

  const MaterialCategory(this.apiValue);
  final String apiValue;

  static MaterialCategory fromApi(Object? value) {
    final normalized = '$value'.trim().toLowerCase();
    return MaterialCategory.values.firstWhere(
      (category) => category.apiValue.toLowerCase() == normalized,
      orElse: () => MaterialCategory.other,
    );
  }
}

enum MaterialMovementType {
  inward('INWARD', 'Stock receipt'),
  outward('OUTWARD', 'Issue / consumption');

  const MaterialMovementType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static MaterialMovementType fromApi(Object? value) =>
      '$value'.trim().toUpperCase() == 'OUTWARD'
      ? MaterialMovementType.outward
      : MaterialMovementType.inward;
}

enum StockHealth { healthy, low, depleted }

enum MaterialsWorkspace { inventory, movements, vendors }

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.companyId,
    required this.siteId,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.lowStockThreshold,
    required this.rate,
    this.createdAt,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    id: '${json['id'] ?? json['_id'] ?? ''}',
    companyId: '${json['company_id'] ?? ''}',
    siteId: '${json['site_id'] ?? ''}',
    name: '${json['name'] ?? ''}'.trim(),
    category: MaterialCategory.fromApi(json['category']),
    unit: '${json['unit'] ?? ''}'.trim(),
    stock: _double(
      json['stock'] ?? json['current_stock'] ?? json['available_quantity'] ?? json['quantity'],
    ),
    lowStockThreshold: _double(json['low_stock_threshold'], fallback: 10),
    rate: _double(json['rate'] ?? json['unit_rate'] ?? json['unit_price'] ?? json['price']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String companyId;
  final String siteId;
  final String name;
  final MaterialCategory category;
  final String unit;
  final double stock;
  final double lowStockThreshold;
  final double rate;
  final DateTime? createdAt;

  String get displayName => name.isEmpty ? 'Material item' : name;
  String get displayUnit => unit.isEmpty ? 'units' : unit;
  double get stockValue => stock * rate;
  StockHealth get health => stock <= 0
      ? StockHealth.depleted
      : stock <= lowStockThreshold
      ? StockHealth.low
      : StockHealth.healthy;
  bool get isLowStock => health != StockHealth.healthy;
  double get thresholdCoverage => lowStockThreshold <= 0
      ? (stock > 0 ? 1 : 0)
      : (stock / lowStockThreshold).clamp(0, 2).toDouble();

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'site_id': siteId,
    'name': name,
    'category': category.apiValue,
    'unit': unit,
    'stock': stock,
    'low_stock_threshold': lowStockThreshold,
    'rate': rate,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class MaterialCreationBrief {
  const MaterialCreationBrief({
    required this.siteId,
    required this.name,
    required this.category,
    required this.unit,
    required this.openingStock,
    required this.lowStockThreshold,
    required this.rate,
  });

  factory MaterialCreationBrief.initial() => const MaterialCreationBrief(
    siteId: '',
    name: '',
    category: MaterialCategory.cement,
    unit: '',
    openingStock: 0,
    lowStockThreshold: 10,
    rate: 0,
  );

  final String siteId;
  final String name;
  final MaterialCategory category;
  final String unit;
  final double openingStock;
  final double lowStockThreshold;
  final double rate;

  String? get validationMessage {
    if (siteId.isEmpty) return 'Choose the project site.';
    if (name.trim().length < 2) return 'Enter the material name.';
    if (unit.trim().isEmpty) return 'Enter a unit of measurement.';
    if (openingStock < 0) return 'Opening stock cannot be negative.';
    if (lowStockThreshold < 0) return 'Low-stock threshold cannot be negative.';
    if (rate < 0) return 'Material rate cannot be negative.';
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'site_id': siteId,
    'name': name.trim(),
    'category': category.apiValue,
    'unit': unit.trim(),
    'stock': openingStock,
    'low_stock_threshold': lowStockThreshold,
    'rate': rate,
  };

  MaterialCreationBrief copyWith({
    String? siteId,
    String? name,
    MaterialCategory? category,
    String? unit,
    double? openingStock,
    double? lowStockThreshold,
    double? rate,
  }) => MaterialCreationBrief(
    siteId: siteId ?? this.siteId,
    name: name ?? this.name,
    category: category ?? this.category,
    unit: unit ?? this.unit,
    openingStock: openingStock ?? this.openingStock,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    rate: rate ?? this.rate,
  );
}

class MaterialMovement {
  const MaterialMovement({
    required this.id,
    required this.companyId,
    required this.materialId,
    required this.siteId,
    required this.type,
    required this.quantity,
    this.rate,
    this.vendor,
    this.note,
    this.invoiceUrl,
    this.createdBy,
    this.createdAt,
  });

  factory MaterialMovement.fromJson(Map<String, dynamic> json) =>
      MaterialMovement(
        id: '${json['id'] ?? ''}',
        companyId: '${json['company_id'] ?? ''}',
        materialId: '${json['material_id'] ?? ''}',
        siteId: '${json['site_id'] ?? ''}',
        type: MaterialMovementType.fromApi(json['type']),
        quantity: _double(json['quantity']),
        rate: _nullableDouble(json['rate']),
        vendor: _nullableString(json['vendor']),
        note: _nullableString(json['note']),
        invoiceUrl: _nullableString(json['invoice_url']),
        createdBy: _nullableString(json['created_by']),
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String companyId;
  final String materialId;
  final String siteId;
  final MaterialMovementType type;
  final double quantity;
  final double? rate;
  final String? vendor;
  final String? note;
  final String? invoiceUrl;
  final String? createdBy;
  final DateTime? createdAt;

  double get value => quantity * (rate ?? 0);
  bool get hasInvoice => invoiceUrl?.isNotEmpty == true;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'material_id': materialId,
    'site_id': siteId,
    'type': type.apiValue,
    'quantity': quantity,
    'rate': rate,
    'vendor': vendor,
    'note': note,
    'invoice_url': invoiceUrl,
    'created_by': createdBy,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class MaterialMovementBrief {
  const MaterialMovementBrief({
    required this.materialId,
    required this.siteId,
    required this.type,
    required this.quantity,
    required this.availableStock,
    required this.rate,
    required this.vendor,
    required this.note,
    required this.invoiceUrl,
  });

  factory MaterialMovementBrief.initial(MaterialItem material) =>
      MaterialMovementBrief(
        materialId: material.id,
        siteId: material.siteId,
        type: MaterialMovementType.inward,
        quantity: 0,
        availableStock: material.stock,
        rate: material.rate,
        vendor: '',
        note: '',
        invoiceUrl: '',
      );

  final String materialId;
  final String siteId;
  final MaterialMovementType type;
  final double quantity;
  final double availableStock;
  final double rate;
  final String vendor;
  final String note;
  final String invoiceUrl;

  String? get validationMessage {
    if (materialId.isEmpty || siteId.isEmpty) return 'Material is unavailable.';
    if (quantity <= 0) return 'Enter a quantity greater than zero.';
    if (type == MaterialMovementType.outward && quantity > availableStock) {
      return 'Issue quantity cannot exceed available stock.';
    }
    if (rate < 0) return 'Transaction rate cannot be negative.';
    final invoice = invoiceUrl.trim();
    if (invoice.isNotEmpty) {
      final uri = Uri.tryParse(invoice);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        return 'Enter a valid invoice URL or leave it blank.';
      }
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'material_id': materialId,
    'site_id': siteId,
    'type': type.apiValue,
    'quantity': quantity,
    'rate': type == MaterialMovementType.inward ? rate : null,
    'vendor': type == MaterialMovementType.inward
        ? _nullableString(vendor)
        : null,
    'note': _nullableString(note),
    'invoice_url': type == MaterialMovementType.inward
        ? _nullableString(invoiceUrl)
        : null,
  };

  MaterialMovementBrief copyWith({
    MaterialMovementType? type,
    double? quantity,
    double? rate,
    String? vendor,
    String? note,
    String? invoiceUrl,
  }) => MaterialMovementBrief(
    materialId: materialId,
    siteId: siteId,
    type: type ?? this.type,
    quantity: quantity ?? this.quantity,
    availableStock: availableStock,
    rate: rate ?? this.rate,
    vendor: vendor ?? this.vendor,
    note: note ?? this.note,
    invoiceUrl: invoiceUrl ?? this.invoiceUrl,
  );
}

class MaterialVendor {
  const MaterialVendor({
    required this.id,
    required this.companyId,
    required this.name,
    required this.categories,
    this.contact,
    this.gst,
    this.address,
    this.paymentTerms,
    this.createdAt,
  });

  factory MaterialVendor.fromJson(Map<String, dynamic> json) => MaterialVendor(
    id: '${json['id'] ?? ''}',
    companyId: '${json['company_id'] ?? ''}',
    name: '${json['name'] ?? ''}'.trim(),
    contact: _nullableString(json['contact']),
    gst: _nullableString(json['gst']),
    address: _nullableString(json['address']),
    paymentTerms: _nullableString(json['payment_terms']),
    categories: _strings(json['categories']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String companyId;
  final String name;
  final String? contact;
  final String? gst;
  final String? address;
  final String? paymentTerms;
  final List<String> categories;
  final DateTime? createdAt;

  String get displayName => name.isEmpty ? 'Material vendor' : name;
  String get initials {
    final words = displayName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.map((word) => word[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'name': name,
    'contact': contact,
    'gst': gst,
    'address': address,
    'payment_terms': paymentTerms,
    'categories': categories,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class MaterialVendorBrief {
  const MaterialVendorBrief({
    required this.name,
    required this.contact,
    required this.gst,
    required this.address,
    required this.paymentTerms,
    required this.categories,
  });

  factory MaterialVendorBrief.initial() => const MaterialVendorBrief(
    name: '',
    contact: '',
    gst: '',
    address: '',
    paymentTerms: '',
    categories: [],
  );

  final String name;
  final String contact;
  final String gst;
  final String address;
  final String paymentTerms;
  final List<String> categories;

  String? get validationMessage {
    if (name.trim().length < 2) return 'Enter the vendor name.';
    if (contact.isNotEmpty &&
        contact.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Enter a valid contact number or leave it blank.';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'name': name.trim(),
    'contact': _nullableString(contact),
    'gst': _nullableString(gst)?.toUpperCase(),
    'address': _nullableString(address),
    'payment_terms': _nullableString(paymentTerms),
    'categories': categories,
  };

  MaterialVendorBrief copyWith({
    String? name,
    String? contact,
    String? gst,
    String? address,
    String? paymentTerms,
    List<String>? categories,
  }) => MaterialVendorBrief(
    name: name ?? this.name,
    contact: contact ?? this.contact,
    gst: gst ?? this.gst,
    address: address ?? this.address,
    paymentTerms: paymentTerms ?? this.paymentTerms,
    categories: categories ?? this.categories,
  );
}

class MaterialsStudioData {
  const MaterialsStudioData({
    required this.materials,
    required this.movements,
    required this.vendors,
    required this.sites,
    required this.fetchedAt,
    required this.canManageVendors,
    this.isOffline = false,
    this.workspace = MaterialsWorkspace.inventory,
    this.query = '',
    this.siteFilter,
    this.categoryFilter,
    this.lowStockOnly = false,
  });

  final List<MaterialItem> materials;
  final List<MaterialMovement> movements;
  final List<MaterialVendor> vendors;
  final List<SiteSummary> sites;
  final DateTime fetchedAt;
  final bool canManageVendors;
  final bool isOffline;
  final MaterialsWorkspace workspace;
  final String query;
  final String? siteFilter;
  final MaterialCategory? categoryFilter;
  final bool lowStockOnly;

  List<MaterialItem> get visibleMaterials {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    return materials
        .where((material) {
          if (siteFilter != null && material.siteId != siteFilter) return false;
          if (categoryFilter != null && material.category != categoryFilter) {
            return false;
          }
          if (lowStockOnly && !material.isLowStock) return false;
          final site = siteFor(material.siteId);
          final searchable =
              '${material.name} ${material.category.apiValue} ${material.unit} '
                      '${site?.name ?? ''} ${site?.location ?? ''}'
                  .toLowerCase();
          return terms.every(searchable.contains);
        })
        .toList(growable: false);
  }

  List<MaterialMovement> get visibleMovements => movements
      .where((movement) {
        if (siteFilter != null && movement.siteId != siteFilter) return false;
        final material = materialFor(movement.materialId);
        final searchable =
            '${material?.name ?? ''} ${movement.type.label} '
                    '${movement.vendor ?? ''} ${movement.note ?? ''}'
                .toLowerCase();
        final terms = query
            .trim()
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((term) => term.isNotEmpty);
        return terms.every(searchable.contains);
      })
      .toList(growable: false);

  List<MaterialVendor> get visibleVendors {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return vendors
        .where((vendor) {
          final searchable =
              '${vendor.name} ${vendor.contact ?? ''} ${vendor.gst ?? ''} '
                      '${vendor.categories.join(' ')}'
                  .toLowerCase();
          return terms.every(searchable.contains);
        })
        .toList(growable: false);
  }

  int get lowStockCount => materials.where((item) => item.isLowStock).length;
  int get depletedCount =>
      materials.where((item) => item.health == StockHealth.depleted).length;
  double get stockValue =>
      materials.fold(0, (sum, material) => sum + material.stockValue);
  double get inwardValue => movements
      .where((movement) => movement.type == MaterialMovementType.inward)
      .fold(0, (sum, movement) => sum + movement.value);
  int get stockedSiteCount =>
      materials.map((item) => item.siteId).toSet().length;

  SiteSummary? siteFor(String siteId) =>
      sites.where((site) => site.id == siteId).firstOrNull;
  MaterialItem? materialFor(String materialId) =>
      materials.where((material) => material.id == materialId).firstOrNull;
  List<MaterialMovement> movementsFor(String materialId) => movements
      .where((movement) => movement.materialId == materialId)
      .toList(growable: false);

  MaterialsStudioData copyWith({
    MaterialsWorkspace? workspace,
    String? query,
    String? siteFilter,
    bool clearSite = false,
    MaterialCategory? categoryFilter,
    bool clearCategory = false,
    bool? lowStockOnly,
  }) => MaterialsStudioData(
    materials: materials,
    movements: movements,
    vendors: vendors,
    sites: sites,
    fetchedAt: fetchedAt,
    canManageVendors: canManageVendors,
    isOffline: isOffline,
    workspace: workspace ?? this.workspace,
    query: query ?? this.query,
    siteFilter: clearSite ? null : siteFilter ?? this.siteFilter,
    categoryFilter: clearCategory
        ? null
        : categoryFilter ?? this.categoryFilter,
    lowStockOnly: lowStockOnly ?? this.lowStockOnly,
  );
}

double _double(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  return value is num ? value.toDouble() : double.tryParse('$value');
}

String? _nullableString(Object? value) {
  final normalized = '${value ?? ''}'.trim();
  return normalized.isEmpty || normalized == 'null' ? null : normalized;
}

List<String> _strings(Object? value) => value is List
    ? value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];

DateTime? _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();
