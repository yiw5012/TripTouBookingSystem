import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceBookingApi {
  static const String _baseUrl = 'http://172.20.10.7:4000';

  static Future<Map<String, dynamic>?> getTourById(String tourId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tourAll/getTourById'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tour_id': tourId}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTourRoundByTourId(
    String tourId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/roundTour/getTourRoundByTourId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tour_id': tourId}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          body is Map &&
          body['success'] == true) {
        return {'statusCode': response.statusCode, 'body': body};
      }

      return {
        'statusCode': response.statusCode,
        'body': body is Map ? body : {'success': false, 'data': []},
      };
    } catch (e) {
      print("Error: $e");
      return {
        'statusCode': 500,
        'body': {'success': false, 'data': []},
      };
    }
  }

  static Future<Map<String, dynamic>?> getRoundById(String roundId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/roundTour/getroundById'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'round_id': roundId}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      return responseData;
    } catch (e) {
      print("Error: $e");
      return {
        'statusCode': 500,
        'body': {'success': false, 'data': []},
      };
    }
  }

  static Future<Map<String, dynamic>> createBookingOrder(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/booking/create-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body);
      return {'statusCode': res.statusCode, 'body': body};
    } catch (e) {
      print('Create booking order error: $e');
      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error: $e'},
      };
    }
  }

  static Future<Map<String, dynamic>> getBookingStatus(
    dynamic bookingId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/api/booking/status/$bookingId"),
        headers: {"Content-Type": "application/json"},
      );

      final body = jsonDecode(res.body);
      return {'statusCode': res.statusCode, 'body': body};
    } catch (e) {
      print('Get booking status error: $e');
      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error: $e'},
      };
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required int bookingId,
    required File slipImageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl/api/booking/confirm-payment"),
      );

      request.fields['booking_id'] = bookingId.toString();
      request.files.add(
        await http.MultipartFile.fromPath('slip_image', slipImageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      return {'statusCode': response.statusCode, 'body': body};
    } catch (e) {
      print('Confirm payment error: $e');
      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error: $e'},
      };
    }
  }

  static Future<Map<String, dynamic>> submitPassengers({
    required Map<String, dynamic> data,
    File? passpot_passenger,
  }) async {
    try {
      final uri = Uri.parse("$_baseUrl/api/booking/add-passengers");

      // กรณีมีไฟล์รูปพาสปอร์ต
      if (passpot_passenger != null && await passpot_passenger.exists()) {
        final request = http.MultipartRequest('POST', uri);

        // ส่งข้อมูล JSON ผ่าน field 'payload'
        request.fields['payload'] = jsonEncode(data);

        // แนบไฟล์รูปภาพพาสปอร์ต
        request.files.add(
          await http.MultipartFile.fromPath(
            'passpot_passenger',
            passpot_passenger.path,
          ),
        );

        final streamedResponse = await request.send();
        final res = await http.Response.fromStream(streamedResponse);
        return {'statusCode': res.statusCode, 'body': jsonDecode(res.body)};
      }

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return {'statusCode': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      print('Submit passengers error: $e');
      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error: $e'},
      };
    }
  }

  static Future<Map<String, dynamic>> cancelBookingOrder({
    required int bookingId,
    required String memberId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/booking/cancel');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'booking_id': bookingId, 'member_id': memberId}),
      );

      final body = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'body': body};
    } catch (e) {
      print('Cancel booking error: $e');
      return {
        'statusCode': 500,
        'body': {
          'success': false,
          'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์: $e',
        },
      };
    }
  }

  static Future<Map<String, dynamic>?> getBookingHistory(
    String memberId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/booking/history/$memberId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer <token>',
        },
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(utf8.decode(response.bodyBytes)),
      };
    } catch (e) {
      debugPrint('Error getBookingHistory: $e');
      return null;
    }
  }
}
