import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ff_product.dart';

class CUProductService {
  static const String _baseUrl = 'https://api.cu.app/v1';

  Future<List<CUProduct>> getProducts(String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productList = data['products'] ?? [];
        return productList.map((json) => CUProduct.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  Future<CUProduct?> getProduct(
      String financialInstitutionId, String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CUProduct.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<List<CUProduct>> getProductsByCategory(
    String financialInstitutionId,
    String category,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/category/$category'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productList = data['products'] ?? [];
        return productList.map((json) => CUProduct.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  Future<List<CUProduct>> getFeaturedProducts(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/featured'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productList = data['products'] ?? [];
        return productList.map((json) => CUProduct.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get featured products: $e');
    }
  }

  Future<List<CUProduct>> searchProducts(
    String financialInstitutionId,
    String query,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/search?q=${Uri.encodeComponent(query)}'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productList = data['products'] ?? [];
        return productList.map((json) => CUProduct.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<List<String>> getProductCategories(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/categories'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['categories'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get product categories: $e');
    }
  }

  Future<void> createProduct(
      String financialInstitutionId, CUProduct product) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> updateProduct(
      String financialInstitutionId, CUProduct product) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/products/${product.productId}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Credit-Union-ID': financialInstitutionId,
        },
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(
      String financialInstitutionId, String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<Map<String, dynamic>> getProductAnalytics(
      String financialInstitutionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/analytics'),
        headers: {'X-Credit-Union-ID': financialInstitutionId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get product analytics: $e');
    }
  }
}
