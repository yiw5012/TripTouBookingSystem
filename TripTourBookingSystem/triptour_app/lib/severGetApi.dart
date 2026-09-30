import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:triptour_app/model/country.dart';

class Severgetapi {
  static const String _baseUrl = 'http://192.168.1.126:4000';
  List<Country> countries = [];
  bool isLoading = true;

  static Future<List<Country>> getCountry() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/country"));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          return [];
        }

        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Country.fromJson)
            .toList();
      }

      throw Exception('Failed to load countries: ${response.statusCode}');
    } catch (error) {
      print('Error loading countries: $error');
      return [];
    }
  }

  // =====================================================
  // REVIEW : ดึงคะแนนและรีวิวของทัวร์
  // =====================================================

  static Future<Map<String, dynamic>> getTourReview(int tourId) async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/review/tour/$tourId"),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(res.body);

      return {"statusCode": res.statusCode, "body": data};
    } catch (e) {
      return {
        "statusCode": 500,
        "body": {"success": false, "message": "ไม่สามารถโหลดข้อมูลรีวิวได้"},
      };
    }
  }
}
