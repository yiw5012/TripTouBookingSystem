import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/registerPage.dart';
import 'package:triptour_app/page/guideHome.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/services/serverApi.dart';

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
      try {
        var response = await Serverapi.checkuser(googleId, email);
        final resBody = response['body'];
        final int statusCode = response['statusCode'] ?? 200;

        // รณีติดสถานะ inactive ( Soft Delete / ถูกระงับบัญชี )
        if (statusCode == 403 ||
            (resBody != null && resBody['status'] == 'inactive')) {
          // ออกจากระบบในระดับ Firebase + Google ทันที
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();

          Future.microtask(() {
            Get.snackbar(
              'เข้าสู่ระบบไม่สำเร็จ',
              resBody?['message'] ??
                  'บัญชีผู้ใช้นี้ถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4),
            );
          });

          return const Homepage();
        }

        //กรณีผู้ใช้เดิมในระบบ (status = 'exist')
        if (resBody != null && resBody['status'] == 'exist') {
          if (resBody['role'] == 'guide') {
            return const Guidehome();
          }
          return const Homepage();
        }

        //กรณีเป็นผู้ใช้ใหม่ (status = 'new')
        if (resBody != null && resBody['status'] == 'new') {
          Future.microtask(() {
            Get.offAll(
              () => const RegisterPage(),
              arguments: {"email": email, "google_id": googleId},
            );
          });
          return const SizedBox();
        }

        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        return const Homepage();
      } catch (e) {
        debugPrint("Check user error in Wrapper: $e");
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        return const Homepage();
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
          // หากยังไม่ได้ล็อกอิน เปิดหน้า Homepage ให้เข้าชมทริปได้เลย
          if (!snapshot.hasData) {
            return const Homepage();
          } else {
            // หากล็อกอินแล้ว เช็กบทบาทและสถานะผู้ใช้
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
