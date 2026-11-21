import '../../../core/network/api_service.dart';
import '../models/contractor_application.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) => ApiService.signInSession(email: email, password: password);

  Future<Map<String, dynamic>> currentUser() => ApiService.getCurrentUser();

  Future<Map<String, dynamic>> submitApplication(
    ContractorApplicationInput application,
  ) => ApiService.createCompanyApplication(application.toJson());

  void setToken(String? token) => ApiService.setToken(token);
}
