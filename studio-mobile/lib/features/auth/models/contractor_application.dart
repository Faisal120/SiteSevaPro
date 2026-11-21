class ContractorApplicationInput {
  const ContractorApplicationInput({
    required this.companyName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.officeAddress,
    required this.city,
    required this.state,
    this.gstNumber,
    this.activeProjects = 0,
    this.employeeCount = 0,
  });

  final String companyName;
  final String ownerName;
  final String mobile;
  final String email;
  final String officeAddress;
  final String city;
  final String state;
  final String? gstNumber;
  final int activeProjects;
  final int employeeCount;

  Map<String, dynamic> toJson() => {
    'company_name': companyName.trim(),
    'owner_name': ownerName.trim(),
    'mobile': mobile.trim(),
    'email': email.trim(),
    'office_address': officeAddress.trim(),
    'city': city.trim(),
    'state': state.trim(),
    'gst_number': gstNumber?.trim().isEmpty == true ? null : gstNumber?.trim(),
    'active_projects': activeProjects,
    'employee_count': employeeCount,
  };
}

class ContractorApplication {
  const ContractorApplication({
    required this.id,
    required this.companyName,
    required this.ownerName,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory ContractorApplication.fromJson(Map<String, dynamic> json) =>
      ContractorApplication(
        id: '${json['id'] ?? ''}',
        companyName: '${json['company_name'] ?? ''}',
        ownerName: '${json['owner_name'] ?? ''}',
        email: '${json['email'] ?? ''}',
        status: '${json['status'] ?? 'PENDING'}',
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      );

  final String id;
  final String companyName;
  final String ownerName;
  final String email;
  final String status;
  final DateTime? createdAt;
}
