import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_terms_acceptance.dart';

class CUTermsAcceptanceService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<CUTermsAcceptance>> getTerms(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/credit-unions/$financialInstitutionId/terms'),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final terms = data['terms'] as List;
        return terms
            .map((t) => CUTermsAcceptance.fromJson(t as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get terms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get terms: $e');
    }
  }

  Future<Map<String, dynamic>> acceptTerms(
    String financialInstitutionId,
    String memberId,
    Map<String, bool> acceptanceStates,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/terms/accept',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'acceptanceStates': acceptanceStates,
              'acceptedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'isAccepted': true,
          'acceptance': data,
        };
      } else {
        throw Exception('Failed to accept terms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to accept terms: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
