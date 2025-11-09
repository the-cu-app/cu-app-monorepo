import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_notification_preferences.dart';

class CUNotificationPreferencesService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<CUNotificationPreferences> getPreferences(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/notification-preferences',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CUNotificationPreferences.fromJson(data);
      } else {
        throw Exception('Failed to get preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get preferences: $e');
    }
  }

  Future<Map<String, dynamic>> updatePreferences(
    String financialInstitutionId,
    String memberId,
    Map<String, bool> preferenceStates,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/notification-preferences',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'preferences': preferenceStates,
              'updatedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isUpdated': true, 'preferences': data};
      } else {
        throw Exception('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
