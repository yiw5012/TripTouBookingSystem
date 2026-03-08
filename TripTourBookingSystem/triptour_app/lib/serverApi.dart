import 'dart:convert';

import 'package:http/http.dart' as http;

class Serverapi {
  static const String _baseUrl = 'http://10.0.2.2:4000';

  static Future<Map<String, dynamic>> checkuser(
    String gmail,
    String google_id,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/checkuser"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"google_id": google_id, "email": gmail}),
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

      final body = jsonDecode(res.body);

      print(body);
      return {'statusCode': res.statusCode, 'body': body};
    } catch (e) {
      print('Registration error: $e');
      return {
        'statusCode': 500,
        'body': {'message': 'Server error'},
      };
    }
  }
}
