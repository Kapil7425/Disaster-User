// CLEAN REWRITE - single class, no duplicates
import 'dart:convert';
import 'dart:async';
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
      print('📡 Sending emergency alert to: $baseUrl/emergency');
      print('📋 Payload: userId=$userId, type=$type, lat=$latitude, lng=$longitude, range=$range');

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
      ).timeout(const Duration(seconds: 30));

      print('📨 Response status: \${response.statusCode}');
      print('📨 Response body: \${response.body.substring(0, response.body.length.clamp(0, 300))}');

      // Guard against non-JSON responses (HTML error pages)
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Server error (HTTP \${response.statusCode}). Backend may be restarting, please try again in 30 seconds.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ Alert created successfully');
        return {
          'success': true,
          'data': data,
          'notifiedCount': data['notifiedCount'] ?? 0,
        };
      } else {
        print('❌ Alert creation failed: \${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create alert (HTTP \${response.statusCode})',
          'error': data['error'] ?? '',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Check your internet connection and try again.',
      };
    } catch (e) {
      print('🔥 EmergencyService.createAlert exception: $e');
      return {
        'success': false,
        'message': 'Connection failed: \${e.toString().split(":").last.trim()}',
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
        Uri.parse(
            '$baseUrl/emergency/nearby?latitude=$latitude&longitude=$longitude&range=$range&status=ACTIVE'),
      ).timeout(const Duration(seconds: 15));

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {'success': false, 'message': 'Server error', 'data': []};
      }

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
          'message': data['message'] ?? 'Failed to get alerts',
          'data': [],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error', 'data': []};
    }
  }

  // Get all alerts (for dashboard)
  static Future<Map<String, dynamic>> getAllAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/all?status=ACTIVE&limit=50'),
      ).timeout(const Duration(seconds: 15));

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {'success': false, 'data': []};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      }
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }
}
