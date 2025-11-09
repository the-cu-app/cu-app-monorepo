import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_youth_account.dart';

class CUYouthAccountService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<CUYouthAccount>> getYouthAccounts(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/youth-accounts',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accounts = data['youthAccounts'] as List;
        return accounts
            .map((a) => CUYouthAccount.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get youth accounts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get youth accounts: $e');
    }
  }

  Future<Map<String, dynamic>> setupYouthAccount(
    String financialInstitutionId,
    String memberId,
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/youth-accounts',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'accountData': accountData,
              'setupAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isSetup': true, 'account': data};
      } else {
        throw Exception(
          'Failed to setup youth account: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to setup youth account: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
