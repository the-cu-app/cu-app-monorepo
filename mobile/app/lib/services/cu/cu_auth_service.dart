import 'dart:convert';
import 'package:http/http.dart' as http;

class CUAuthService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<bool> validatePin(String financialInstitutionId, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/validate-pin'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({'pin': pin}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] ?? false;
      }

      return false;
    } catch (e) {
      throw Exception('PIN validation failed: $e');
    }
  }

  Future<bool> validatePassword(
      String financialInstitutionId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/validate-password'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] ?? false;
      }

      return false;
    } catch (e) {
      throw Exception('Password validation failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getLockoutStatus(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/lockout-status'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get lockout status: $e');
    }
  }

  Future<void> clearLockoutStatus(String financialInstitutionId) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/auth/lockout-status'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );
    } catch (e) {
      throw Exception('Failed to clear lockout status: $e');
    }
  }

  Future<void> setLockoutStatus(
    String financialInstitutionId,
    int failedAttempts,
    bool isLockedOut,
    DateTime lockoutEndTime,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/lockout-status'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'failedAttempts': failedAttempts,
          'isLockedOut': isLockedOut,
          'lockoutEndTime': lockoutEndTime.toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to set lockout status: $e');
    }
  }

  Future<void> updateFailedAttempts(
    String financialInstitutionId,
    int failedAttempts,
  ) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/auth/failed-attempts'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({'failedAttempts': failedAttempts}),
      );
    } catch (e) {
      throw Exception('Failed to update failed attempts: $e');
    }
  }

  Future<void> recordSuccessfulAuth(
    String financialInstitutionId,
    String authMethod,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/successful-auth'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'authMethod': authMethod,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to record successful auth: $e');
    }
  }
}
