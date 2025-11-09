import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_signature_capture.dart';

class CUSignatureCaptureService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<CUSignatureCapture>> getSignatures(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/signatures',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final signatures = data['signatures'] as List;
        return signatures
            .map((s) => CUSignatureCapture.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get signatures: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get signatures: $e');
    }
  }

  Future<Map<String, dynamic>> captureSignature(
    String financialInstitutionId,
    String memberId,
    String documentType,
    List<int> signatureData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/signatures',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'documentType': documentType,
              'signatureData': signatureData,
              'signatureFormat': 'png',
              'capturedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isCaptured': true, 'signature': data};
      } else {
        throw Exception('Failed to capture signature: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to capture signature: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
