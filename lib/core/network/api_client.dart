import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage/storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  static const Duration _timeoutDuration = Duration(seconds: 15);

  static Future<Map<String, String>> _headers({
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await StorageService.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static dynamic _decode(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decode(response);
    String message = 'Request failed with status ${response.statusCode}';

    if (body is Map && body['detail'] != null) {
      final detail = body['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List) {
        message = detail
            .map((entry) {
              if (entry is! Map) return entry.toString();
              final location = entry['loc'];
              final field = location is List && location.isNotEmpty
                  ? location.last.toString().replaceAll('_', ' ')
                  : 'request';
              final issue = entry['msg']?.toString() ?? 'Invalid value';
              final readableField = field.isEmpty
                  ? 'Request'
                  : '${field[0].toUpperCase()}${field.substring(1)}';
              return '$readableField: $issue';
            })
            .join('\n');
      } else {
        message = detail.toString();
      }
    } else {
      switch (response.statusCode) {
        case 401:
          message = 'Authentication required. Please log in again.';
          break;
        case 403:
          message = 'Access denied. Insufficient permissions.';
          break;
        case 404:
          message = 'Requested resource not found.';
          break;
        case 422:
          message = 'Validation error. Please check your request.';
          break;
        case 500:
        case 502:
        case 503:
          message = 'Server error. Please try again later.';
          break;
      }
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }

  static Future<dynamic> get(String url, {bool authenticated = true}) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: await _headers(authenticated: authenticated),
          )
          .timeout(_timeoutDuration);

      _checkResponse(response);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}). Failed to connect to server.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}).',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected network error: $e',
      );
    }
  }

  static Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(authenticated: authenticated),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_timeoutDuration);

      _checkResponse(response);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}). Failed to connect to server.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}).',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected network error: $e',
      );
    }
  }

  static Future<dynamic> put(
    String url, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: await _headers(authenticated: authenticated),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_timeoutDuration);

      _checkResponse(response);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}). Failed to connect to server.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}).',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected network error: $e',
      );
    }
  }

  static Future<dynamic> patch(
    String url, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: await _headers(authenticated: authenticated),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_timeoutDuration);

      _checkResponse(response);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}). Failed to connect to server.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}).',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected network error: $e',
      );
    }
  }

  static Future<dynamic> delete(String url, {bool authenticated = true}) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: await _headers(authenticated: authenticated),
          )
          .timeout(_timeoutDuration);

      _checkResponse(response);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}). Failed to connect to server.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${e.message}).',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected network error: $e',
      );
    }
  }

  static Future<List<int>> postBytes(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);
      _checkResponse(response);
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (error) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${error.message}).',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${error.message}).',
      );
    }
  }

  static Future<List<int>> getBytes(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _headers())
          .timeout(_timeoutDuration);
      _checkResponse(response);
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Request timed out. Please check your network connection.',
      );
    } on SocketException catch (error) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${error.message}).',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error (${error.message}).',
      );
    }
  }
}
