import '../../../features/auth/models/auth_user.dart';

class ProfileCompanyData {
  const ProfileCompanyData({
    required this.user,
    required this.company,
    required this.branding,
    required this.fetchedAt,
    this.isOffline = false,
    this.apiAvailable = true,
    this.brandingApiAvailable = true,
    this.apiMessage,
    this.brandingApiMessage,
  });

  factory ProfileCompanyData.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    bool isOffline = false,
    bool apiAvailable = true,
    bool brandingApiAvailable = true,
    String? apiMessage,
    String? brandingApiMessage,
  }) {
    final rawUser = _map(json['user']);
    final user = AuthUser.fromJson(rawUser);
    final brandingJson = _map(json['branding']);
    return ProfileCompanyData(
      user: user,
      company: CompanyProfile.fromJson(
        _map(json['company']).isEmpty ? brandingJson : _map(json['company']),
        fallbackUser: user,
        fallbackBranding: brandingJson,
      ),
      branding: CompanyBranding.fromJson(brandingJson),
      fetchedAt: fetchedAt ?? _date(json['fetched_at']) ?? DateTime.now(),
      isOffline: isOffline,
      apiAvailable: apiAvailable,
      brandingApiAvailable: brandingApiAvailable,
      apiMessage: apiMessage,
      brandingApiMessage: brandingApiMessage,
    );
  }

  factory ProfileCompanyData.fromResponses({
    required Map<String, dynamic> userPayload,
    required Map<String, dynamic> brandingPayload,
    DateTime? fetchedAt,
    bool isOffline = false,
    bool brandingApiAvailable = true,
    String? brandingApiMessage,
  }) {
    final user = AuthUser.fromJson(userPayload);
    final nestedBranding = _map(brandingPayload['branding']);
    final effectiveBranding = nestedBranding.isEmpty
        ? brandingPayload
        : nestedBranding;
    final companyPayload = _map(effectiveBranding['company']);
    return ProfileCompanyData(
      user: user,
      company: CompanyProfile.fromJson(
        companyPayload.isEmpty ? effectiveBranding : companyPayload,
        fallbackUser: user,
        fallbackBranding: effectiveBranding,
      ),
      branding: CompanyBranding.fromJson(effectiveBranding),
      fetchedAt: fetchedAt ?? DateTime.now(),
      isOffline: isOffline,
      brandingApiAvailable: brandingApiAvailable,
      brandingApiMessage: brandingApiMessage,
    );
  }

  factory ProfileCompanyData.unavailable({
    required AuthUser user,
    DateTime? fetchedAt,
    String? message,
  }) => ProfileCompanyData(
    user: user,
    company: CompanyProfile.fromUser(user),
    branding: const CompanyBranding(),
    fetchedAt: fetchedAt ?? DateTime.now(),
    apiAvailable: false,
    brandingApiAvailable: false,
    apiMessage: message ?? 'Profile data is not available yet.',
    brandingApiMessage: 'Company branding is not connected.',
  );

  final AuthUser user;
  final CompanyProfile company;
  final CompanyBranding branding;
  final DateTime fetchedAt;
  final bool isOffline;
  final bool apiAvailable;
  final bool brandingApiAvailable;
  final String? apiMessage;
  final String? brandingApiMessage;

  ProfilePermissions get permissions => ProfilePermissions.forUser(user);

  String get cacheKey => user.id;

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'company': company.toJson(),
    'branding': branding.toJson(),
    'fetched_at': fetchedAt.toUtc().toIso8601String(),
  };
}

class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    this.legalName,
    this.email,
    this.phone,
    this.website,
    this.gstNumber,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.logoUrl,
    this.createdAt,
  });

  factory CompanyProfile.fromUser(AuthUser user) => CompanyProfile(
    id: user.companyId ?? '',
    name: user.companyName ?? '',
  );

  factory CompanyProfile.fromJson(
    Map<String, dynamic> json, {
    required AuthUser fallbackUser,
    Map<String, dynamic> fallbackBranding = const {},
  }) {
    String? value(String key, [String? alternate]) {
      final raw = json[key] ?? (alternate == null ? null : json[alternate]);
      if (raw == null && fallbackBranding.isNotEmpty) {
        return _nullableString(
          fallbackBranding[key] ??
              (alternate == null ? null : fallbackBranding[alternate]),
        );
      }
      return _nullableString(raw);
    }

    return CompanyProfile(
      id: '${json['id'] ?? fallbackUser.companyId ?? ''}',
      name: '${json['name'] ?? json['company_name'] ?? fallbackUser.companyName ?? ''}'
          .trim(),
      legalName: value('legal_name'),
      email: value('email', 'business_email'),
      phone: value('phone', 'business_phone'),
      website: value('website'),
      gstNumber: value('gst_number', 'gstin'),
      address: value('address'),
      city: value('city'),
      state: value('state'),
      pincode: value('pincode', 'postal_code'),
      logoUrl: value('logo_url', 'logo'),
      createdAt: _date(json['created_at']),
    );
  }

  final String id;
  final String name;
  final String? legalName;
  final String? email;
  final String? phone;
  final String? website;
  final String? gstNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? logoUrl;
  final DateTime? createdAt;

  String get location => [city, state]
      .where((part) => part?.trim().isNotEmpty == true)
      .map((part) => part!.trim())
      .join(', ');

  bool get hasRegisteredDetails => [
    legalName,
    gstNumber,
    address,
    city,
    state,
    pincode,
  ].any((value) => value?.trim().isNotEmpty == true);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'legal_name': legalName,
    'email': email,
    'phone': phone,
    'website': website,
    'gst_number': gstNumber,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'logo_url': logoUrl,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

class CompanyBranding {
  const CompanyBranding({
    this.companyName = '',
    this.logoUrl,
    this.primaryColor = '#2563EB',
    this.secondaryColor = '#0A0E17',
    this.accentColor = '#4F8CFF',
    this.font = 'Sora',
    this.email,
    this.phone,
    this.address,
    this.website,
    this.gstNumber,
  });

  factory CompanyBranding.fromJson(Map<String, dynamic> json) => CompanyBranding(
    companyName: '${json['company_name'] ?? json['name'] ?? ''}'.trim(),
    logoUrl: _nullableString(
      json['logo_url'] ?? json['logo'] ?? json['company_logo'],
    ),
    primaryColor: _colorValue(json['primary_color'], '#2563EB'),
    secondaryColor: _colorValue(json['secondary_color'], '#0A0E17'),
    accentColor: _colorValue(json['accent_color'], '#4F8CFF'),
    font: '${json['font'] ?? 'Sora'}'.trim(),
    email: _nullableString(json['email']),
    phone: _nullableString(json['phone']),
    address: _nullableString(json['address']),
    website: _nullableString(json['website']),
    gstNumber: _nullableString(json['gst_number'] ?? json['gstin']),
  );

  final String companyName;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String font;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? gstNumber;

  Map<String, dynamic> toJson() => {
    'company_name': companyName,
    'logo_url': logoUrl,
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
    'accent_color': accentColor,
    'font': font,
    'email': email,
    'phone': phone,
    'address': address,
    'website': website,
    'gst_number': gstNumber,
  };
}

class BrandingUpdate {
  const BrandingUpdate({
    required this.companyName,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.gstNumber,
    this.primaryColor = '#2563EB',
    this.secondaryColor = '#0A0E17',
    this.accentColor = '#4F8CFF',
    this.font = 'Sora',
  });

  final String companyName;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? gstNumber;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String font;

  Map<String, dynamic> toJson() => {
    'company_name': companyName.trim(),
    'email': _clean(email),
    'phone': _clean(phone),
    'address': _clean(address),
    'website': _clean(website),
    'gst_number': _clean(gstNumber),
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
    'accent_color': accentColor,
    'font': font,
  };
}

class ProfilePermissions {
  const ProfilePermissions({
    required this.canEditBranding,
    required this.canUploadLogo,
    required this.canManageSubscription,
    required this.isReadOnly,
  });

  factory ProfilePermissions.forUser(AuthUser user) => ProfilePermissions(
    canEditBranding: user.isContractor || user.isSuperAdmin,
    canUploadLogo: user.isContractor || user.isSuperAdmin,
    canManageSubscription: user.isContractor || user.isSuperAdmin,
    isReadOnly: user.isSupervisor || user.isClient,
  );

  final bool canEditBranding;
  final bool canUploadLogo;
  final bool canManageSubscription;
  final bool isReadOnly;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

String _colorValue(Object? value, String fallback) {
  final text = '$value'.trim();
  return text.isEmpty || text == 'null' ? fallback : text;
}

String? _clean(String? value) => value?.trim().isEmpty == true ? null : value?.trim();

DateTime? _date(Object? value) => value == null
    ? null
    : DateTime.tryParse('$value')?.toLocal();

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, item) => MapEntry('$key', item))
    : <String, dynamic>{};
