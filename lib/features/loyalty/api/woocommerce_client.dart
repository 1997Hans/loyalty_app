import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:loyalty_app/core/config/app_config.dart';

/// Client for interacting with the WooCommerce API
class WooCommerceClient {
  final Dio _dio;
  final String _baseUrl = AppConfig.woocommerceBaseUrl;
  final String _consumerKey = AppConfig.woocommerceConsumerKey;
  final String _consumerSecret = AppConfig.woocommerceConsumerSecret;
  final String _authString;

  // Track connection state
  bool _isConnected = false;
  String? _lastError;

  WooCommerceClient()
    : _dio = Dio(),
      _authString = base64Encode(
        utf8.encode(
          '${AppConfig.woocommerceConsumerKey}:${AppConfig.woocommerceConsumerSecret}',
        ),
      ) {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Get connection status
  bool get isConnected => _isConnected;

  /// Get last error message
  String? get lastError => _lastError;

  /// Test the connection to the WooCommerce API
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/system_status',
        options: Options(headers: {'Authorization': 'Basic $_authString'}),
      );

      _isConnected = response.statusCode == 200;
      if (_isConnected) {
        _lastError = null;
      }

      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      print('WooCommerce connection test failed: $e');
      return false;
    }
  }

  /// Get orders for a specific customer
  Future<List<dynamic>> getCustomerOrders(int customerId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/orders',
        queryParameters: {'customer': customerId},
        options: Options(headers: {'Authorization': 'Basic $_authString'}),
      );

      _isConnected = true;
      _lastError = null;

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        _lastError = 'Failed to get orders: HTTP ${response.statusCode}';
        print(_lastError);
        return [];
      }
    } on DioException catch (e) {
      _isConnected = false;
      _lastError = 'Network error: ${e.message}';
      print('WooCommerce API error: ${e.message}');
      return [];
    } catch (e) {
      _isConnected = false;
      _lastError = 'Error: $e';
      print('Unexpected error getting orders: $e');
      return [];
    }
  }

  /// Fetch a specific order by ID
  Future<Map<String, dynamic>> getOrder(int orderId) async {
    try {
      final uri = Uri.parse('$_baseUrl/orders/$orderId');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Basic $_authString'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  /// Create or update loyalty points for a customer via WooCommerce metadata
  Future<bool> updateCustomerLoyaltyPoints(
    int customerId,
    int points, {
    bool overwrite = false,
  }) async {
    try {
      // First, get customer data to retrieve existing points
      final customerUri = Uri.parse('$_baseUrl/customers/$customerId');

      final customerResponse = await http.get(
        customerUri,
        headers: {'Authorization': 'Basic $_authString'},
      );

      if (customerResponse.statusCode != 200) {
        throw Exception(
          'Failed to get customer: ${customerResponse.statusCode} - ${customerResponse.body}',
        );
      }

      final customerData = json.decode(customerResponse.body);
      final List<dynamic> metadata = customerData['meta_data'] ?? [];

      // Check if loyalty points metadata already exists
      int existingPoints = 0;
      int metaDataIndex = -1;

      for (int i = 0; i < metadata.length; i++) {
        if (metadata[i]['key'] == 'loyalty_points') {
          existingPoints = int.tryParse(metadata[i]['value'].toString()) ?? 0;
          metaDataIndex = i;
          break;
        }
      }

      // Calculate new points value
      final newPointsValue = overwrite ? points : existingPoints + points;

      // Prepare the update request
      final Map<String, dynamic> updateData = {
        'meta_data':
            metaDataIndex >= 0
                ? [
                  {
                    'id': metadata[metaDataIndex]['id'],
                    'key': 'loyalty_points',
                    'value': newPointsValue.toString(),
                  },
                ]
                : [
                  {'key': 'loyalty_points', 'value': newPointsValue.toString()},
                ],
      };

      // Update customer metadata
      final updateUri = Uri.parse('$_baseUrl/customers/$customerId');

      final updateResponse = await http.put(
        updateUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_authString',
        },
        body: json.encode(updateData),
      );

      return updateResponse.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating loyalty points: $e');
    }
  }

  /// Get the current loyalty points for a customer
  Future<int> getCustomerLoyaltyPoints(int customerId) async {
    try {
      final uri = Uri.parse('$_baseUrl/customers/$customerId');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Basic $_authString'},
      );

      if (response.statusCode == 200) {
        final customerData = json.decode(response.body);
        final List<dynamic> metadata = customerData['meta_data'] ?? [];

        for (var item in metadata) {
          if (item['key'] == 'loyalty_points') {
            return int.tryParse(item['value'].toString()) ?? 0;
          }
        }

        return 0; // No loyalty points found
      } else {
        throw Exception(
          'Failed to get customer: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching loyalty points: $e');
    }
  }

  /// Get customer details by ID
  Future<Map<String, dynamic>?> getCustomer(int customerId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/customers/$customerId',
        options: Options(headers: {'Authorization': 'Basic $_authString'}),
      );

      _isConnected = true;
      _lastError = null;

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        _lastError = 'Failed to get customer: HTTP ${response.statusCode}';
        print(_lastError);
        return null;
      }
    } on DioException catch (e) {
      _isConnected = false;
      _lastError = 'Network error: ${e.message}';
      print('WooCommerce API error getting customer: ${e.message}');
      return null;
    } catch (e) {
      _isConnected = false;
      _lastError = 'Error: $e';
      print('Unexpected error getting customer: $e');
      return null;
    }
  }
}
