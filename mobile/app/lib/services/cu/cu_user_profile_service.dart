import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_user_profile.dart';

class CUUserProfileService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<CUUserProfile> getProfile(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/profile',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CUUserProfile.fromJson(data);
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Map<String, dynamic>> setupProfile(
    String financialInstitutionId,
    String memberId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/profile',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'profileData': profileData,
              'setupAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'isSetup': true, 'profile': data};
      } else {
        throw Exception('Failed to setup profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to setup profile: $e');
    }
  }

  Future<String> _getAuthToken() async {
    return 'placeholder_auth_token';
  }
}
