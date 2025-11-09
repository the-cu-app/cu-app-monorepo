import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_digital_enrollment.dart';

class CUErollmentService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<CUDigitalEnrollment?> getEnrollment(
    String financialInstitutionId,
    String enrollmentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enrollment/$enrollmentId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUDigitalEnrollment.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get enrollment: $e');
    }
  }

  Future<void> saveEnrollment(CUDigitalEnrollment enrollment) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/enrollment'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': enrollment.financialInstitutionId,
        },
        body: jsonEncode(enrollment.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to save enrollment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save enrollment: $e');
    }
  }

  Future<void> updateEnrollment(CUDigitalEnrollment enrollment) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/enrollment/${enrollment.enrollmentId}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': enrollment.financialInstitutionId,
        },
        body: jsonEncode(enrollment.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update enrollment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update enrollment: $e');
    }
  }

  Future<void> deleteEnrollment(
    String financialInstitutionId,
    String enrollmentId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/enrollment/$enrollmentId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete enrollment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete enrollment: $e');
    }
  }

  Future<List<CUDigitalEnrollment>> getAllEnrollments(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enrollment'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> enrollmentList = data['enrollments'] ?? [];
        return enrollmentList
            .map((json) => CUDigitalEnrollment.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get all enrollments: $e');
    }
  }

  Future<List<CUDigitalEnrollment>> getEnrollmentsByStatus(
    String financialInstitutionId,
    String status,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enrollment/status/$status'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> enrollmentList = data['enrollments'] ?? [];
        return enrollmentList
            .map((json) => CUDigitalEnrollment.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get enrollments by status: $e');
    }
  }

  Future<List<CUDigitalEnrollment>> getEnrollmentsByMember(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enrollment/member/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> enrollmentList = data['enrollments'] ?? [];
        return enrollmentList
            .map((json) => CUDigitalEnrollment.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get enrollments by member: $e');
    }
  }

  Future<void> updateEnrollmentStatus(
    String financialInstitutionId,
    String enrollmentId,
    String status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/enrollment/$enrollmentId/status'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update enrollment status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update enrollment status: $e');
    }
  }

  Future<void> updateApprovalStatus(
    String financialInstitutionId,
    String enrollmentId,
    String approvalStatus,
    String? rejectionReason,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/enrollment/$enrollmentId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'approvalStatus': approvalStatus,
          'rejectionReason': rejectionReason,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update approval status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update approval status: $e');
    }
  }

  Future<Map<String, dynamic>> getEnrollmentAnalytics(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enrollment/analytics'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get enrollment analytics: $e');
    }
  }

  Future<List<String>> getRequiredDocuments(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enrollment/required-documents'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['documents'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get required documents: $e');
    }
  }

  Future<void> uploadDocument(
    String financialInstitutionId,
    String enrollmentId,
    String documentType,
    String documentPath,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/enrollment/$enrollmentId/documents'),
      );

      request.headers.addAll({'X-Credit-Union-ID': financialInstitutionId});

      request.fields['documentType'] = documentType;
      request.files.add(
        await http.MultipartFile.fromPath('document', documentPath),
      );

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }
}
