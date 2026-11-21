import '../models/material_models.dart';

abstract interface class MaterialsRepository {
  Future<MaterialsStudioData> fetchStudio();
  Future<MaterialItem> createMaterial(MaterialCreationBrief brief);
  Future<MaterialMovement> createMovement(MaterialMovementBrief brief);
  Future<MaterialVendor> createVendor(MaterialVendorBrief brief);
  Future<void> deleteVendor(String vendorId);
}
