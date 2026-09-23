import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ServiceBookingApi {
  static const String _baseUrl = 'http://192.168.1.8:4000';

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

  // ส่งไฟล์สลิปโอนเงินชำระเงินจริงไปยัง Server (Multipart Upload)
  static Future<Map<String, dynamic>> uploadSlipFile({
    required int bookingId,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl/api/booking/confirm-payment"),
      );

      // ใส่ fields ข้อมูล text
      request.fields['booking_id'] = bookingId.toString();

      // ใส่ไฟล์รูปภาพสลิป
      request.files.add(
        await http.MultipartFile.fromPath('slip_image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      return {'statusCode': response.statusCode, 'body': body};
    } catch (e) {
      print('Upload slip file error: $e');
      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error: $e'},
      };
    }
  }

  Future<String?> uploadSlipToServer(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl/uploads/upload"),
      );

      // แนบไฟล์ภาพสลิปในฟิลด์ 'slip'
      request.files.add(await http.MultipartFile.fromPath('slip', imagePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['slipUrl']; // ได้ URL รูปภาพ (ยาวไม่เกิน 100-200 ตัวอักษร)
        }
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // static Future<Map<String, dynamic>> createPassernderBooking(Map<String, dynamic> payload) async {

  // }

  //passenger

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

  static Future<Map<String, dynamic>> cancelBookingOrder(int bookingId) async {
    final url = Uri.parse('$_baseUrl/booking/cancel-order');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'booking_id': bookingId}),
    );
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }
}
