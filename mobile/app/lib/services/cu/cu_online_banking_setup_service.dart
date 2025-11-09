import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_online_banking_setup.dart';

class CUOnlineBankingSetupService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<CUOnlineBankingSetup> getSetup(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/online-banking-setup',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CUOnlineBankingSetup.fromJson(data);
      } else {
        throw Exception('Failed to get setup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get setup: $e');
    }
  }

  Future<Map<String, dynamic>> configureSetup(
    String financialInstitutionId,
    String memberId,
    Map<String, dynamic> configuration,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/online-banking-setup',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'configuration': configuration,
              'configuredAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isConfigured': true, 'setup': data};
      } else {
        throw Exception('Failed to configure setup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to configure setup: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
