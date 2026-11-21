enum CrmWorkspace {
  leads,
  clients,
  vendors,
  activities,
  quotations;

  String get label => switch (this) {
    CrmWorkspace.leads => 'Leads',
    CrmWorkspace.clients => 'Clients',
    CrmWorkspace.vendors => 'Vendors',
    CrmWorkspace.activities => 'Follow-ups',
    CrmWorkspace.quotations => 'Quotations',
  };
}

enum CrmContactKind {
  client,
  vendor,
  architect,
  builder,
  unknown;

  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    CrmContactKind.client => 'Client',
    CrmContactKind.vendor => 'Vendor',
    CrmContactKind.architect => 'Architect',
    CrmContactKind.builder => 'Builder',
    CrmContactKind.unknown => 'Contact',
  };

  static CrmContactKind fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return switch (normalized) {
      'CLIENT' || 'CUSTOMER' => CrmContactKind.client,
      'VENDOR' || 'SUPPLIER' => CrmContactKind.vendor,
      'ARCHITECT' => CrmContactKind.architect,
      'BUILDER' || 'DEVELOPER' => CrmContactKind.builder,
      _ => CrmContactKind.unknown,
    };
  }
}

enum CrmLeadStage {
  newLead,
  qualified,
  proposal,
  negotiation,
  won,
  lost,
  unknown;

  String get apiValue => switch (this) {
    CrmLeadStage.newLead => 'NEW',
    CrmLeadStage.qualified => 'QUALIFIED',
    CrmLeadStage.proposal => 'PROPOSAL',
    CrmLeadStage.negotiation => 'NEGOTIATION',
    CrmLeadStage.won => 'WON',
    CrmLeadStage.lost => 'LOST',
    CrmLeadStage.unknown => 'UNKNOWN',
  };

  String get label => switch (this) {
    CrmLeadStage.newLead => 'New',
    CrmLeadStage.qualified => 'Qualified',
    CrmLeadStage.proposal => 'Proposal',
    CrmLeadStage.negotiation => 'Negotiation',
    CrmLeadStage.won => 'Won',
    CrmLeadStage.lost => 'Lost',
    CrmLeadStage.unknown => 'Unknown',
  };

  static CrmLeadStage fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return switch (normalized) {
      'NEW' || 'NEW_LEAD' => CrmLeadStage.newLead,
      'QUALIFIED' => CrmLeadStage.qualified,
      'PROPOSAL' => CrmLeadStage.proposal,
      'NEGOTIATION' => CrmLeadStage.negotiation,
      'WON' || 'CONVERTED' => CrmLeadStage.won,
      'LOST' || 'CLOSED_LOST' => CrmLeadStage.lost,
      _ => CrmLeadStage.unknown,
    };
  }
}

enum CrmActivityKind {
  meeting,
  call,
  followUp,
  note,
  unknown;

  String get label => switch (this) {
    CrmActivityKind.meeting => 'Meeting',
    CrmActivityKind.call => 'Call',
    CrmActivityKind.followUp => 'Follow-up',
    CrmActivityKind.note => 'Note',
    CrmActivityKind.unknown => 'Activity',
  };

  static CrmActivityKind fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return switch (normalized) {
      'MEETING' || 'MEETINGS' => CrmActivityKind.meeting,
      'CALL' || 'CALLS' => CrmActivityKind.call,
      'FOLLOW_UP' || 'FOLLOWUP' || 'TASK' => CrmActivityKind.followUp,
      'NOTE' || 'NOTES' => CrmActivityKind.note,
      _ => CrmActivityKind.unknown,
    };
  }
}

class CrmLead {
  const CrmLead({
    required this.id,
    required this.name,
    required this.company,
    required this.stage,
    required this.value,
    required this.email,
    required this.phone,
    required this.source,
    required this.owner,
    required this.nextFollowUp,
    required this.createdAt,
  });

  factory CrmLead.fromJson(Map<String, dynamic> json) => CrmLead(
    id: _string(json['id']),
    name: _string(json['name'] ?? json['contact_name'] ?? json['full_name']),
    company: _string(json['company'] ?? json['company_name']),
    stage: CrmLeadStage.fromApi(json['stage'] ?? json['status']),
    value: _double(json['value'] ?? json['estimated_value'] ?? json['amount']),
    email: _string(json['email']),
    phone: _string(json['phone'] ?? json['mobile']),
    source: _string(json['source']),
    owner: _string(json['owner_name'] ?? json['assigned_to_name']),
    nextFollowUp: _date(json['next_follow_up'] ?? json['next_follow_up_at']),
    createdAt: _date(json['created_at'] ?? json['created']) ?? DateTime.now(),
  );

  final String id;
  final String name;
  final String company;
  final CrmLeadStage stage;
  final double value;
  final String email;
  final String phone;
  final String source;
  final String owner;
  final DateTime? nextFollowUp;
  final DateTime createdAt;
}

class CrmContact {
  const CrmContact({
    required this.id,
    required this.name,
    required this.company,
    required this.kind,
    required this.email,
    required this.phone,
    required this.city,
    required this.gstin,
    required this.status,
  });

  factory CrmContact.fromJson(Map<String, dynamic> json) => CrmContact(
    id: _string(json['id']),
    name: _string(json['name'] ?? json['contact_name'] ?? json['full_name']),
    company: _string(json['company'] ?? json['company_name']),
    kind: CrmContactKind.fromApi(json['kind'] ?? json['type'] ?? json['role']),
    email: _string(json['email']),
    phone: _string(json['phone'] ?? json['mobile']),
    city: _string(json['city'] ?? json['location']),
    gstin: _string(json['gstin'] ?? json['gst_number']),
    status: _string(json['status']),
  );

  final String id;
  final String name;
  final String company;
  final CrmContactKind kind;
  final String email;
  final String phone;
  final String city;
  final String gstin;
  final String status;
}

class CrmActivity {
  const CrmActivity({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.contactName,
    required this.scheduledAt,
    required this.status,
  });

  factory CrmActivity.fromJson(Map<String, dynamic> json) => CrmActivity(
    id: _string(json['id']),
    kind: CrmActivityKind.fromApi(json['kind'] ?? json['type']),
    title: _string(json['title'] ?? json['subject']),
    description: _string(json['description'] ?? json['notes']),
    contactName: _string(json['contact_name'] ?? json['lead_name']),
    scheduledAt: _date(json['scheduled_at'] ?? json['due_at'] ?? json['date']),
    status: _string(json['status']),
  );

  final String id;
  final CrmActivityKind kind;
  final String title;
  final String description;
  final String contactName;
  final DateTime? scheduledAt;
  final String status;
}

class CrmQuotation {
  const CrmQuotation({
    required this.id,
    required this.number,
    required this.title,
    required this.contactName,
    required this.status,
    required this.amount,
    required this.validUntil,
    required this.updatedAt,
  });

  factory CrmQuotation.fromJson(Map<String, dynamic> json) => CrmQuotation(
    id: _string(json['id']),
    number: _string(json['number'] ?? json['quotation_number'] ?? json['quote_no']),
    title: _string(json['title'] ?? json['subject']),
    contactName: _string(json['contact_name'] ?? json['client_name']),
    status: _string(json['status']),
    amount: _double(json['amount'] ?? json['total'] ?? json['grand_total']),
    validUntil: _date(json['valid_until'] ?? json['valid_till']),
    updatedAt: _date(json['updated_at'] ?? json['created_at']),
  );

  final String id;
  final String number;
  final String title;
  final String contactName;
  final String status;
  final double amount;
  final DateTime? validUntil;
  final DateTime? updatedAt;
}

class CrmMetrics {
  const CrmMetrics({
    required this.leads,
    required this.activeClients,
    required this.vendors,
    required this.openFollowUps,
    required this.pipelineValue,
    required this.quotations,
  });

  factory CrmMetrics.fromJson(Map<String, dynamic> json) => CrmMetrics(
    leads: _int(json['leads'] ?? json['lead_count']),
    activeClients: _int(json['active_clients'] ?? json['client_count']),
    vendors: _int(json['vendors'] ?? json['vendor_count']),
    openFollowUps: _int(json['open_follow_ups'] ?? json['follow_up_count']),
    pipelineValue: _double(json['pipeline_value'] ?? json['pipeline_amount']),
    quotations: _int(json['quotations'] ?? json['quotation_count']),
  );

  final int leads;
  final int activeClients;
  final int vendors;
  final int openFollowUps;
  final double pipelineValue;
  final int quotations;
}

class CrmWorkspaceData {
  const CrmWorkspaceData({
    required this.leads,
    required this.clients,
    required this.vendors,
    required this.activities,
    required this.quotations,
    required this.metrics,
    required this.fetchedAt,
    this.workspace = CrmWorkspace.leads,
    this.query = '',
    this.isOffline = false,
    this.apiAvailable = true,
    this.apiMessage,
  });

  factory CrmWorkspaceData.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    bool isOffline = false,
  }) {
    final contacts = _mapList(json['contacts'])
        .map(CrmContact.fromJson)
        .toList(growable: false);
    final clients = _mapList(json['clients'])
        .map(CrmContact.fromJson)
        .toList(growable: false);
    final vendors = _mapList(json['vendors'])
        .map(CrmContact.fromJson)
        .toList(growable: false);
    return CrmWorkspaceData(
      leads: _mapList(json['leads']).map(CrmLead.fromJson).toList(),
      clients: clients.isNotEmpty
          ? clients
          : contacts
                .where((contact) => contact.kind == CrmContactKind.client)
                .toList(),
      vendors: vendors.isNotEmpty
          ? vendors
          : contacts
                .where((contact) => contact.kind == CrmContactKind.vendor)
                .toList(),
      activities: _mapList(
        json['activities'] ?? json['meetings'] ?? json['follow_ups'],
      ).map(CrmActivity.fromJson).toList(),
      quotations: _mapList(
        json['quotations'] ?? json['quotes'],
      ).map(CrmQuotation.fromJson).toList(),
      metrics: CrmMetrics.fromJson(_map(json['metrics'])),
      fetchedAt: fetchedAt ?? DateTime.now(),
      isOffline: isOffline,
    );
  }

  factory CrmWorkspaceData.unavailable({required DateTime fetchedAt}) =>
      CrmWorkspaceData(
        leads: const [],
        clients: const [],
        vendors: const [],
        activities: const [],
        quotations: const [],
        metrics: const CrmMetrics(
          leads: 0,
          activeClients: 0,
          vendors: 0,
          openFollowUps: 0,
          pipelineValue: 0,
          quotations: 0,
        ),
        fetchedAt: fetchedAt,
        apiAvailable: false,
        apiMessage:
            'CRM endpoints are not enabled in the connected FastAPI backend yet.',
      );

  final List<CrmLead> leads;
  final List<CrmContact> clients;
  final List<CrmContact> vendors;
  final List<CrmActivity> activities;
  final List<CrmQuotation> quotations;
  final CrmMetrics metrics;
  final DateTime fetchedAt;
  final CrmWorkspace workspace;
  final String query;
  final bool isOffline;
  final bool apiAvailable;
  final String? apiMessage;

  List<Object> get visibleRecords {
    final normalized = query.trim().toLowerCase();
    final records = switch (workspace) {
      CrmWorkspace.leads => leads,
      CrmWorkspace.clients => clients,
      CrmWorkspace.vendors => vendors,
      CrmWorkspace.activities => activities,
      CrmWorkspace.quotations => quotations,
    };
    if (normalized.isEmpty) return records.cast<Object>();
    return records.where((record) {
      final text = switch (record) {
        CrmLead lead => [lead.name, lead.company, lead.email, lead.phone].join(' '),
        CrmContact contact => [contact.name, contact.company, contact.email, contact.phone].join(' '),
        CrmActivity activity => [activity.title, activity.contactName, activity.description].join(' '),
        CrmQuotation quotation => [quotation.number, quotation.title, quotation.contactName].join(' '),
        _ => '',
      };
      return text.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }

  CrmWorkspaceData copyWith({
    CrmWorkspace? workspace,
    String? query,
    bool? isOffline,
  }) => CrmWorkspaceData(
    leads: leads,
    clients: clients,
    vendors: vendors,
    activities: activities,
    quotations: quotations,
    metrics: metrics,
    fetchedAt: fetchedAt,
    workspace: workspace ?? this.workspace,
    query: query ?? this.query,
    isOffline: isOffline ?? this.isOffline,
    apiAvailable: apiAvailable,
    apiMessage: apiMessage,
  );
}

class CrmLeadInput {
  const CrmLeadInput({
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.source,
    required this.value,
  });

  final String name;
  final String company;
  final String email;
  final String phone;
  final String source;
  final double value;

  Map<String, dynamic> toJson() => {
    'name': name,
    'company': company,
    'email': email.isEmpty ? null : email,
    'phone': phone.isEmpty ? null : phone,
    'source': source.isEmpty ? null : source,
    'estimated_value': value,
  };
}

class CrmContactInput {
  const CrmContactInput({
    required this.kind,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.city,
    required this.gstin,
  });

  final CrmContactKind kind;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String city;
  final String gstin;

  Map<String, dynamic> toJson() => {
    'kind': kind.apiValue,
    'name': name,
    'company': company,
    'email': email.isEmpty ? null : email,
    'phone': phone.isEmpty ? null : phone,
    'city': city.isEmpty ? null : city,
    'gstin': gstin.isEmpty ? null : gstin,
  };
}

class CrmActivityInput {
  const CrmActivityInput({
    required this.kind,
    required this.title,
    required this.description,
    required this.contactId,
    required this.scheduledAt,
  });

  final CrmActivityKind kind;
  final String title;
  final String description;
  final String contactId;
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() => {
    'kind': kind.name.toUpperCase(),
    'title': title,
    'description': description.isEmpty ? null : description,
    'contact_id': contactId.isEmpty ? null : contactId,
    'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
  };
}

class CrmQuotationInput {
  const CrmQuotationInput({
    required this.title,
    required this.contactId,
    required this.amount,
    required this.validUntil,
  });

  final String title;
  final String contactId;
  final double amount;
  final DateTime? validUntil;

  Map<String, dynamic> toJson() => {
    'title': title,
    'contact_id': contactId.isEmpty ? null : contactId,
    'amount': amount,
    'valid_until': validUntil?.toUtc().toIso8601String(),
  };
}

class CrmPermissions {
  const CrmPermissions({required this.role});

  final String role;

  bool get isContractor => role.trim().toUpperCase() == 'CONTRACTOR';
  bool get isSupervisor => role.trim().toUpperCase() == 'SUPERVISOR';
  bool get canWriteLeads => isContractor;
  bool get canWriteContacts => isContractor;
  bool get canWriteActivities => isContractor || isSupervisor;
  bool get canWriteQuotations => isContractor;
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? Map<String, dynamic>.from(value)
    : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

String _string(Object? value) => value == null ? '' : '$value'.trim();

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value')?.toLocal();
}
