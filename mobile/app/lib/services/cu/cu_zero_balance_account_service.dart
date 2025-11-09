import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_zero_balance_account.dart';

class CUZeroBalanceAccountService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<CUZeroBalanceAccount>> getZeroBalanceAccounts(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/zero-balance-accounts',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accounts = data['zeroBalanceAccounts'] as List;
        return accounts
            .map(
              (a) => CUZeroBalanceAccount.fromJson(a as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to get zero balance accounts: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get zero balance accounts: $e');
    }
  }

  Future<Map<String, dynamic>> createZeroBalanceAccount(
    String financialInstitutionId,
    String memberId,
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/zero-balance-accounts',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'accountData': accountData,
              'createdAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isCreated': true, 'account': data};
      } else {
        throw Exception(
          'Failed to create zero balance account: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create zero balance account: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
