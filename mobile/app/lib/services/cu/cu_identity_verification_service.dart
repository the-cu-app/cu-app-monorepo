import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_identity_verification.dart';

class CUIdentityVerificationService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  // Start identity verification process
  Future<Map<String, dynamic>> startVerification(
    String financialInstitutionId,
    String memberId,
    String provider,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/identity-verification',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'provider': provider,
              'verificationType': 'identity',
              'memberId': memberId,
              'financialInstitutionId': financialInstitutionId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _processVerificationResponse(data, provider);
      } else {
        throw Exception('Failed to start verification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Identity verification service error: $e');
    }
  }

  // Process verification response based on provider
  Map<String, dynamic> _processVerificationResponse(
    Map<String, dynamic> data,
    String provider,
  ) {
    switch (provider.toLowerCase()) {
      case 'lexisnexis':
        return _processLexisNexisResponse(data);
      case 'vouched':
        return _processVouchedResponse(data);
      case 'alloy':
        return _processAlloyResponse(data);
      case 'jumio':
        return _processJumioResponse(data);
      case 'onfido':
        return _processOnfidoResponse(data);
      default:
        return _processGenericResponse(data);
    }
  }

  // Process LexisNexis verification response
  Map<String, dynamic> _processLexisNexisResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationResult'] == 'PASS';
    final score = data['confidenceScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationResult'] == 'FAIL') {
        issues.add('Identity verification failed');
      }
      if (data['verificationResult'] == 'REVIEW') {
        issues.add('Identity requires manual review');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'lexisnexis',
      'issues': issues,
      'verificationData': data,
      'provider': 'LexisNexis',
      'verificationMethod': 'document_verification',
      'documentType': data['documentType'],
      'documentNumber': data['documentNumber'],
      'biometricData': data['biometricData'] ?? {},
      'addressVerification': data['addressVerification'] ?? {},
      'phoneVerification': data['phoneVerification'] ?? {},
      'emailVerification': data['emailVerification'] ?? {},
      'ssnVerification': data['ssnVerification'] ?? {},
      'ofacVerification': data['ofacVerification'] ?? {},
      'pepVerification': data['pepVerification'] ?? {},
      'sanctionsVerification': data['sanctionsVerification'] ?? {},
      'watchlistVerification': data['watchlistVerification'] ?? {},
      'riskAssessment': data['riskAssessment'] ?? {},
      'complianceChecks': data['complianceChecks'] ?? {},
      'verificationId': data['verificationId'],
      'sessionId': data['sessionId'],
      'referenceId': data['referenceId'],
      'auditTrail': data['auditTrail'] ?? {},
      'expiresAt': data['expiresAt'],
      'rejectionReason': data['rejectionReason'],
      'requiredDocuments': List<String>.from(data['requiredDocuments'] ?? []),
      'completedDocuments': List<String>.from(data['completedDocuments'] ?? []),
      'customFields': data['customFields'] ?? {},
      'notes': data['notes'],
    };
  }

  // Process Vouched verification response
  Map<String, dynamic> _processVouchedResponse(Map<String, dynamic> data) {
    final isVerified = data['status'] == 'approved';
    final score = data['confidence']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['status'] == 'rejected') {
        issues.add('Identity verification rejected');
      }
      if (data['status'] == 'pending') {
        issues.add('Identity verification pending');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'vouched',
      'issues': issues,
      'verificationData': data,
      'provider': 'Vouched',
      'verificationMethod': 'document_verification',
      'documentType': data['documentType'],
      'documentNumber': data['documentNumber'],
      'biometricData': data['biometricData'] ?? {},
      'addressVerification': data['addressVerification'] ?? {},
      'phoneVerification': data['phoneVerification'] ?? {},
      'emailVerification': data['emailVerification'] ?? {},
      'ssnVerification': data['ssnVerification'] ?? {},
      'ofacVerification': data['ofacVerification'] ?? {},
      'pepVerification': data['pepVerification'] ?? {},
      'sanctionsVerification': data['sanctionsVerification'] ?? {},
      'watchlistVerification': data['watchlistVerification'] ?? {},
      'riskAssessment': data['riskAssessment'] ?? {},
      'complianceChecks': data['complianceChecks'] ?? {},
      'verificationId': data['verificationId'],
      'sessionId': data['sessionId'],
      'referenceId': data['referenceId'],
      'auditTrail': data['auditTrail'] ?? {},
      'expiresAt': data['expiresAt'],
      'rejectionReason': data['rejectionReason'],
      'requiredDocuments': List<String>.from(data['requiredDocuments'] ?? []),
      'completedDocuments': List<String>.from(data['completedDocuments'] ?? []),
      'customFields': data['customFields'] ?? {},
      'notes': data['notes'],
    };
  }

  // Process Alloy verification response
  Map<String, dynamic> _processAlloyResponse(Map<String, dynamic> data) {
    final isVerified = data['outcome'] == 'approved';
    final score = data['riskScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['outcome'] == 'denied') {
        issues.add('Identity verification denied');
      }
      if (data['outcome'] == 'manual_review') {
        issues.add('Identity requires manual review');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'alloy',
      'issues': issues,
      'verificationData': data,
      'provider': 'Alloy',
      'verificationMethod': 'document_verification',
      'documentType': data['documentType'],
      'documentNumber': data['documentNumber'],
      'biometricData': data['biometricData'] ?? {},
      'addressVerification': data['addressVerification'] ?? {},
      'phoneVerification': data['phoneVerification'] ?? {},
      'emailVerification': data['emailVerification'] ?? {},
      'ssnVerification': data['ssnVerification'] ?? {},
      'ofacVerification': data['ofacVerification'] ?? {},
      'pepVerification': data['pepVerification'] ?? {},
      'sanctionsVerification': data['sanctionsVerification'] ?? {},
      'watchlistVerification': data['watchlistVerification'] ?? {},
      'riskAssessment': data['riskAssessment'] ?? {},
      'complianceChecks': data['complianceChecks'] ?? {},
      'verificationId': data['verificationId'],
      'sessionId': data['sessionId'],
      'referenceId': data['referenceId'],
      'auditTrail': data['auditTrail'] ?? {},
      'expiresAt': data['expiresAt'],
      'rejectionReason': data['rejectionReason'],
      'requiredDocuments': List<String>.from(data['requiredDocuments'] ?? []),
      'completedDocuments': List<String>.from(data['completedDocuments'] ?? []),
      'customFields': data['customFields'] ?? {},
      'notes': data['notes'],
    };
  }

  // Process Jumio verification response
  Map<String, dynamic> _processJumioResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationStatus'] == 'APPROVED_VERIFIED';
    final score = data['confidence']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationStatus'] == 'DENIED_FRAUD') {
        issues.add('Identity verification denied due to fraud');
      }
      if (data['verificationStatus'] == 'DENIED_UNSUPPORTED_ID_TYPE') {
        issues.add('Unsupported ID type');
      }
      if (data['verificationStatus'] == 'DENIED_UNSUPPORTED_ID_COUNTRY') {
        issues.add('Unsupported ID country');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'jumio',
      'issues': issues,
      'verificationData': data,
      'provider': 'Jumio',
      'verificationMethod': 'document_verification',
      'documentType': data['documentType'],
      'documentNumber': data['documentNumber'],
      'biometricData': data['biometricData'] ?? {},
      'addressVerification': data['addressVerification'] ?? {},
      'phoneVerification': data['phoneVerification'] ?? {},
      'emailVerification': data['emailVerification'] ?? {},
      'ssnVerification': data['ssnVerification'] ?? {},
      'ofacVerification': data['ofacVerification'] ?? {},
      'pepVerification': data['pepVerification'] ?? {},
      'sanctionsVerification': data['sanctionsVerification'] ?? {},
      'watchlistVerification': data['watchlistVerification'] ?? {},
      'riskAssessment': data['riskAssessment'] ?? {},
      'complianceChecks': data['complianceChecks'] ?? {},
      'verificationId': data['verificationId'],
      'sessionId': data['sessionId'],
      'referenceId': data['referenceId'],
      'auditTrail': data['auditTrail'] ?? {},
      'expiresAt': data['expiresAt'],
      'rejectionReason': data['rejectionReason'],
      'requiredDocuments': List<String>.from(data['requiredDocuments'] ?? []),
      'completedDocuments': List<String>.from(data['completedDocuments'] ?? []),
      'customFields': data['customFields'] ?? {},
      'notes': data['notes'],
    };
  }

  // Process Onfido verification response
  Map<String, dynamic> _processOnfidoResponse(Map<String, dynamic> data) {
    final isVerified = data['result'] == 'clear';
    final score = data['confidence']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['result'] == 'consider') {
        issues.add('Identity verification requires consideration');
      }
      if (data['result'] == 'unidentified') {
        issues.add('Identity could not be identified');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'onfido',
      'issues': issues,
      'verificationData': data,
      'provider': 'Onfido',
      'verificationMethod': 'document_verification',
      'documentType': data['documentType'],
      'documentNumber': data['documentNumber'],
      'biometricData': data['biometricData'] ?? {},
      'addressVerification': data['addressVerification'] ?? {},
      'phoneVerification': data['phoneVerification'] ?? {},
      'emailVerification': data['emailVerification'] ?? {},
      'ssnVerification': data['ssnVerification'] ?? {},
      'ofacVerification': data['ofacVerification'] ?? {},
      'pepVerification': data['pepVerification'] ?? {},
      'sanctionsVerification': data['sanctionsVerification'] ?? {},
      'watchlistVerification': data['watchlistVerification'] ?? {},
      'riskAssessment': data['riskAssessment'] ?? {},
      'complianceChecks': data['complianceChecks'] ?? {},
      'verificationId': data['verificationId'],
      'sessionId': data['sessionId'],
      'referenceId': data['referenceId'],
      'auditTrail': data['auditTrail'] ?? {},
      'expiresAt': data['expiresAt'],
      'rejectionReason': data['rejectionReason'],
      'requiredDocuments': List<String>.from(data['requiredDocuments'] ?? []),
      'completedDocuments': List<String>.from(data['completedDocuments'] ?? []),
      'customFields': data['customFields'] ?? {},
      'notes': data['notes'],
    };
  }

  // Process generic verification response
  Map<String, dynamic> _processGenericResponse(Map<String, dynamic> data) {
    final isVerified = data['isVerified'] ?? false;
    final score = data['verificationScore']?.toString() ?? '0%';
    final issues = List<String>.from(data['issues'] ?? []);

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'generic',
      'issues': issues,
      'verificationData': data,
      'provider': data['provider'] ?? 'Unknown',
      'verificationMethod':
          data['verificationMethod'] ?? 'document_verification',
      'documentType': data['documentType'],
      'documentNumber': data['documentNumber'],
      'biometricData': data['biometricData'] ?? {},
      'addressVerification': data['addressVerification'] ?? {},
      'phoneVerification': data['phoneVerification'] ?? {},
      'emailVerification': data['emailVerification'] ?? {},
      'ssnVerification': data['ssnVerification'] ?? {},
      'ofacVerification': data['ofacVerification'] ?? {},
      'pepVerification': data['pepVerification'] ?? {},
      'sanctionsVerification': data['sanctionsVerification'] ?? {},
      'watchlistVerification': data['watchlistVerification'] ?? {},
      'riskAssessment': data['riskAssessment'] ?? {},
      'complianceChecks': data['complianceChecks'] ?? {},
      'verificationId': data['verificationId'],
      'sessionId': data['sessionId'],
      'referenceId': data['referenceId'],
      'auditTrail': data['auditTrail'] ?? {},
      'expiresAt': data['expiresAt'],
      'rejectionReason': data['rejectionReason'],
      'requiredDocuments': List<String>.from(data['requiredDocuments'] ?? []),
      'completedDocuments': List<String>.from(data['completedDocuments'] ?? []),
      'customFields': data['customFields'] ?? {},
      'notes': data['notes'],
    };
  }

  // Get existing verifications for a member
  Future<List<CUIdentityVerification>> getVerifications(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/identity-verifications',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final verifications = data['verifications'] as List;
        return verifications
            .map(
              (v) => CUIdentityVerification.fromJson(v as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to get verifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get verifications: $e');
    }
  }

  // Save verification result
  Future<void> saveVerification(CUIdentityVerification verification) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/${verification.financialInstitutionId}/members/${verification.memberId}/identity-verifications',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode(verification.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save verification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save verification: $e');
    }
  }

  // Update verification status
  Future<void> updateVerificationStatus(
    String financialInstitutionId,
    String memberId,
    String verificationId,
    String status,
    String? notes,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/identity-verifications/$verificationId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'verificationStatus': status,
              'notes': notes,
              'updatedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update verification status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  // Get verification providers
  Future<List<String>> getVerificationProviders(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/identity-verification-providers',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['providers'] ?? []);
      } else {
        throw Exception(
          'Failed to get verification providers: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get verification providers: $e');
    }
  }

  // Get authentication token
  Future<String> _getAuthToken() async {
    // This would typically integrate with your authentication system
    // For now, return a placeholder token
    return 'placeholder_auth_token';
  }
}
