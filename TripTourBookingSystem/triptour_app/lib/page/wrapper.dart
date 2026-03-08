import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
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
    String? google_id = FirebaseAuth.instance.currentUser?.uid;
    String? email = FirebaseAuth.instance.currentUser?.email;

    if (google_id != null && email != null) {
      print("ตรวจสอบผู้ใช้ในระบบ: ID=${google_id}, Email=${email}");
      //ตรวจสอบว่ามีข้อมูลผู้ใช้ในระบบหรือไม่
      var response = await Serverapi.checkuser(email, google_id);
      if (response['body']['status'] == 'exist') {
        //มีข้อมูลผู้ใช้ในระบบแล้ว
        print("ผู้ใช้มีอยู่ในระบบแล้ว: ${response['body']}");
        //เข้าสู่ระบบได้เลย
        return const Homepage();
      } else {
        //ไม่มีข้อมูลผู้ใช้ในระบบ

        print("ผู้ใช้ไม่มีอยู่ในระบบ: ${response['body']}");
        print("ผู้ใช้ใหม่ ไปสมัคร");
        //ถ้าไม่มีข้อมูลผู้ใช้ในระบบหรือข้อมูลไม่สมบูรณ์ ให้ไปหน้า Register เพื่อกรอกข้อมูลเพิ่มเติม
        Get.to(
          () => const RegisterPage(),
          arguments: {"email": email, "google_id": google_id},
        );
      }

      //ถ้ามีแล้วก็เข้าสู่ระบบได้เลย
      //สมัครครั้งแรกก็ให้กรอกข้อมูลให้ครบ แล้วค่อยบันทึกลง database
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
            //ยังไม่ล็อกอิน
            return const LoginPage(); // Replace with your main content widget
          } else {
            //login แล้ว ไปเช็คข้อมูลผู้ใช้ในระบบ
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
