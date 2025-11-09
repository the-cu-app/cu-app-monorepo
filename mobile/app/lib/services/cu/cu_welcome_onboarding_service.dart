import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_welcome_onboarding.dart';

class CUWelcomeOnboardingService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<CUWelcomeOnboarding> getOnboarding(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/welcome-onboarding',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CUWelcomeOnboarding.fromJson(data);
      } else {
        throw Exception('Failed to get onboarding: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get onboarding: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOnboardingSteps(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/onboarding-steps',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['steps'] ?? []);
      } else {
        throw Exception(
          'Failed to get onboarding steps: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get onboarding steps: $e');
    }
  }

  Future<Map<String, dynamic>> completeOnboarding(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/welcome-onboarding/complete',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({'completedAt': DateTime.now().toIso8601String()}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isComplete': true, 'onboarding': data};
      } else {
        throw Exception(
          'Failed to complete onboarding: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
