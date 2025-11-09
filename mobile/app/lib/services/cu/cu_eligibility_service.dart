import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_eligibility_rules.dart';

class CUEligibilityService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<CUEligibilityRules?> getEligibilityRules(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/rules'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUEligibilityRules.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get eligibility rules: $e');
    }
  }

  Future<void> saveEligibilityRules(CUEligibilityRules rules) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eligibility/rules'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': rules.financialInstitutionId,
        },
        body: jsonEncode(rules.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to save eligibility rules: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to save eligibility rules: $e');
    }
  }

  Future<void> updateEligibilityRules(CUEligibilityRules rules) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/eligibility/rules'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': rules.financialInstitutionId,
        },
        body: jsonEncode(rules.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update eligibility rules: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update eligibility rules: $e');
    }
  }

  Future<Map<String, dynamic>> verifyEligibility(
    String financialInstitutionId,
    CUEligibilityRules rules,
    Map<String, dynamic> memberData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eligibility/verify'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({'rules': rules.toJson(), 'memberData': memberData}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception(
        'Eligibility verification failed: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Eligibility verification failed: $e');
    }
  }

  Future<Map<String, dynamic>> getMemberData(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/member-data'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get member data: $e');
    }
  }

  Future<List<String>> getEligibleStates(String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/states'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['states'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligible states: $e');
    }
  }

  Future<List<String>> getEligibleCounties(
    String financialInstitutionId,
    String state,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/counties/$state'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['counties'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligible counties: $e');
    }
  }

  Future<List<String>> getEligibleEmployers(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/employers'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['employers'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligible employers: $e');
    }
  }

  Future<List<String>> getEligibleOrganizations(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/organizations'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['organizations'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligible organizations: $e');
    }
  }

  Future<Map<String, dynamic>> getEligibilityAnalytics(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/analytics'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get eligibility analytics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEligibilityHistory(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eligibility/history/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligibility history: $e');
    }
  }

  Future<void> recordEligibilityCheck(
    String financialInstitutionId,
    String memberId,
    bool isEligible,
    Map<String, dynamic> checkData,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/eligibility/record-check'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'memberId': memberId,
          'isEligible': isEligible,
          'checkData': checkData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to record eligibility check: $e');
    }
  }

  Future<Map<String, dynamic>> validateAddress(
    String financialInstitutionId,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eligibility/validate-address'),
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

  Future<Map<String, dynamic>> validateEmployment(
    String financialInstitutionId,
    Map<String, dynamic> employmentData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eligibility/validate-employment'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(employmentData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Employment validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Employment validation failed: $e');
    }
  }
}
