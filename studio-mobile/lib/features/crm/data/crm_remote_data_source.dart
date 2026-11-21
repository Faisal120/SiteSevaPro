import '../../../core/network/api_service.dart';
import '../models/crm_models.dart';

abstract interface class CrmRemoteDataSource {
  Future<Map<String, dynamic>> fetchOverview();
  Future<void> createLead(CrmLeadInput input);
  Future<void> createContact(CrmContactInput input);
  Future<void> createActivity(CrmActivityInput input);
  Future<void> createQuotation(CrmQuotationInput input);
  Future<void> completeActivity(String id);
}

class HttpCrmRemoteDataSource implements CrmRemoteDataSource {
  const HttpCrmRemoteDataSource();

  @override
  Future<Map<String, dynamic>> fetchOverview() => ApiService.getCrmOverview();

  @override
  Future<void> createLead(CrmLeadInput input) async {
    await ApiService.createCrmLead(input.toJson());
  }

  @override
  Future<void> createContact(CrmContactInput input) async {
    await ApiService.createCrmContact(input.toJson());
  }

  @override
  Future<void> createActivity(CrmActivityInput input) async {
    await ApiService.createCrmActivity(input.toJson());
  }

  @override
  Future<void> createQuotation(CrmQuotationInput input) async {
    await ApiService.createCrmQuotation(input.toJson());
  }

  @override
  Future<void> completeActivity(String id) async {
    await ApiService.updateCrmActivity(id, {'status': 'COMPLETED'});
  }
}
