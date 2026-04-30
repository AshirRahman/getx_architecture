// path: lib/core/services/network_caller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';

import '../models/response_data.dart';

class NetworkCaller {
  final int timeoutDuration = 60;

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': token,
      };

  // ===================== GET =====================
  Future<ResponseData> getRequest(String url, {String? token}) async {
    try {
      final response = await get(
        Uri.parse(url),
        headers: _headers(token),
      ).timeout(Duration(seconds: timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================== POST =====================
  Future<ResponseData> postRequest(String url,
      {Map<String, dynamic>? body, String? token}) async {
    try {
      final response = await post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================== PUT =====================
  Future<ResponseData> putRequest(String url,
      {Map<String, dynamic>? body, String? token}) async {
    try {
      final response = await put(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================== PATCH =====================
  Future<ResponseData> patchRequest(String url,
      {Map<String, dynamic>? body, String? token}) async {
    try {
      final response = await patch(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================== DELETE =====================
  Future<ResponseData> deleteRequest(String url,
      {Map<String, dynamic>? body, String? token}) async {
    try {
      final response = await delete(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================== MULTIPART =====================
  Future<ResponseData> multipartRequest(
    String url, {
    required String method,
    Map<String, String>? fields,
    List<File>? files,
    String? token,
  }) async {
    try {
      var request = MultipartRequest(method, Uri.parse(url));

      if (token != null) {
        request.headers['Authorization'] = token;
      }

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        for (File file in files) {
          request.files.add(
            await MultipartFile.fromPath(
              'files', // backend key
              file.path,
            ),
          );
        }
      }

      var streamedResponse =
          await request.send().timeout(Duration(seconds: timeoutDuration));

      final response = await Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================== RESPONSE HANDLER =====================
  ResponseData _handleResponse(Response response) {
    log('Status: ${response.statusCode}');
    log('Body: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ResponseData(
        isSuccess: true,
        statusCode: response.statusCode,
        responseData: decoded,
        errorMessage: '',
      );
    } else if (response.statusCode == 400) {
      return ResponseData(
        isSuccess: false,
        statusCode: response.statusCode,
        responseData: decoded,
        errorMessage: _extractErrorMessages(decoded['errorSources']),
      );
    } else {
      return ResponseData(
        isSuccess: false,
        statusCode: response.statusCode,
        responseData: decoded,
        errorMessage: decoded['message'] ?? 'Something went wrong',
      );
    }
  }

  // ===================== ERROR HANDLER =====================
  ResponseData _handleError(dynamic error) {
    log('Error: $error');

    if (error is ClientException) {
      return ResponseData(
        isSuccess: false,
        statusCode: 500,
        responseData: '',
        errorMessage: 'Network error. Check internet.',
      );
    } else if (error is TimeoutException) {
      return ResponseData(
        isSuccess: false,
        statusCode: 408,
        responseData: '',
        errorMessage: 'Request timeout.',
      );
    } else {
      return ResponseData(
        isSuccess: false,
        statusCode: 500,
        responseData: '',
        errorMessage: 'Unexpected error occurred.',
      );
    }
  }

  String _extractErrorMessages(dynamic errorSources) {
    if (errorSources is List) {
      return errorSources.map((e) => e['message'] ?? 'Error').join(', ');
    }
    return 'Validation error';
  }
}
