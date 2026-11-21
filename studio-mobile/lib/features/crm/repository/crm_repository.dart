import '../models/crm_models.dart';

abstract interface class CrmRepository {
  Future<CrmWorkspaceData> fetchWorkspace();
  Future<void> createLead(CrmLeadInput input);
  Future<void> createContact(CrmContactInput input);
  Future<void> createActivity(CrmActivityInput input);
  Future<void> createQuotation(CrmQuotationInput input);
  Future<void> completeActivity(String id);
}
