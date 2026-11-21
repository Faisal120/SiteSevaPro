import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://10.0.2.2:8000/api',
                  ))
              .replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;
  String? token;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _request('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _request('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _request('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$baseUrl$cleanPath');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 25));
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 25));
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 25));
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 25));
        default:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 25));
      }
    } catch (_) {
      throw ApiException(
        'Server se connection nahi ho paaya. API URL: $baseUrl',
      );
    }

    dynamic payload;
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = response.body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed (${response.statusCode})';
      if (payload is Map && payload['detail'] != null) {
        final detail = payload['detail'];
        message = detail is String ? detail : jsonEncode(detail);
      } else if (payload is String && payload.isNotEmpty) {
        message = payload;
      }
      throw ApiException(message, statusCode: response.statusCode);
    }
    return payload;
  }
}
