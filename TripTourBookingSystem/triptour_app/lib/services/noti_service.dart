import 'package:firebase_messaging/firebase_messaging.dart';

class NotiService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ฟังก์ชันช่วยแปลงชื่อประเทศให้เป็นรูปแบบ Topic Name (เช่น "South Korea" -> "country_south_korea")
  static String formatCountryTopic(String countryName) {
    final cleanName = countryName.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );
    return 'country_$cleanName';
  }

  // 1. เรียกใช้ตอน "สมัครสมาชิกสำเร็จ" หรือ "เข้าสู่ระบบ (Login)"
  static Future<void> subscribeToPreferredCountries(
    List<String> countries,
  ) async {
    for (String country in countries) {
      print(country);
      if (country.trim().isNotEmpty) {
        String topic = formatCountryTopic(country);
        await _messaging.subscribeToTopic(topic);
        print('✅ Subscribed to FCM Topic: $topic');
      }
    }
  }

  // 2. เรียกใช้ตอน "ผู้ใช้แก้ไขประเทศที่ชอบในหน้าโปรไฟล์"
  static Future<void> updatePreferredCountries({
    required List<String> oldCountries,
    required List<String> newCountries,
  }) async {
    // หาประเทศที่ผู้ใช้เอาออก -> Unsubscribe
    final removedCountries = oldCountries.where(
      (c) => !newCountries.contains(c),
    );
    for (String country in removedCountries) {
      String topic = formatCountryTopic(country);
      await _messaging.unsubscribeFromTopic(topic);
      print('🚫 Unsubscribed from FCM Topic: $topic');
    }

    // Subscribe ประเทศใหม่ๆ ที่เพิ่มเข้ามา
    await subscribeToPreferredCountries(newCountries);
  }
}
