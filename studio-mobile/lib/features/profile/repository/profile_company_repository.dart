import 'dart:typed_data';

import '../models/profile_models.dart';

abstract interface class ProfileCompanyRepository {
  Future<ProfileCompanyData> fetchWorkspace();
  Future<ProfileCompanyData> saveBranding(BrandingUpdate input);
  Future<ProfileCompanyData> uploadLogo({
    required Uint8List bytes,
    required String filename,
  });
}
