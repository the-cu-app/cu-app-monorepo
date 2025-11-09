import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_verification_status.dart';

class CUVerificationStatusService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<CUVerificationStatus> getStatus(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/verification-status',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CUVerificationStatus.fromJson(data);
      } else {
        throw Exception(
          'Failed to get verification status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get verification status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVerificationSteps(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/verification-steps',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['steps'] ?? []);
      } else {
        throw Exception(
          'Failed to get verification steps: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get verification steps: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
