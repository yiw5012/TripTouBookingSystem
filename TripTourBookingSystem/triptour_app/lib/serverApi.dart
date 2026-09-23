import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Serverapi {
  static const String _baseUrl = 'http://192.168.1.8:4000';

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
    String first_name,
    String last_name,
    String phone,
    String number_id,
    String birthday,
    String address,
    String gender,
    String medicine,
    String congenital_disease,
    String allergic_list,
    String other, {
    String? imageProfileUrl,
    String? passportUrl,
    List<int>? favoriteCountries,
  }) async {
    try {
      print("REGISTER URL: $_baseUrl/register");

      final res = await http.post(
        Uri.parse("$_baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "google_id": google_id,
          "email": email,
          "first_name": first_name,
          "last_name": last_name,
          "phone": phone,
          "number_id": number_id,
          "birthday": birthday,
          "address": address,
          "gender": gender,
          "medicine": medicine,
          "congenital_disease": congenital_disease,
          "allergic_list": allergic_list,
          "other": other,
          "image_profile": imageProfileUrl,
          "image_passport": passportUrl,
          "favorite_countries": favoriteCountries ?? [],
        }),
      );

      print("Response status: ${res.statusCode}");
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

  static Future<bool> sendOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/otp/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (res.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      print('Send OTP error: $e');
      return false;
    }
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

  static Future<Map<String, dynamic>> getTours() async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/add-tour"),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(res.body);

      print("Get tours: $data");

      return {'statusCode': res.statusCode, 'body': data};
    } catch (e) {
      print('Get tours error: $e');

      return {
        'statusCode': 500,
        'body': {'message': 'Server error'},
      };
    }
  }

  static Future<Map<String, dynamic>> getSearchCountries() async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/add-tour/search-options/countries"),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(res.body);

      print("Search countries: $data");

      return {'statusCode': res.statusCode, 'body': data};
    } catch (e) {
      print("Get search countries error: $e");

      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error'},
      };
    }
  }

  static Future<Map<String, dynamic>?> uploadImage(
    File? selectedImage,
    File? selectedImage_passport,
  ) async {
    if (selectedImage == null && selectedImage_passport == null) {
      print("No image selected for upload. ");
      return null;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$_baseUrl/uploads/upload"),
    );
    if (selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', selectedImage.path),
      );
    }
    if (selectedImage_passport != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'passport',
          selectedImage_passport.path,
        ),
      );
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> data =
            jsonDecode(responseBody) as Map<String, dynamic>;
        print("Image uploaded successfully: $data");
        return {
          'imageUrl': data['imageUrl'],
          'passportUrl': data['passportUrl'],
        };
      } else {
        print("Image upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getSearchAirlines() async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/add-tour/search-options/airlines"),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(res.body);

      print("Search airlines: $data");

      return {'statusCode': res.statusCode, 'body': data};
    } catch (e) {
      print("Get search airlines error: $e");

      return {
        'statusCode': 500,
        'body': {'success': false, 'message': 'Server error'},
      };
    }
  }

  static Future<Map<String, dynamic>> searchTours({
    String? keyword,
    int? countryId,
    List<String>? airlines,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/add-tour/search-tour"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "keyword": keyword,
          "countryId": countryId,
          "airlines": airlines ?? [],
          "startDate": startDate == null
              ? null
              : startDate.toIso8601String().split('T').first,
          "endDate": endDate == null
              ? null
              : endDate.toIso8601String().split('T').first,
        }),
      );

      final data = jsonDecode(res.body);

      print("Search tours: $data");

      return {"statusCode": res.statusCode, "body": data};
    } catch (e) {
      print("Search tours error: $e");

      return {
        "statusCode": 500,
        "body": {"success": false, "message": "Server error"},
      };
    }
  }

  static Future<Map<String, dynamic>?> getMemberDetail(String uid) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/member/detail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'targetUid': uid}),
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

  static Future<Map<String, dynamic>> getTourDetail(int tourId) async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/add-tour/detail/$tourId"),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(res.body);

      print("Tour detail: $data");

      return {"statusCode": res.statusCode, "body": data};
    } catch (e) {
      print("Get tour detail error: $e");

      return {
        "statusCode": 500,
        "body": {"success": false, "message": "Server error"},
      };
    }
  }
}
