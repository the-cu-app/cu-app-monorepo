import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_household_data.dart';

class CUHouseholdService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<CUHouseholdData?> getHouseholdData(
    String financialInstitutionId,
    String householdId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/household/$householdId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUHouseholdData.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get household data: $e');
    }
  }

  Future<void> saveHouseholdData(CUHouseholdData householdData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/household'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': householdData.financialInstitutionId,
        },
        body: jsonEncode(householdData.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to save household data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to save household data: $e');
    }
  }

  Future<void> updateHouseholdData(CUHouseholdData householdData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/household/${householdData.householdId}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': householdData.financialInstitutionId,
        },
        body: jsonEncode(householdData.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update household data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update household data: $e');
    }
  }

  Future<Map<String, dynamic>> verifyHousehold(
    String financialInstitutionId,
    CUHouseholdData householdData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/household/verify'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(householdData.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Household verification failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Household verification failed: $e');
    }
  }

  Future<List<CUHouseholdData>> getAllHouseholds(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/household'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> householdList = data['households'] ?? [];
        return householdList
            .map((json) => CUHouseholdData.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get all households: $e');
    }
  }

  Future<List<CUHouseholdData>> getHouseholdsByMember(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/household/member/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> householdList = data['households'] ?? [];
        return householdList
            .map((json) => CUHouseholdData.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get households by member: $e');
    }
  }

  Future<Map<String, dynamic>> getHouseholdAnalytics(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/household/analytics'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get household analytics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHouseholdHistory(
    String financialInstitutionId,
    String householdId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/household/$householdId/history'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get household history: $e');
    }
  }

  Future<void> recordHouseholdVerification(
    String financialInstitutionId,
    String householdId,
    bool isVerified,
    Map<String, dynamic> verificationData,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/household/$householdId/verification'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'isVerified': isVerified,
          'verificationData': verificationData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to record household verification: $e');
    }
  }

  Future<Map<String, dynamic>> validateHouseholdAddress(
    String financialInstitutionId,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/household/validate-address'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(addressData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Address validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Address validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateHouseholdMember(
    String financialInstitutionId,
    Map<String, dynamic> memberData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/household/validate-member'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(memberData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Member validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Member validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateHouseholdRelationship(
    String financialInstitutionId,
    Map<String, dynamic> relationshipData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/household/validate-relationship'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(relationshipData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Relationship validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Relationship validation failed: $e');
    }
  }

  Future<void> addHouseholdMember(
    String financialInstitutionId,
    String householdId,
    CUHouseholdMember member,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/household/$householdId/members'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(member.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to add household member: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to add household member: $e');
    }
  }

  Future<void> removeHouseholdMember(
    String financialInstitutionId,
    String householdId,
    String memberId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/household/$householdId/members/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove household member: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to remove household member: $e');
    }
  }

  Future<void> updateHouseholdMember(
    String financialInstitutionId,
    String householdId,
    String memberId,
    CUHouseholdMember member,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/household/$householdId/members/$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(member.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update household member: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update household member: $e');
    }
  }
}
