import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  static const _timeout = Duration(seconds: 45);
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _productionBaseUrl = 'https://api.sitesevapro.in';
  static String? _token;

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      final configured = _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
      return configured.endsWith('/api') ? configured : '$configured/api';
    }
    if (kReleaseMode) return '$_productionBaseUrl/api';
    // Android emulators cannot reach the host via localhost. Physical devices
    // should use --dart-define=API_BASE_URL=http://<lan-ip>:8000/api.
    return Platform.isAndroid
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
  }

  static String? get token => _token;

  static Uri get notificationsWebSocketUri {
    final base = Uri.parse(baseUrl);
    final basePath = base.path.replaceFirst(RegExp(r'/+$'), '');
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '$basePath/notifications/stream',
    );
  }

  static void setToken(String? token) => _token = token;

  static Future<Map<String, dynamic>> signInSession({
    required String email,
    required String password,
  }) async {
    final data =
        await _request(
              'POST',
              '/auth/login',
              authenticated: false,
              body: {'email': email, 'password': password},
            )
            as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'The server did not return a session token.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    _token = token;
    return data;
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final data = await signInSession(email: email, password: password);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async =>
      _map(await _request('GET', '/auth/me'));

  static Future<Map<String, dynamic>> getBootstrap() async =>
      _map(await _request('GET', '/dashboard/bootstrap'));

  static Future<Map<String, dynamic>> getDashboard() async =>
      _map(await _request('GET', '/dashboard'));

  static Future<List<Map<String, dynamic>>> getSites() async =>
      _list(await _request('GET', '/sites'));

  static Future<Map<String, dynamic>> getSite(String id) async =>
      _map(await _request('GET', '/sites/$id'));

  static Future<Map<String, dynamic>> createSite(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/sites', body: body));

  static Future<Map<String, dynamic>> updateSite(
    String id,
    Map<String, dynamic> body,
  ) async => _map(await _request('PUT', '/sites/$id', body: body));

  static Future<void> deleteSite(String id) async =>
      _request('DELETE', '/sites/$id');

  static Future<void> assignSiteSupervisor(
    String siteId,
    String userId,
  ) async => _request(
    'POST',
    '/sites/$siteId/assign-supervisor',
    body: {'user_id': userId},
  );

  static Future<void> assignSiteClient(String siteId, String userId) async =>
      _request(
        'POST',
        '/sites/$siteId/assign-client',
        body: {'user_id': userId},
      );

  static Future<List<Map<String, dynamic>>> getMaterials({
    String? siteId,
  }) async => _list(
    await _request(
      'GET',
      '/materials',
      params: siteId == null ? null : {'site_id': siteId},
    ),
  );

  static Future<Map<String, dynamic>> createMaterial(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/materials', body: body));

  static Future<Map<String, dynamic>> createMaterialTransaction(
    Map<String, dynamic> body,
  ) async =>
      _map(await _request('POST', '/materials/transactions', body: body));

  static Future<List<Map<String, dynamic>>> getMaterialTransactions({
    String? siteId,
  }) async => _list(
    await _request(
      'GET',
      '/materials/transactions',
      params: siteId == null ? null : {'site_id': siteId},
    ),
  );

  static Future<List<Map<String, dynamic>>> getLabour({String? siteId}) async =>
      _list(
        await _request(
          'GET',
          '/labour',
          params: siteId == null ? null : {'site_id': siteId},
        ),
      );

  static Future<Map<String, dynamic>> createLabour(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/labour', body: body));

  static Future<void> deleteLabour(String labourId) async =>
      _request('DELETE', '/labour/$labourId');

  static Future<List<Map<String, dynamic>>> getPayments({
    String? siteId,
  }) async => _list(
    await _request(
      'GET',
      '/payments',
      params: siteId == null ? null : {'site_id': siteId},
    ),
  );

  static Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/payments', body: body));

  static Future<List<Map<String, dynamic>>> getReports({
    String? siteId,
  }) async => _list(
    await _request(
      'GET',
      '/reports',
      params: siteId == null ? null : {'site_id': siteId},
    ),
  );

  static Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/reports', body: body));

  static Future<Map<String, dynamic>> getCloudinarySignature({
    String resourceType = 'image',
    String folder = 'siteseva/reports',
  }) async => _map(
    await _request(
      'GET',
      '/cloudinary/signature',
      params: {'resource_type': resourceType, 'folder': folder},
    ),
  );

  static Future<Map<String, dynamic>> uploadCloudinaryAsset({
    required Uint8List bytes,
    required String filename,
    required Map<String, dynamic> signature,
  }) async {
    final cloudName = '${signature['cloud_name'] ?? ''}'.trim();
    final apiKey = '${signature['api_key'] ?? ''}'.trim();
    final signedValue = '${signature['signature'] ?? ''}'.trim();
    final timestamp = '${signature['timestamp'] ?? ''}'.trim();
    final folder = '${signature['folder'] ?? ''}'.trim();
    final resourceType = '${signature['resource_type'] ?? 'image'}'.trim();
    if ([
      cloudName,
      apiKey,
      signedValue,
      timestamp,
      folder,
    ].any((value) => value.isEmpty)) {
      throw const ApiException(
        'The media upload configuration returned by the server is incomplete.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll({
          'api_key': apiKey,
          'signature': signedValue,
          'timestamp': timestamp,
          'folder': folder,
        })
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? '${decoded['error'] is Map ? decoded['error']['message'] : decoded['message'] ?? 'Media upload failed'}'
            : 'Media upload failed';
        throw ApiException(message, statusCode: response.statusCode);
      }
      return _map(decoded);
    } on SocketException {
      throw const ApiException(
        'SiteSeva could not upload this photo. Check your connection and retry.',
        kind: ApiErrorKind.network,
      );
    } on TimeoutException {
      throw const ApiException(
        'The photo upload took too long. Please retry in a moment.',
        kind: ApiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const ApiException(
        'A secure media connection could not be established.',
        kind: ApiErrorKind.network,
      );
    } on FormatException {
      throw const ApiException(
        'The media service returned an invalid response.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendance({
    required String siteId,
    String? date,
  }) async {
    final params = <String, String>{'site_id': siteId};
    if (date != null) params['date'] = date;
    final response = await _request('GET', '/attendance', params: params);
    if (date != null) return _list(_map(response)['entries']);
    return _list(response);
  }

  static Future<Map<String, dynamic>> getAttendanceDay({
    required String siteId,
    required String date,
  }) async => _map(
    await _request(
      'GET',
      '/attendance',
      params: {'site_id': siteId, 'date': date},
    ),
  );

  static Future<List<Map<String, dynamic>>> getAttendanceHistory(
    String siteId,
  ) async =>
      _list(await _request('GET', '/attendance', params: {'site_id': siteId}));

  static Future<Map<String, dynamic>> markAttendance(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/attendance', body: body));

  static Future<List<Map<String, dynamic>>> getNotifications() async =>
      _list(await _request('GET', '/notifications'));

  static Future<int> getUnreadNotifications() async {
    final response = _map(await _request('GET', '/notifications/unread'));
    return ((response['unread'] ?? response['count']) as num?)?.toInt() ?? 0;
  }

  static Future<void> markNotificationRead(String id) async =>
      _request('PUT', '/notifications/$id/read');

  static Future<void> markAllNotificationsRead() async =>
      _request('PUT', '/notifications/read-all');

  static Future<void> deleteNotification(String id) async =>
      _request('DELETE', '/notifications/$id');

  static Future<void> registerPushDevice({
    required String token,
    required String platform,
  }) async => _request(
    'POST',
    '/notifications/devices',
    body: {'token': token, 'platform': platform},
  );

  static Future<void> unregisterPushDevice(String token) async => _request(
    'POST',
    '/notifications/devices/unregister',
    body: {'token': token},
  );

  static Future<List<Map<String, dynamic>>> getDocuments({
    String? siteId,
    String? kind,
    String? query,
  }) async => _list(
    await _request(
      'GET',
      '/documents',
      params: {
        if (siteId != null && siteId.isNotEmpty) 'site_id': siteId,
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    ),
  );

  static Future<Map<String, dynamic>> createDocument(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/documents', body: body));

  static Future<Map<String, dynamic>> updateDocument(
    String id,
    Map<String, dynamic> body,
  ) async => _map(await _request('PATCH', '/documents/$id', body: body));

  static Future<void> deleteDocument(String id) async =>
      _request('DELETE', '/documents/$id');

  static Future<Uint8List> downloadDocument(String id) => _requestBytes(
    'GET',
    '/documents/$id/download',
    timeout: const Duration(minutes: 2),
  );

  static Future<Map<String, dynamic>> getBranding() async =>
      _map(await _request('GET', '/branding'));

  static Future<Map<String, dynamic>> updateBranding(
    Map<String, dynamic> body,
  ) async => _map(await _request('PUT', '/branding', body: body));

  /// Uploads the workspace logo through the authenticated branding endpoint.
  /// The server returns the refreshed branding document so the client never
  /// has to construct a CDN URL locally.
  static Future<Map<String, dynamic>> uploadBrandingLogo({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/branding/logo');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? '${decoded['detail'] ?? decoded['message'] ?? 'Logo upload failed'}'
            : 'Logo upload failed';
        if (response.statusCode == 401) _token = null;
        throw ApiException(
          message,
          statusCode: response.statusCode,
          kind: response.statusCode == 401 || response.statusCode == 403
              ? ApiErrorKind.authentication
              : ApiErrorKind.server,
        );
      }
      return _map(decoded);
    } on SocketException {
      throw const ApiException(
        'SiteSeva could not upload the company logo. Check your connection and retry.',
        kind: ApiErrorKind.network,
      );
    } on TimeoutException {
      throw const ApiException(
        'The company logo upload took too long. Please retry in a moment.',
        kind: ApiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const ApiException(
        'A secure logo upload connection could not be established.',
        kind: ApiErrorKind.network,
      );
    } on FormatException {
      throw const ApiException(
        'The branding service returned an invalid response.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
  }

  // Contract-ready methods for the next backend slice. These are deliberately
  // not called by the Profile UI until the FastAPI routes are deployed.
  static Future<Map<String, dynamic>> updateCurrentUser(
    Map<String, dynamic> body,
  ) async => _map(await _request('PATCH', '/auth/profile', body: body));

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => _request(
    'PATCH',
    '/auth/password',
    body: {'current_password': currentPassword, 'new_password': newPassword},
  );

  static Future<Map<String, dynamic>> getCompanyProfile() async =>
      _map(await _request('GET', '/company/profile'));

  static Future<Map<String, dynamic>> updateCompanyProfile(
    Map<String, dynamic> body,
  ) async => _map(await _request('PATCH', '/company/profile', body: body));

  static Future<Map<String, dynamic>> getCurrentSubscription() async =>
      _map(await _request('GET', '/subscription/current'));

  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async =>
      _list(await _request('GET', '/subscription/plans'));

  static Future<Map<String, dynamic>> getCompanyPreferences() async =>
      _map(await _request('GET', '/company/preferences'));

  static Future<Map<String, dynamic>> updateCompanyPreferences(
    Map<String, dynamic> body,
  ) async => _map(await _request('PATCH', '/company/preferences', body: body));

  // API-ready contracts. The UI treats a 404 as unavailable until these
  // FastAPI modules are deployed; it never generates local AI answers.
  static Future<Map<String, dynamic>> getAiAssistantConversation() async =>
      _map(await _request('GET', '/ai-assistant/conversation'));

  static Future<Map<String, dynamic>> sendAiAssistantMessage(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/ai-assistant/messages', body: body));

  /// Existing production AI endpoint. It returns server-grounded construction
  /// insight and is used when the conversational module is not deployed.
  static Future<Map<String, dynamic>> getAiInsight(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/ai/insight', body: body));

  static Future<Map<String, dynamic>> getPlanningOverview() async =>
      _map(await _request('GET', '/planning/overview'));

  static Future<Map<String, dynamic>> createPlanningTask(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/planning/tasks', body: body));

  static Future<Map<String, dynamic>> createPlanningSchedule(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/planning/schedule', body: body));

  static Future<Map<String, dynamic>> decidePlanningApproval(
    String approvalId,
    Map<String, dynamic> body,
  ) async => _map(
    await _request(
      'POST',
      '/planning/approvals/$approvalId/decision',
      body: body,
    ),
  );

  static Future<Map<String, dynamic>> requestSubscriptionRenewal() async =>
      _map(await _request('POST', '/subscription/renewal/request'));

  static Future<List<Map<String, dynamic>>> getVendors() async =>
      _list(await _request('GET', '/vendors'));

  static Future<Map<String, dynamic>> createVendor(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/vendors', body: body));

  static Future<void> deleteVendor(String vendorId) async =>
      _request('DELETE', '/vendors/$vendorId');

  // CRM endpoints are kept behind the existing API service so the Flutter
  // contract is ready when the FastAPI CRM module is deployed.
  static Future<Map<String, dynamic>> getCrmOverview({
    String? query,
    String? workspace,
  }) async => _map(
    await _request(
      'GET',
      '/crm/overview',
      params: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (workspace != null && workspace.isNotEmpty) 'workspace': workspace,
      },
    ),
  );

  static Future<Map<String, dynamic>> createCrmLead(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/crm/leads', body: body));

  static Future<Map<String, dynamic>> createCrmContact(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/crm/contacts', body: body));

  static Future<Map<String, dynamic>> createCrmActivity(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/crm/activities', body: body));

  static Future<Map<String, dynamic>> createCrmQuotation(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/crm/quotations', body: body));

  static Future<Map<String, dynamic>> updateCrmActivity(
    String id,
    Map<String, dynamic> body,
  ) async => _map(await _request('PATCH', '/crm/activities/$id', body: body));

  static Future<List<Map<String, dynamic>>> getEstimates() async =>
      _list(await _request('GET', '/estimates'));

  static Future<Map<String, dynamic>> getEstimate(String id) async =>
      _map(await _request('GET', '/estimates/$id'));

  static Future<Map<String, dynamic>> createEstimate(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/estimates', body: body));

  static Future<List<Map<String, dynamic>>> getBoqs() async =>
      _list(await _request('GET', '/boq'));

  static Future<Map<String, dynamic>> getBoq(String id) async =>
      _map(await _request('GET', '/boq/$id'));

  static Future<Map<String, dynamic>> generateBoq(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/boq/generate', body: body));

  static Future<List<Map<String, dynamic>>> getTeam() async =>
      _list(await _request('GET', '/team'));

  static Future<Map<String, dynamic>> getWalletSummary({
    String? siteId,
  }) async => _map(
    await _request(
      'GET',
      '/wallet/summary',
      params: siteId == null ? null : {'site_id': siteId},
    ),
  );

  static Future<Map<String, dynamic>> getLabourWallet(String labourId) async =>
      _map(await _request('GET', '/wallet/$labourId'));

  static Future<Map<String, dynamic>> getWorkforceDetail(
    String labourId,
  ) async => _map(await _request('GET', '/wallet/labour/$labourId'));

  static Future<List<Map<String, dynamic>>> getLabourLedger(
    String labourId,
  ) async => _list(await _request('GET', '/wallet/$labourId/ledger'));

  static Future<Map<String, dynamic>> settleWallet(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/wallet/settle', body: body));

  static Future<List<Map<String, dynamic>>> getPayrollSummary(
    String month,
  ) async => _list(await _request('GET', '/wallet/payroll/$month'));

  static Future<Map<String, dynamic>> generatePayroll(
    String labourId,
    String month,
  ) async => _map(await _request('POST', '/wallet/payroll/$labourId/$month'));

  static Future<List<Map<String, dynamic>>> getDesigns() async =>
      _list(await _request('GET', '/design'));

  static Future<Map<String, dynamic>> createDesign(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/design', body: body));

  static Future<Map<String, dynamic>> generateMap(
    Map<String, dynamic> body,
  ) async => _map(
    await _request(
      'POST',
      '/maps/generate',
      body: body,
      timeout: const Duration(minutes: 3),
    ),
  );

  static Future<Map<String, dynamic>> generateTechnicalDrawing(
    String designId,
    String type,
  ) async => _map(await _request('POST', '/maps/$designId/technical/$type'));

  static Future<Map<String, dynamic>> generate3dConcept(
    String designId,
    int floorNumber,
  ) async => _map(
    await _request(
      'POST',
      '/maps/$designId/3d/$floorNumber',
      timeout: const Duration(minutes: 2),
    ),
  );

  static Future<Uint8List> downloadDesignPdf(
    String designId,
    String drawingType, {
    int floorNumber = 1,
  }) => _requestBytes(
    'GET',
    '/maps/$designId/download/$drawingType.pdf',
    params: {'floor_number': '$floorNumber'},
    timeout: const Duration(minutes: 2),
  );

  static Future<Map<String, dynamic>> getDesign(String id) async =>
      _map(await _request('GET', '/design/$id'));

  static Future<void> deleteDesign(String id) async =>
      _request('DELETE', '/design/$id');

  static Future<Map<String, dynamic>> getDesignWallet() async =>
      _map(await _request('GET', '/design-wallet'));

  static Future<List<Map<String, dynamic>>>
  getDesignWalletTransactions() async =>
      _list(await _request('GET', '/design-wallet/transactions'));

  static Future<Map<String, dynamic>> getDesignWalletPurchaseConfig() async =>
      _map(await _request('GET', '/design-wallet/purchase/config'));

  static Future<Map<String, dynamic>> requestDesignWalletPurchase(
    Map<String, dynamic> body,
  ) async => _map(
    await _request('POST', '/design-wallet/purchase/request', body: body),
  );

  static Future<List<Map<String, dynamic>>>
  getMyDesignWalletPurchases() async =>
      _list(await _request('GET', '/design-wallet/purchase/my'));

  static Future<List<Map<String, dynamic>>> getDesignWalletPurchases({
    String? status,
  }) async => _list(
    await _request(
      'GET',
      '/design-wallet/purchase/admin',
      params: status == null ? null : {'status': status},
    ),
  );

  static Future<List<Map<String, dynamic>>> getCompanyApplications() async =>
      _list(await _request('GET', '/auth/applications', authenticated: false));

  static Future<Map<String, dynamic>> createCompanyApplication(
    Map<String, dynamic> body,
  ) async => _map(
    await _request(
      'POST',
      '/auth/applications',
      authenticated: false,
      body: body,
    ),
  );

  static Future<Map<String, dynamic>> getAdminDashboard() async =>
      _map(await _request('GET', '/admin/dashboard'));

  static Future<List<Map<String, dynamic>>> getAdminContractors({
    int page = 1,
    int limit = 20,
  }) async => _list(
    await _request(
      'GET',
      '/admin/contractors',
      params: {'page': '$page', 'limit': '$limit'},
    ),
  );

  static Future<List<Map<String, dynamic>>> getAdminSubscriptions({
    int page = 1,
    int limit = 20,
  }) async => _list(
    await _request(
      'GET',
      '/admin/subscriptions',
      params: {'page': '$page', 'limit': '$limit'},
    ),
  );

  static Future<Map<String, dynamic>> getAdminAnalytics() async =>
      _map(await _request('GET', '/admin/analytics'));

  static Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> body,
  ) async => _map(await _request('POST', '/expenses', body: body));

  static Future<List<Map<String, dynamic>>> getExpenses({
    String? siteId,
    String? period,
  }) async {
    final params = <String, String>{};
    if (siteId != null) params['site_id'] = siteId;
    if (period != null) params['period'] = period;
    return _list(
      await _request(
        'GET',
        '/expenses',
        params: params.isEmpty ? null : params,
      ),
    );
  }

  static Future<Map<String, dynamic>> getExpenseReport({
    String? siteId,
  }) async => _map(
    await _request(
      'GET',
      '/expenses/report',
      params: siteId == null ? null : {'site_id': siteId},
    ),
  );

  static Future<void> signOut() async => _token = null;

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? params,
    bool authenticated = true,
    Duration timeout = _timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? '${decoded['detail'] ?? decoded['message'] ?? 'Request failed'}'
            : 'Request failed';
        if (response.statusCode == 401) _token = null;
        throw ApiException(
          message,
          statusCode: response.statusCode,
          kind: response.statusCode == 401 || response.statusCode == 403
              ? ApiErrorKind.authentication
              : ApiErrorKind.server,
        );
      }
      return decoded;
    } on SocketException {
      throw ApiException(
        'SiteSeva could not reach the server. Check your connection and API '
        'configuration, then retry.',
        kind: ApiErrorKind.network,
      );
    } on TimeoutException {
      throw ApiException(
        'The server took too long to respond. Please retry in a moment.',
        kind: ApiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const ApiException(
        'A secure connection to SiteSeva could not be established.',
        kind: ApiErrorKind.network,
      );
    } on FormatException {
      throw const ApiException(
        'The server returned an invalid response.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
  }

  static Future<Uint8List> _requestBytes(
    String method,
    String path, {
    Map<String, String>? params,
    Duration timeout = _timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final headers = <String, String>{
      'Accept': 'application/pdf',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Export failed';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            message = '${decoded['detail'] ?? decoded['message'] ?? message}';
          }
        } on FormatException {
          // Binary/error gateway responses do not always contain JSON.
        }
        if (response.statusCode == 401) _token = null;
        throw ApiException(
          message,
          statusCode: response.statusCode,
          kind: response.statusCode == 401 || response.statusCode == 403
              ? ApiErrorKind.authentication
              : ApiErrorKind.server,
        );
      }
      return response.bodyBytes;
    } on SocketException {
      throw const ApiException(
        'SiteSeva could not reach the server for this export.',
        kind: ApiErrorKind.network,
      );
    } on TimeoutException {
      throw const ApiException(
        'The drawing export took too long. Please retry in a moment.',
        kind: ApiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const ApiException(
        'A secure connection to SiteSeva could not be established.',
        kind: ApiErrorKind.network,
      );
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// Supports FastAPI's direct-array responses as well as the paginated
  /// envelopes used by deployed modules. Without this normalization an
  /// otherwise valid `{items: [...]}` response silently rendered as zero rows.
  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
    if (value is Map) {
      for (final key in const [
        'items',
        'data',
        'results',
        'records',
        'notifications',
      ]) {
        final nested = value[key];
        if (nested is List) return _list(nested);
      }
    }
    return const <Map<String, dynamic>>[];
  }
}

enum ApiErrorKind {
  network,
  timeout,
  authentication,
  server,
  invalidResponse,
  configuration,
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.kind = ApiErrorKind.server,
  });
  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  bool get isConnectivityFailure =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;
  bool get isAuthenticationFailure => kind == ApiErrorKind.authentication;

  @override
  String toString() => message;
}
