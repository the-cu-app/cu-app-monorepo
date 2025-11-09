import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_payment_method.dart';

class CUPaymentMethodService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<CUPaymentMethod>> getPaymentMethods(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/payment-methods',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final methods = data['paymentMethods'] as List;
        return methods
            .map((m) => CUPaymentMethod.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to get payment methods: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  Future<Map<String, dynamic>> setupPaymentMethod(
    String financialInstitutionId,
    String memberId,
    String methodType,
    Map<String, dynamic> methodData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/payment-methods',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'methodType': methodType,
              'methodData': methodData,
              'setupAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isSetup': true, 'paymentMethod': data};
      } else {
        throw Exception(
          'Failed to setup payment method: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to setup payment method: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
