import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';
import 'package:triptour_app/page/Tourdetail/tour/tourDetailSection.dart';
import 'package:triptour_app/page/homepage.dart';
import 'firebase_options.dart';

final localNotifications = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const androidChannel = AndroidNotificationChannel(
  'default',
  'General Notifications',
  description: 'General app notifications',
  importance: Importance.high,
);

//  Background Message Handler สำหรับ FCM (ต้องเป็น Top-level Function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void _navigateToTourDetail(String tourId) {
  final tour_id = tourId.hashCode;
  if (tourId.isNotEmpty) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => DetailTour(tourId: tour_id)),
    );
  }
}

// ตั้งค่าระบบ Notification ทั้งหมด
Future<void> setupNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // ขอสิทธิ์การแจ้งเตือน
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // ตั้งค่า Initial Settings สำหรับ Android / iOS
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: DarwinInitializationSettings(),
  );

  // เริ่มต้นทำงาน Local Notifications
  await localNotifications.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null && response.payload!.isNotEmpty) {
        // เมื่อผู้ใช้กด Local Notification ตอนเปิดแอปอยู่
        _navigateToTourDetail(response.payload!);
      }
    },
  );

  // สร้าง Channel ใน Android
  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(androidChannel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    var notification = message.notification;

    String title =
        notification?.title ?? message.data['title'] ?? 'แจ้งเตือนใหม่';
    String body =
        notification?.body ?? message.data['body'] ?? 'คุณได้รับข้อความใหม่';
    String? tourId = message.data['tour_id']?.toString();

    localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: tourId, // แนบ tour_id เพื่อนำไปเปิดหน้าทัวร์เมื่อกด
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.containsKey('tour_id')) {
      _navigateToTourDetail(message.data['tour_id'].toString());
    }
  });

  //ปิดแอพ แต่ยังล็อกอิน
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null && initialMessage.data.containsKey('tour_id')) {
    _navigateToTourDetail(initialMessage.data['tour_id'].toString());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ผูก Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await setupNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TripTour App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Homepage(),
    );
  }
}
