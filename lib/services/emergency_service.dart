import 'dart:convert';
import 'package:http/http.dart' as http;

class EmergencyService {
  static const String baseUrl = 'https://disaster-backend-six.vercel.app/api';

  // Create emergency alert
  static Future<Map<String, dynamic>> createAlert({
    required String userId,
    required String token,
    required String type,
    required String message,
    required double latitude,
    required double longitude,
    required String address,
    required double range,
    required String severity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emergency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'type': type,
          'message': message,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'range': range,
          'severity': severity,
        }),
      );

      // Guard against non-JSON responses (HTML error pages)
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Server error (status ${response.statusCode}). Please try again.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create alert (${response.statusCode})',
        };
      }
    } catch (e) {
      print('EmergencyService.createAlert error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Check your internet and try again.',
      };
    }
  }

  // Get nearby alerts
  static Future<Map<String, dynamic>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double range = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/nearby?latitude=$latitude&longitude=$longitude&range=$range&status=ACTIVE'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch alerts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all active alerts
  static Future<Map<String, dynamic>> getAllAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/all?status=ACTIVE&limit=50'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch alerts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
