import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OptimizedHttpClient {
  static OptimizedHttpClient? _instance;
  late final http.Client _client;

  OptimizedHttpClient._() {
    _client = http.Client();
  }

  factory OptimizedHttpClient() {
    _instance ??= OptimizedHttpClient._();
    return _instance!;
  }

  http.Client get client => _client;

  // Helper methods with retry logic
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final response = await _client.get(url, headers: headers);

        if (response.statusCode >= 500 && retryCount < maxRetries - 1) {
          // Server error, retry with exponential backoff
          await Future.delayed(Duration(seconds: 1 << retryCount));
          retryCount++;
          continue;
        }

        return response;
      } catch (e) {
        if (retryCount < maxRetries - 1) {
          // Network error, retry
          await Future.delayed(Duration(seconds: 1 << retryCount));
          retryCount++;
          continue;
        }
        throw e;
      }
    }

    throw Exception('Max retries exceeded');
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final response = await _client.post(
          url,
          headers: headers,
          body: body,
        );

        if (response.statusCode >= 500 && retryCount < maxRetries - 1) {
          // Server error, retry with exponential backoff
          await Future.delayed(Duration(seconds: 1 << retryCount));
          retryCount++;
          continue;
        }

        return response;
      } catch (e) {
        if (retryCount < maxRetries - 1) {
          // Network error, retry
          await Future.delayed(Duration(seconds: 1 << retryCount));
          retryCount++;
          continue;
        }
        throw e;
      }
    }

    throw Exception('Max retries exceeded');
  }

  void dispose() {
    _client.close();
    _instance = null;
  }
}
