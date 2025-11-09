import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_risk_assessment.dart';

class CURiskAssessmentService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<Map<String, dynamic>>> getRiskQuestions(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/credit-unions/$financialInstitutionId/risk-questions'),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['questions'] ?? []);
      } else {
        throw Exception('Failed to get risk questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get risk questions: $e');
    }
  }

  Future<CURiskAssessment> getAssessment(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/risk-assessment',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CURiskAssessment.fromJson(data);
      } else {
        throw Exception('Failed to get assessment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get assessment: $e');
    }
  }

  Future<Map<String, dynamic>> submitAssessment(
    String financialInstitutionId,
    String memberId,
    Map<String, dynamic> responses,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/risk-assessment',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'responses': responses,
              'submittedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isCompleted': true, 'assessment': data};
      } else {
        throw Exception('Failed to submit assessment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit assessment: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
