import '../../../features/auth/models/auth_user.dart';

enum SettingsTab {
  preferences('Preferences'),
  security('Security'),
  subscription('Plan');

  const SettingsTab(this.label);
  final String label;
}

class SettingsWorkspaceData {
  const SettingsWorkspaceData({
    required this.user,
    required this.subscription,
    required this.plans,
    required this.preferences,
    required this.fetchedAt,
    this.isOffline = false,
  });

  factory SettingsWorkspaceData.fromResponses({
    required Map<String, dynamic> userPayload,
    Map<String, dynamic> subscriptionPayload = const {},
    List<Map<String, dynamic>> plansPayload = const [],
    Map<String, dynamic> preferencesPayload = const {},
    bool subscriptionAvailable = true,
    String? subscriptionMessage,
  }) {
    final user = AuthUser.fromJson(userPayload);
    return SettingsWorkspaceData(
      user: user,
      subscription: SubscriptionSnapshot.fromJson(
        subscriptionPayload,
        fallbackPlan: user.plan,
        apiAvailable: subscriptionAvailable,
        apiMessage: subscriptionMessage,
      ),
      plans: plansPayload
          .map(SubscriptionPlan.fromJson)
          .where((plan) => plan.name.isNotEmpty)
          .toList(growable: false),
      preferences: WorkspacePreferences.fromJson(preferencesPayload),
      fetchedAt: DateTime.now(),
    );
  }

  factory SettingsWorkspaceData.offline(AuthUser user) => SettingsWorkspaceData(
    user: user,
    subscription: SubscriptionSnapshot.fromJson(
      const {},
      fallbackPlan: user.plan,
      apiAvailable: false,
      apiMessage: 'Subscription details could not be reached from this device.',
    ),
    plans: const [],
    preferences: const WorkspacePreferences(),
    fetchedAt: DateTime.now(),
    isOffline: true,
  );

  final AuthUser user;
  final SubscriptionSnapshot subscription;
  final List<SubscriptionPlan> plans;
  final WorkspacePreferences preferences;
  final DateTime fetchedAt;
  final bool isOffline;

  SettingsPermissions get permissions => SettingsPermissions.forUser(user);
}

class WorkspacePreferences {
  const WorkspacePreferences({
    this.language = 'en',
    this.currency = 'INR',
    this.measurementSystem = 'METRIC',
    this.timezone = 'Asia/Kolkata',
  });

  factory WorkspacePreferences.fromJson(Map<String, dynamic> json) =>
      WorkspacePreferences(
        language: '${json['language'] ?? 'en'}'.trim(),
        currency: '${json['currency'] ?? 'INR'}'.trim(),
        measurementSystem: '${json['measurement_system'] ?? 'METRIC'}'.trim(),
        timezone: '${json['timezone'] ?? 'Asia/Kolkata'}'.trim(),
      );

  final String language;
  final String currency;
  final String measurementSystem;
  final String timezone;

  Map<String, dynamic> toJson() => {
    'language': language,
    'currency': currency,
    'measurement_system': measurementSystem,
    'timezone': timezone,
  };
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.currency,
    required this.features,
    this.description,
  });

  factory SubscriptionPlan.fromJson(
    Map<String, dynamic> json,
  ) => SubscriptionPlan(
    name: '${json['name'] ?? json['plan'] ?? json['code'] ?? json['id'] ?? ''}'
        .trim(),
    price: _doubleOrNull(
      json['price'] ?? json['amount'] ?? json['monthly_price'],
    ),
    currency: '${json['currency'] ?? 'INR'}'.trim(),
    description: _text(json['description'] ?? json['subtitle']),
    features: _strings(json['features'] ?? json['benefits']),
  );

  final String name;
  final double? price;
  final String currency;
  final String? description;
  final List<String> features;
}

class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.plan,
    required this.apiAvailable,
    this.status,
    this.renewsAt,
    this.aiCreditsRemaining,
    this.apiMessage,
  });

  factory SubscriptionSnapshot.fromJson(
    Map<String, dynamic> json, {
    String? fallbackPlan,
    required bool apiAvailable,
    String? apiMessage,
  }) => SubscriptionSnapshot(
    plan: '${json['plan'] ?? json['name'] ?? fallbackPlan ?? ''}'.trim(),
    status: _text(json['status']),
    renewsAt: DateTime.tryParse(
      '${json['renews_at'] ?? json['renewal_date'] ?? ''}',
    )?.toLocal(),
    aiCreditsRemaining: _intOrNull(
      json['ai_credits_remaining'] ?? json['credits_remaining'],
    ),
    apiAvailable: apiAvailable,
    apiMessage: apiMessage,
  );

  final String plan;
  final String? status;
  final DateTime? renewsAt;
  final int? aiCreditsRemaining;
  final bool apiAvailable;
  final String? apiMessage;

  bool get hasPlan => plan.isNotEmpty;
}

class SettingsPermissions {
  const SettingsPermissions({required this.canManageSubscription});

  factory SettingsPermissions.forUser(AuthUser user) => SettingsPermissions(
    canManageSubscription: user.isContractor || user.isSuperAdmin,
  );

  final bool canManageSubscription;
}

String? _text(Object? value) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

int? _intOrNull(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');

double? _doubleOrNull(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

List<String> _strings(Object? value) => value is List
    ? value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];
