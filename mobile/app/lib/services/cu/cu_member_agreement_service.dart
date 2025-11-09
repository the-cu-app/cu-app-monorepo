import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_member_agreement.dart';

class CUMemberAgreementService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<CUMemberAgreement>> getAgreements(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/credit-unions/$financialInstitutionId/agreements'),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final agreements = data['agreements'] as List;
        return agreements
            .map((a) => CUMemberAgreement.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get agreements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get agreements: $e');
    }
  }

  Future<Map<String, dynamic>> acceptAgreements(
    String financialInstitutionId,
    String memberId,
    Map<String, bool> agreementStates,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/agreements/accept',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'agreementStates': agreementStates,
              'acceptedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isAccepted': true, 'agreement': data};
      } else {
        throw Exception('Failed to accept agreements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to accept agreements: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
