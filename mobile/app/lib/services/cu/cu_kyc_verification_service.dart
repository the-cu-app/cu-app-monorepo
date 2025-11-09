import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_kyc_verification.dart';

class CUKYCVerificationService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> startVerification(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/kyc-verification',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'memberId': memberId,
              'financialInstitutionId': financialInstitutionId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'isVerified': data['isVerified'] ?? false,
          'verification': data,
        };
      } else {
        throw Exception(
          'Failed to start KYC verification: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('KYC verification service error: $e');
    }
  }

  Future<List<CUKYCVerification>> getVerifications(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/kyc-verifications',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final verifications = data['verifications'] as List;
        return verifications
            .map((v) => CUKYCVerification.fromJson(v as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to get KYC verifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get KYC verifications: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
