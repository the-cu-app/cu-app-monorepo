import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ff_geographic_rules.dart';

class CUGeographicService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<CUGeographicRules?> getGeographicRules(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/geographic/rules'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUGeographicRules.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get geographic rules: $e');
    }
  }

  Future<void> saveGeographicRules(CUGeographicRules rules) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/rules'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': rules.financialInstitutionId,
        },
        body: jsonEncode(rules.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to save geographic rules: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to save geographic rules: $e');
    }
  }

  Future<void> updateGeographicRules(CUGeographicRules rules) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/geographic/rules'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': rules.financialInstitutionId,
        },
        body: jsonEncode(rules.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update geographic rules: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update geographic rules: $e');
    }
  }

  Future<Map<String, dynamic>> verifyGeographicEligibility(
    String financialInstitutionId,
    CUGeographicRules rules,
    LatLng location,
    String address,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/verify'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'rules': rules.toJson(),
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Geographic verification failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Geographic verification failed: $e');
    }
  }

  Future<Map<String, dynamic>> getLocationInfo(LatLng location) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/location-info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get location info: $e');
    }
  }

  Future<List<String>> getEligibleStates(String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/geographic/states'),
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
        Uri.parse('$_baseUrl/geographic/counties/$state'),
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

  Future<List<String>> getEligibleCities(
    String financialInstitutionId,
    String state,
    String county,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/geographic/cities/$state/$county'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['cities'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligible cities: $e');
    }
  }

  Future<List<String>> getEligibleZipCodes(
    String financialInstitutionId,
    String state,
    String county,
    String city,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/geographic/zip-codes/$state/$county/$city'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['zipCodes'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get eligible ZIP codes: $e');
    }
  }

  Future<Map<String, dynamic>> getGeographicAnalytics(
    String financialInstitutionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/geographic/analytics'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get geographic analytics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGeographicHistory(
    String financialInstitutionId,
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/geographic/history/$memberId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get geographic history: $e');
    }
  }

  Future<void> recordGeographicCheck(
    String financialInstitutionId,
    String memberId,
    LatLng location,
    bool isEligible,
    Map<String, dynamic> checkData,
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/geographic/record-check'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'memberId': memberId,
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'isEligible': isEligible,
          'checkData': checkData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to record geographic check: $e');
    }
  }

  Future<Map<String, dynamic>> validateAddress(
    String financialInstitutionId,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/validate-address'),
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

  Future<Map<String, dynamic>> calculateDistance(
    String financialInstitutionId,
    LatLng fromLocation,
    LatLng toLocation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/calculate-distance'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'fromLocation': {
            'latitude': fromLocation.latitude,
            'longitude': fromLocation.longitude,
          },
          'toLocation': {
            'latitude': toLocation.latitude,
            'longitude': toLocation.longitude,
          },
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Distance calculation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Distance calculation failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyBranches(
    String financialInstitutionId,
    LatLng location,
    double radius,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/nearby-branches'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['branches'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get nearby branches: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyATMs(
    String financialInstitutionId,
    LatLng location,
    double radius,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geographic/nearby-atms'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode({
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['atms'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get nearby ATMs: $e');
    }
  }
}
