import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Session expired or invalid credentials.'])
      : super(message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Access denied: You are not authorized to view this resource.'])
      : super(message, statusCode: 403);
}

class ApiClient {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _getHeaders());
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach backend server. Please verify your connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach backend server. Please verify your connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyStr = response.body;
    dynamic bodyJson;

    if (bodyStr.isNotEmpty) {
      try {
        bodyJson = jsonDecode(bodyStr);
      } catch (_) {
        bodyJson = bodyStr;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return bodyJson;
    } else if (statusCode == 401) {
      final detail = (bodyJson is Map && bodyJson['detail'] != null)
          ? bodyJson['detail']
          : 'Unauthorized';
      throw UnauthorizedException(detail);
    } else if (statusCode == 403) {
      final detail = (bodyJson is Map && bodyJson['detail'] != null)
          ? bodyJson['detail']
          : 'Access denied: You are restricted to your assigned route/vehicle.';
      throw ForbiddenException(detail);
    } else {
      final detail = (bodyJson is Map && bodyJson['detail'] != null)
          ? bodyJson['detail'].toString()
          : 'HTTP Error $statusCode: $bodyStr';
      throw ApiException(detail, statusCode: statusCode);
    }
  }
}
