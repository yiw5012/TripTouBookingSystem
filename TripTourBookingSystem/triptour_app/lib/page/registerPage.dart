import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/wrapper.dart';

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
      appBar: AppBar(title: const Text("สมัครสมาชิก")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (google_id != null)
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

              const TextField(
                decoration: InputDecoration(
                  labelText: "ชื่อผู้ใช้",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  labelText: "นามสกุล",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
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
                  Get.offAll(() => const Wrapper());
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
      if (google_id == null) {
        if (passwordctl.text.trim().length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร")),
          );
          return;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailctl.text.trim(),
          password: passwordctl.text.trim(),
        );
      }

      Get.offAll(() => const Wrapper());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("สมัครสมาชิกไม่สำเร็จ: $e")));
    }
  }
}
