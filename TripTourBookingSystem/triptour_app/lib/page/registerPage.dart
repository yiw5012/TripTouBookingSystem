import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/loginPage.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/serverApi.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailctl = TextEditingController();
  final passwordctl = TextEditingController();
  final firstnamectl = TextEditingController();
  final lastnamectl = TextEditingController();
  final phonectl = TextEditingController();

  String? google_id;

  @override
  void initState() {
    super.initState();
    // รับข้อมูลจากหน้า LoginPage ผ่าน Get.arguments
    final args = Get.arguments;
    if (args != null) {
      emailctl.text = args["email"] ?? "";
      google_id = args["google_id"];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (google_id == null)
                TextField(
                  controller: emailctl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 10),
              if (google_id ==
                  null) // ถ้าไม่ได้มาจาก Google ให้แสดงช่องรหัสผ่าน
                TextField(
                  controller: passwordctl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 20),

              TextField(
                controller: firstnamectl,
                decoration: const InputDecoration(
                  labelText: "ชื่อผู้ใช้",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastnamectl,
                decoration: const InputDecoration(
                  labelText: "นามสกุล",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phonectl,
                decoration: const InputDecoration(
                  labelText: "เบอร์โทรศัพท์",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => signUp(),
                child: const Text("สมัครสมาชิก"),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.offAll(() => const LoginPage());
                },

                child: const Text("NEXT ->"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signUp() async {
    try {
      print(google_id);
      if (google_id == null) {
        if (passwordctl.text.trim().length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร")),
          );
          return;
        }

        print("process 1 - สร้างบัญชีใหม่ด้วย Email/Password");
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailctl.text.trim(),
          password: passwordctl.text.trim(),
        );
        print("สร้างบัญชีสำเร็จ");
        print("process 2 - รับ Google ID จาก Firebase");
        google_id = FirebaseAuth.instance.currentUser?.uid;
      }

      print(
        "process 3 - ลงทะเบียนผู้ใช้ในระบบด้วย Google ID และข้อมูลเพิ่มเติม",
      );
      final result = await Serverapi.registerUser(
        google_id!,
        emailctl.text.trim(),
        firstnamectl.text.trim(),
        lastnamectl.text.trim(),
        phonectl.text.trim(),
      );
      if (result != null && result['status'] == 'success') {
        print("process 4 - ไปหน้า Wrapper เพื่อเช็คข้อมูลผู้ใช้และเข้าสู่ระบบ");
        Get.offAll(() => const Wrapper());
      } else {
        print(result);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกไม่สำเร็จ")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("สมัครสมาชิกไม่สำเร็จ: $e")));
    }
  }
}
