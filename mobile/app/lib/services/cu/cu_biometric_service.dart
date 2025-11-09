import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_biometric_data.dart';

class CUBiometricService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<CUBiometricData?> getBiometricData(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/biometric/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUBiometricData.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get biometric data: $e');
    }
  }

  Future<void> saveBiometricData(CUBiometricData biometricData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/biometric'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': biometricData.financialInstitutionId,
        },
        body: jsonEncode(biometricData.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to save biometric data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to save biometric data: $e');
    }
  }

  Future<void> updateBiometricData(CUBiometricData biometricData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/biometric/${biometricData.memberId}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': biometricData.financialInstitutionId,
        },
        body: jsonEncode(biometricData.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update biometric data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update biometric data: $e');
    }
  }

  Future<void> deleteBiometricData(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/biometric/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete biometric data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete biometric data: $e');
    }
  }

  Future<List<CUBiometricData>> getAllBiometricData(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/biometric'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> biometricList = data['biometricData'] ?? [];
        return biometricList
            .map((json) => CUBiometricData.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get all biometric data: $e');
    }
  }

  Future<bool> validateBiometric(
    String financialInstitutionId,
    String memberId,
    String biometricHash,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/biometric/validate'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'memberId': memberId,
          'biometricHash': biometricHash,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] ?? false;
      }

      return false;
    } catch (e) {
      throw Exception('Biometric validation failed: $e');
    }
  }

  Future<void> recordBiometricUsage(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/biometric/usage'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'memberId': memberId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to record biometric usage: $e');
    }
  }
}
