// wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/auth/registerPage.dart';
import 'package:triptour_app/page/guideHome.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/serverApi.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  Future<Widget> checkUser() async {
    String? googleId = FirebaseAuth.instance.currentUser?.uid;
    String? email = FirebaseAuth.instance.currentUser?.email;

    if (googleId != null && email != null) {
      var response = await Serverapi.checkuser(googleId, email);
      if (response['body']['status'] == 'exist') {
        if (response['body']['role'] == 'guide') {
          return const Guidehome();
        }
        return const Homepage();
      } else {
        Future.microtask(() {
          Get.offAll(
            () => const RegisterPage(),
            arguments: {"email": email, "google_id": googleId},
          );
        });
        return const SizedBox();
      }
    }
    return const Homepage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //หากยังไม่ล็อกอิน ให้เปิดหน้า Homepage ให้เข้าชมทริปก่อนได้เลย
          if (!snapshot.hasData) {
            return const Homepage();
          } else {
            //หากล็อกอินแล้ว เช็กบทบาทผู้ใช้ตามปกติ
            return FutureBuilder<Widget>(
              future: checkUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('เกิดข้อผิดพลาดในการตรวจสอบผู้ใช้'),
                  );
                }
                return snapshot.data ?? const Homepage();
              },
            );
          }
        },
      ),
    );
  }
}
