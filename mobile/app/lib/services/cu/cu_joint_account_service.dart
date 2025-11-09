import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_joint_account.dart';

class CUJointAccountService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> createJointAccount(
    String financialInstitutionId,
    String primaryMemberId,
    String secondaryMemberId,
    String accountType,
    String ownershipType,
    String accessLevel,
    String signatureRequired,
    String? notes,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$primaryMemberId/joint-accounts',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'secondaryMemberId': secondaryMemberId,
              'accountType': accountType,
              'ownershipType': ownershipType,
              'accessLevel': accessLevel,
              'signatureRequired': signatureRequired,
              'notes': notes,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isCreated': true, 'jointAccount': data};
      } else {
        throw Exception(
          'Failed to create joint account: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Joint account service error: $e');
    }
  }

  Future<List<CUJointAccount>> getJointAccounts(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/joint-accounts',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accounts = data['jointAccounts'] as List;
        return accounts
            .map((a) => CUJointAccount.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get joint accounts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get joint accounts: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
