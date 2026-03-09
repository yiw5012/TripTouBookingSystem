import 'dart:convert';

import 'package:http/http.dart' as http;

class Serverapi {
  static const String _baseUrl = 'http://10.0.2.2:4000';

  static Future<Map<String, dynamic>> checkuser(
    String google_id,
    String email,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/checkuser"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"google_id": google_id, "email": email}),
      );

      final body = jsonDecode(res.body);

      print(body);

      return {'statusCode': res.statusCode, 'body': body};
    } catch (e) {
      print('Login error: $e');
      return {
        'statusCode': 500,
        'body': {'message': 'Server error'},
      };
    }
  }

  static Future<Map<String, dynamic>> registerUser(
    String google_id,
    String email,
    String firstName,
    String lastName,
    String phone,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "google_id": google_id,
          "email": email,
          "firstname": firstName,
          "lastname": lastName,
          "phone": phone,
        }),
      );

      final data = jsonDecode(res.body);

      print(data);
      return data;
    } catch (e) {
      print('Registration error: $e');
      return {
        'statusCode': 500,
        'body': {'message': 'Server error'},
      };
    }
  }

  static Future<void> sendOtp(String email) async {
    await http.post(
      Uri.parse("$_baseUrl/otp/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/otp/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    print(res.body);
    final data = jsonDecode(res.body);

    return data["success"];
  }

  static Future<bool> resetpassword(String email, String password) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/otp/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(res.body);

    return data["success"];
  }

  static Future<List<dynamic>> getTours() async {
    final response = await http.get(Uri.parse("$_baseUrl/tourAll"));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception("Failed to load tours");
    }
  }
}
