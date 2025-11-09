import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_income_verification.dart';

class CUIncomeVerificationService {
  static const String _baseUrl = 'https://api.cu-platform.com/v1';
  static const Duration _timeout = Duration(seconds: 30);

  // Start income verification process
  Future<Map<String, dynamic>> startVerification(
    String financialInstitutionId,
    String memberId,
    String provider,
    double reportedIncome,
    String incomeType,
    String? employerName,
    String? jobTitle,
    String? employmentStatus,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/income-verification',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: jsonEncode({
              'provider': provider,
              'verificationType': 'income',
              'memberId': memberId,
              'financialInstitutionId': financialInstitutionId,
              'reportedIncome': reportedIncome,
              'incomeType': incomeType,
              'employerName': employerName,
              'jobTitle': jobTitle,
              'employmentStatus': employmentStatus,
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
      throw Exception('Income verification service error: $e');
    }
  }

  // Process verification response based on provider
  Map<String, dynamic> _processVerificationResponse(
    Map<String, dynamic> data,
    String provider,
  ) {
    switch (provider.toLowerCase()) {
      case 'plaid':
        return _processPlaidResponse(data);
      case 'mx':
        return _processMXResponse(data);
      case 'yodlee':
        return _processYodleeResponse(data);
      case 'finicity':
        return _processFinicityResponse(data);
      case 'truelayer':
        return _processTrueLayerResponse(data);
      default:
        return _processGenericResponse(data);
    }
  }

  // Process Plaid verification response
  Map<String, dynamic> _processPlaidResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationStatus'] == 'verified';
    final score = data['confidenceScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationStatus'] == 'failed') {
        issues.add('Income verification failed');
      }
      if (data['verificationStatus'] == 'pending') {
        issues.add('Income verification pending');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'plaid',
      'issues': issues,
      'verificationData': data,
      'provider': 'Plaid',
      'verificationMethod': 'bank_account_verification',
      'verifiedIncome': data['verifiedIncome']?.toDouble() ?? 0.0,
      'incomeType': data['incomeType'] ?? 'employment',
      'employerName': data['employerName'],
      'jobTitle': data['jobTitle'],
      'employmentStatus': data['employmentStatus'],
      'employerAddress': data['employerAddress'],
      'employerPhone': data['employerPhone'],
      'employerEmail': data['employerEmail'],
      'supervisorName': data['supervisorName'],
      'supervisorPhone': data['supervisorPhone'],
      'supervisorEmail': data['supervisorEmail'],
      'employmentStartDate': data['employmentStartDate'],
      'employmentEndDate': data['employmentEndDate'],
      'payFrequency': data['payFrequency'],
      'payMethod': data['payMethod'],
      'bankAccountNumber': data['bankAccountNumber'],
      'bankRoutingNumber': data['bankRoutingNumber'],
      'bankName': data['bankName'],
      'bankAddress': data['bankAddress'],
      'bankPhone': data['bankPhone'],
      'bankEmail': data['bankEmail'],
      'incomeSources': List<String>.from(data['incomeSources'] ?? []),
      'verifiedSources': List<String>.from(data['verifiedSources'] ?? []),
      'bankStatementData': data['bankStatementData'] ?? {},
      'paystubData': data['paystubData'] ?? {},
      'taxReturnData': data['taxReturnData'] ?? {},
      'w2Data': data['w2Data'] ?? {},
      'w4Data': data['w4Data'] ?? {},
      'directDepositData': data['directDepositData'] ?? {},
      'payrollData': data['payrollData'] ?? {},
      'benefitsData': data['benefitsData'] ?? {},
      'deductionsData': data['deductionsData'] ?? {},
      'overtimeData': data['overtimeData'] ?? {},
      'bonusData': data['bonusData'] ?? {},
      'commissionData': data['commissionData'] ?? {},
      'tipsData': data['tipsData'] ?? {},
      'selfEmploymentData': data['selfEmploymentData'] ?? {},
      'businessData': data['businessData'] ?? {},
      'investmentData': data['investmentData'] ?? {},
      'rentalData': data['rentalData'] ?? {},
      'retirementData': data['retirementData'] ?? {},
      'disabilityData': data['disabilityData'] ?? {},
      'socialSecurityData': data['socialSecurityData'] ?? {},
      'unemploymentData': data['unemploymentData'] ?? {},
      'otherIncomeData': data['otherIncomeData'] ?? {},
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

  // Process MX verification response
  Map<String, dynamic> _processMXResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationResult'] == 'verified';
    final score = data['confidenceScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationResult'] == 'failed') {
        issues.add('Income verification failed');
      }
      if (data['verificationResult'] == 'pending') {
        issues.add('Income verification pending');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'mx',
      'issues': issues,
      'verificationData': data,
      'provider': 'MX',
      'verificationMethod': 'bank_account_verification',
      'verifiedIncome': data['verifiedIncome']?.toDouble() ?? 0.0,
      'incomeType': data['incomeType'] ?? 'employment',
      'employerName': data['employerName'],
      'jobTitle': data['jobTitle'],
      'employmentStatus': data['employmentStatus'],
      'employerAddress': data['employerAddress'],
      'employerPhone': data['employerPhone'],
      'employerEmail': data['employerEmail'],
      'supervisorName': data['supervisorName'],
      'supervisorPhone': data['supervisorPhone'],
      'supervisorEmail': data['supervisorEmail'],
      'employmentStartDate': data['employmentStartDate'],
      'employmentEndDate': data['employmentEndDate'],
      'payFrequency': data['payFrequency'],
      'payMethod': data['payMethod'],
      'bankAccountNumber': data['bankAccountNumber'],
      'bankRoutingNumber': data['bankRoutingNumber'],
      'bankName': data['bankName'],
      'bankAddress': data['bankAddress'],
      'bankPhone': data['bankPhone'],
      'bankEmail': data['bankEmail'],
      'incomeSources': List<String>.from(data['incomeSources'] ?? []),
      'verifiedSources': List<String>.from(data['verifiedSources'] ?? []),
      'bankStatementData': data['bankStatementData'] ?? {},
      'paystubData': data['paystubData'] ?? {},
      'taxReturnData': data['taxReturnData'] ?? {},
      'w2Data': data['w2Data'] ?? {},
      'w4Data': data['w4Data'] ?? {},
      'directDepositData': data['directDepositData'] ?? {},
      'payrollData': data['payrollData'] ?? {},
      'benefitsData': data['benefitsData'] ?? {},
      'deductionsData': data['deductionsData'] ?? {},
      'overtimeData': data['overtimeData'] ?? {},
      'bonusData': data['bonusData'] ?? {},
      'commissionData': data['commissionData'] ?? {},
      'tipsData': data['tipsData'] ?? {},
      'selfEmploymentData': data['selfEmploymentData'] ?? {},
      'businessData': data['businessData'] ?? {},
      'investmentData': data['investmentData'] ?? {},
      'rentalData': data['rentalData'] ?? {},
      'retirementData': data['retirementData'] ?? {},
      'disabilityData': data['disabilityData'] ?? {},
      'socialSecurityData': data['socialSecurityData'] ?? {},
      'unemploymentData': data['unemploymentData'] ?? {},
      'otherIncomeData': data['otherIncomeData'] ?? {},
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

  // Process Yodlee verification response
  Map<String, dynamic> _processYodleeResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationStatus'] == 'verified';
    final score = data['confidenceScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationStatus'] == 'failed') {
        issues.add('Income verification failed');
      }
      if (data['verificationStatus'] == 'pending') {
        issues.add('Income verification pending');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'yodlee',
      'issues': issues,
      'verificationData': data,
      'provider': 'Yodlee',
      'verificationMethod': 'bank_account_verification',
      'verifiedIncome': data['verifiedIncome']?.toDouble() ?? 0.0,
      'incomeType': data['incomeType'] ?? 'employment',
      'employerName': data['employerName'],
      'jobTitle': data['jobTitle'],
      'employmentStatus': data['employmentStatus'],
      'employerAddress': data['employerAddress'],
      'employerPhone': data['employerPhone'],
      'employerEmail': data['employerEmail'],
      'supervisorName': data['supervisorName'],
      'supervisorPhone': data['supervisorPhone'],
      'supervisorEmail': data['supervisorEmail'],
      'employmentStartDate': data['employmentStartDate'],
      'employmentEndDate': data['employmentEndDate'],
      'payFrequency': data['payFrequency'],
      'payMethod': data['payMethod'],
      'bankAccountNumber': data['bankAccountNumber'],
      'bankRoutingNumber': data['bankRoutingNumber'],
      'bankName': data['bankName'],
      'bankAddress': data['bankAddress'],
      'bankPhone': data['bankPhone'],
      'bankEmail': data['bankEmail'],
      'incomeSources': List<String>.from(data['incomeSources'] ?? []),
      'verifiedSources': List<String>.from(data['verifiedSources'] ?? []),
      'bankStatementData': data['bankStatementData'] ?? {},
      'paystubData': data['paystubData'] ?? {},
      'taxReturnData': data['taxReturnData'] ?? {},
      'w2Data': data['w2Data'] ?? {},
      'w4Data': data['w4Data'] ?? {},
      'directDepositData': data['directDepositData'] ?? {},
      'payrollData': data['payrollData'] ?? {},
      'benefitsData': data['benefitsData'] ?? {},
      'deductionsData': data['deductionsData'] ?? {},
      'overtimeData': data['overtimeData'] ?? {},
      'bonusData': data['bonusData'] ?? {},
      'commissionData': data['commissionData'] ?? {},
      'tipsData': data['tipsData'] ?? {},
      'selfEmploymentData': data['selfEmploymentData'] ?? {},
      'businessData': data['businessData'] ?? {},
      'investmentData': data['investmentData'] ?? {},
      'rentalData': data['rentalData'] ?? {},
      'retirementData': data['retirementData'] ?? {},
      'disabilityData': data['disabilityData'] ?? {},
      'socialSecurityData': data['socialSecurityData'] ?? {},
      'unemploymentData': data['unemploymentData'] ?? {},
      'otherIncomeData': data['otherIncomeData'] ?? {},
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

  // Process Finicity verification response
  Map<String, dynamic> _processFinicityResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationResult'] == 'verified';
    final score = data['confidenceScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationResult'] == 'failed') {
        issues.add('Income verification failed');
      }
      if (data['verificationResult'] == 'pending') {
        issues.add('Income verification pending');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'finicity',
      'issues': issues,
      'verificationData': data,
      'provider': 'Finicity',
      'verificationMethod': 'bank_account_verification',
      'verifiedIncome': data['verifiedIncome']?.toDouble() ?? 0.0,
      'incomeType': data['incomeType'] ?? 'employment',
      'employerName': data['employerName'],
      'jobTitle': data['jobTitle'],
      'employmentStatus': data['employmentStatus'],
      'employerAddress': data['employerAddress'],
      'employerPhone': data['employerPhone'],
      'employerEmail': data['employerEmail'],
      'supervisorName': data['supervisorName'],
      'supervisorPhone': data['supervisorPhone'],
      'supervisorEmail': data['supervisorEmail'],
      'employmentStartDate': data['employmentStartDate'],
      'employmentEndDate': data['employmentEndDate'],
      'payFrequency': data['payFrequency'],
      'payMethod': data['payMethod'],
      'bankAccountNumber': data['bankAccountNumber'],
      'bankRoutingNumber': data['bankRoutingNumber'],
      'bankName': data['bankName'],
      'bankAddress': data['bankAddress'],
      'bankPhone': data['bankPhone'],
      'bankEmail': data['bankEmail'],
      'incomeSources': List<String>.from(data['incomeSources'] ?? []),
      'verifiedSources': List<String>.from(data['verifiedSources'] ?? []),
      'bankStatementData': data['bankStatementData'] ?? {},
      'paystubData': data['paystubData'] ?? {},
      'taxReturnData': data['taxReturnData'] ?? {},
      'w2Data': data['w2Data'] ?? {},
      'w4Data': data['w4Data'] ?? {},
      'directDepositData': data['directDepositData'] ?? {},
      'payrollData': data['payrollData'] ?? {},
      'benefitsData': data['benefitsData'] ?? {},
      'deductionsData': data['deductionsData'] ?? {},
      'overtimeData': data['overtimeData'] ?? {},
      'bonusData': data['bonusData'] ?? {},
      'commissionData': data['commissionData'] ?? {},
      'tipsData': data['tipsData'] ?? {},
      'selfEmploymentData': data['selfEmploymentData'] ?? {},
      'businessData': data['businessData'] ?? {},
      'investmentData': data['investmentData'] ?? {},
      'rentalData': data['rentalData'] ?? {},
      'retirementData': data['retirementData'] ?? {},
      'disabilityData': data['disabilityData'] ?? {},
      'socialSecurityData': data['socialSecurityData'] ?? {},
      'unemploymentData': data['unemploymentData'] ?? {},
      'otherIncomeData': data['otherIncomeData'] ?? {},
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

  // Process TrueLayer verification response
  Map<String, dynamic> _processTrueLayerResponse(Map<String, dynamic> data) {
    final isVerified = data['verificationStatus'] == 'verified';
    final score = data['confidenceScore']?.toString() ?? '0%';
    final issues = <String>[];

    if (!isVerified) {
      if (data['verificationStatus'] == 'failed') {
        issues.add('Income verification failed');
      }
      if (data['verificationStatus'] == 'pending') {
        issues.add('Income verification pending');
      }
    }

    return {
      'isVerified': isVerified,
      'verificationScore': score,
      'verificationType': 'truelayer',
      'issues': issues,
      'verificationData': data,
      'provider': 'TrueLayer',
      'verificationMethod': 'bank_account_verification',
      'verifiedIncome': data['verifiedIncome']?.toDouble() ?? 0.0,
      'incomeType': data['incomeType'] ?? 'employment',
      'employerName': data['employerName'],
      'jobTitle': data['jobTitle'],
      'employmentStatus': data['employmentStatus'],
      'employerAddress': data['employerAddress'],
      'employerPhone': data['employerPhone'],
      'employerEmail': data['employerEmail'],
      'supervisorName': data['supervisorName'],
      'supervisorPhone': data['supervisorPhone'],
      'supervisorEmail': data['supervisorEmail'],
      'employmentStartDate': data['employmentStartDate'],
      'employmentEndDate': data['employmentEndDate'],
      'payFrequency': data['payFrequency'],
      'payMethod': data['payMethod'],
      'bankAccountNumber': data['bankAccountNumber'],
      'bankRoutingNumber': data['bankRoutingNumber'],
      'bankName': data['bankName'],
      'bankAddress': data['bankAddress'],
      'bankPhone': data['bankPhone'],
      'bankEmail': data['bankEmail'],
      'incomeSources': List<String>.from(data['incomeSources'] ?? []),
      'verifiedSources': List<String>.from(data['verifiedSources'] ?? []),
      'bankStatementData': data['bankStatementData'] ?? {},
      'paystubData': data['paystubData'] ?? {},
      'taxReturnData': data['taxReturnData'] ?? {},
      'w2Data': data['w2Data'] ?? {},
      'w4Data': data['w4Data'] ?? {},
      'directDepositData': data['directDepositData'] ?? {},
      'payrollData': data['payrollData'] ?? {},
      'benefitsData': data['benefitsData'] ?? {},
      'deductionsData': data['deductionsData'] ?? {},
      'overtimeData': data['overtimeData'] ?? {},
      'bonusData': data['bonusData'] ?? {},
      'commissionData': data['commissionData'] ?? {},
      'tipsData': data['tipsData'] ?? {},
      'selfEmploymentData': data['selfEmploymentData'] ?? {},
      'businessData': data['businessData'] ?? {},
      'investmentData': data['investmentData'] ?? {},
      'rentalData': data['rentalData'] ?? {},
      'retirementData': data['retirementData'] ?? {},
      'disabilityData': data['disabilityData'] ?? {},
      'socialSecurityData': data['socialSecurityData'] ?? {},
      'unemploymentData': data['unemploymentData'] ?? {},
      'otherIncomeData': data['otherIncomeData'] ?? {},
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
          data['verificationMethod'] ?? 'bank_account_verification',
      'verifiedIncome': data['verifiedIncome']?.toDouble() ?? 0.0,
      'incomeType': data['incomeType'] ?? 'employment',
      'employerName': data['employerName'],
      'jobTitle': data['jobTitle'],
      'employmentStatus': data['employmentStatus'],
      'employerAddress': data['employerAddress'],
      'employerPhone': data['employerPhone'],
      'employerEmail': data['employerEmail'],
      'supervisorName': data['supervisorName'],
      'supervisorPhone': data['supervisorPhone'],
      'supervisorEmail': data['supervisorEmail'],
      'employmentStartDate': data['employmentStartDate'],
      'employmentEndDate': data['employmentEndDate'],
      'payFrequency': data['payFrequency'],
      'payMethod': data['payMethod'],
      'bankAccountNumber': data['bankAccountNumber'],
      'bankRoutingNumber': data['bankRoutingNumber'],
      'bankName': data['bankName'],
      'bankAddress': data['bankAddress'],
      'bankPhone': data['bankPhone'],
      'bankEmail': data['bankEmail'],
      'incomeSources': List<String>.from(data['incomeSources'] ?? []),
      'verifiedSources': List<String>.from(data['verifiedSources'] ?? []),
      'bankStatementData': data['bankStatementData'] ?? {},
      'paystubData': data['paystubData'] ?? {},
      'taxReturnData': data['taxReturnData'] ?? {},
      'w2Data': data['w2Data'] ?? {},
      'w4Data': data['w4Data'] ?? {},
      'directDepositData': data['directDepositData'] ?? {},
      'payrollData': data['payrollData'] ?? {},
      'benefitsData': data['benefitsData'] ?? {},
      'deductionsData': data['deductionsData'] ?? {},
      'overtimeData': data['overtimeData'] ?? {},
      'bonusData': data['bonusData'] ?? {},
      'commissionData': data['commissionData'] ?? {},
      'tipsData': data['tipsData'] ?? {},
      'selfEmploymentData': data['selfEmploymentData'] ?? {},
      'businessData': data['businessData'] ?? {},
      'investmentData': data['investmentData'] ?? {},
      'rentalData': data['rentalData'] ?? {},
      'retirementData': data['retirementData'] ?? {},
      'disabilityData': data['disabilityData'] ?? {},
      'socialSecurityData': data['socialSecurityData'] ?? {},
      'unemploymentData': data['unemploymentData'] ?? {},
      'otherIncomeData': data['otherIncomeData'] ?? {},
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
  Future<List<CUIncomeVerification>> getVerifications(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/income-verifications',
        ),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final verifications = data['verifications'] as List;
        return verifications
            .map(
              (v) => CUIncomeVerification.fromJson(v as Map<String, dynamic>),
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
  Future<void> saveVerification(CUIncomeVerification verification) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/credit-unions/${verification.financialInstitutionId}/members/${verification.memberId}/income-verifications',
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
              '$_baseUrl/credit-unions/$financialInstitutionId/members/$memberId/income-verifications/$verificationId',
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
          '$_baseUrl/credit-unions/$financialInstitutionId/income-verification-providers',
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
