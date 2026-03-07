// import 'dart:convert';

// import 'package:http/http.dart' as http;

// class Serverapi {
//   static const String _baseUrl = 'http://localhost:4000';

//   static Future<Map<String, dynamic>> login(
//     String email,
//     String password,
//   ) async {
//     try {
//       final res = await http.post(
//         Uri.parse("$_baseUrl/login"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"email": email, "password": password}),
//       );
//       final body = jsonDecode(res.body);
//       print(body);
//       return {'statusCode': res.statusCode, 'body': body};
//     } catch (e) {
//       print('Login error: $e');
//       return {
//         'statusCode': 500,
//         'body': {'message': 'Server error'},
//       };
//     }
//   }
// }
