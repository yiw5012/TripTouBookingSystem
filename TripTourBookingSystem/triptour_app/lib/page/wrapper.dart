import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/guideHome.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/page/loginPage.dart';
import 'package:triptour_app/page/registerPage.dart';
import 'package:triptour_app/serverApi.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  Future<Widget> checkUser() async {
    // await FirebaseAuth.instance.signOut();
    // await GoogleSignIn().signOut();
    print("process 0");
    String? google_id = FirebaseAuth.instance.currentUser?.uid;
    String? email = FirebaseAuth.instance.currentUser?.email;

    if (google_id != null && email != null) {
      print("ตรวจสอบผู้ใช้ในระบบ: ID=${google_id}, Email=${email}");
      //ตรวจสอบว่ามีข้อมูลผู้ใช้ในระบบหรือไม่
      var response = await Serverapi.checkuser(google_id, email);
      if (response['body']['status'] == 'exist') {
        //มีข้อมูลผู้ใช้ในระบบแล้ว
        print("ผู้ใช้มีอยู่ในระบบแล้ว: ${response['body']}");
        if (response['body']['role'] == 'guide') {
          return const Guidehome();
        }
        //เข้าสู่ระบบได้เลย
        return Homepage();
      } else {
        print(response);
        print("ผู้ใช้ใหม่ ไปสมัคร");

        Future.microtask(() {
          Get.offAll(
            () => const RegisterPage(),
            arguments: {"email": email, "google_id": google_id},
          );
        });

        return const SizedBox();
      }
    }
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            print(FirebaseAuth.instance.currentUser?.email);
            print("ยังไม่ล็อกอิน");
            return const LoginPage(); // Replace with your main content widget
          } else {
            print(FirebaseAuth.instance.currentUser);

            print("login แล้ว ไปเช็คข้อมูลผู้ใช้ในระบบ");
            return FutureBuilder<Widget>(
              future: checkUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                //หลังจากเช็คข้อมูลผู้ใช้ในระบบแล้ว ให้ไปหน้า Homepage
                return snapshot.data!;
              },
            );
          }
        },
      ),
    );
  }
}
