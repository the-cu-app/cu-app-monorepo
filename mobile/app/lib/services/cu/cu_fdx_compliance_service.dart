import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_fdx_compliance.dart';

class CUFDXComplianceService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<CUFDXCompliance?> getComplianceData(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/compliance/fdx'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUFDXCompliance.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get compliance data: $e');
    }
  }

  Future<void> saveComplianceData(CUFDXCompliance compliance) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': compliance.financialInstitutionId,
        },
        body: jsonEncode(compliance.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to save compliance data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to save compliance data: $e');
    }
  }

  Future<void> updateComplianceData(CUFDXCompliance compliance) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/compliance/fdx'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': compliance.financialInstitutionId,
        },
        body: jsonEncode(compliance.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update compliance data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update compliance data: $e');
    }
  }

  Future<Map<String, dynamic>> runComplianceCheck(
    String financialInstitutionId,
    String fdxVersion,
    List<String> complianceChecks,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/check'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'fdxVersion': fdxVersion,
          'complianceChecks': complianceChecks,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Compliance check failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Compliance check failed: $e');
    }
  }

  Future<List<CUFDXCompliance>> getAllComplianceData(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/compliance/fdx/all'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> complianceList = data['complianceData'] ?? [];
        return complianceList
            .map((json) => CUFDXCompliance.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get all compliance data: $e');
    }
  }

  Future<Map<String, dynamic>> getComplianceAnalytics(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/compliance/fdx/analytics'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get compliance analytics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getComplianceHistory(
    String financialInstitutionId,
    int limit,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/compliance/fdx/history?limit=$limit'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get compliance history: $e');
    }
  }

  Future<void> recordComplianceCheck(
    String financialInstitutionId,
    String fdxVersion,
    bool isCompliant,
    String complianceScore,
    Map<String, dynamic> checkData,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/record-check'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'fdxVersion': fdxVersion,
          'isCompliant': isCompliant,
          'complianceScore': complianceScore,
          'checkData': checkData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to record compliance check: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXEndpoint(
    String financialInstitutionId,
    String endpoint,
    String method,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({'endpoint': endpoint, 'method': method}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Endpoint validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Endpoint validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXDataFormat(
    String financialInstitutionId,
    String dataType,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-data-format'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({'dataType': dataType, 'data': data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Data format validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Data format validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXAuthentication(
    String financialInstitutionId,
    Map<String, dynamic> authData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-authentication'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(authData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception(
        'Authentication validation failed: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Authentication validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXRateLimiting(
    String financialInstitutionId,
    Map<String, dynamic> rateLimitData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-rate-limiting'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(rateLimitData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception(
        'Rate limiting validation failed: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Rate limiting validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXErrorHandling(
    String financialInstitutionId,
    Map<String, dynamic> errorData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-error-handling'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(errorData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception(
        'Error handling validation failed: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error handling validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXDataPrivacy(
    String financialInstitutionId,
    Map<String, dynamic> privacyData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-data-privacy'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(privacyData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Data privacy validation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Data privacy validation failed: $e');
    }
  }

  Future<Map<String, dynamic>> validateFDXAuditLogging(
    String financialInstitutionId,
    Map<String, dynamic> auditData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compliance/fdx/validate-audit-logging'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(auditData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception(
        'Audit logging validation failed: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Audit logging validation failed: $e');
    }
  }
}
