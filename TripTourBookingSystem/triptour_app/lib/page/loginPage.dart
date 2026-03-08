import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/page/registerPage.dart';
import 'package:triptour_app/serverApi.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailctl = TextEditingController();
  final passwordctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      backgroundColor: Colors.grey,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.asset("assets/images/login.png", height: 200),

              const SizedBox(height: 20),

              TextField(
                controller: emailctl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: passwordctl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// LOGIN EMAIL
              ElevatedButton(
                onPressed: () => signInEmail(),
                child: const Text("เข้าสู่ระบบ"),
              ),

              const SizedBox(height: 10),

              /// GOOGLE LOGIN
              ElevatedButton(
                onPressed: () async {
                  final userCredential = await signInWithGoogle();
                  if (userCredential != null) {
                    String? google_id = userCredential.user?.uid;
                    String? gmail = userCredential.user?.email;

                    print(
                      "เข้าสู่ระบบด้วย Google สำเร็จ: ${google_id}, ${gmail}",
                    );
                    //insert google , email  to database
                    //defult role = user
                    if (google_id != null && gmail != null) {
                      //ตรวจสอบว่ามีข้อมูลผู้ใช้ในระบบหรือไม่
                      Serverapi.checkuser(gmail, google_id).then((response) {
                        if (response['statusCode'] == 200) {
                          //มีข้อมูลผู้ใช้ในระบบแล้ว
                          print("ผู้ใช้มีอยู่ในระบบแล้ว: ${response['body']}");
                          //เข้าสู่ระบบได้เลย
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Homepage(),
                            ),
                          );
                        } else {
                          //ไม่มีข้อมูลผู้ใช้ในระบบ
                          print("ผู้ใช้ไม่มีอยู่ในระบบ: ${response['body']}");
                          //ให้ไปกรอกข้อมูลเพิ่มเติมเพื่อสมัครสมาชิก
                          callRegister();
                        }
                      });
                      //ถ้ามีแล้วก็เข้าสู่ระบบได้เลย
                      //สมัครครั้งแรกก็ให้กรอกข้อมูลให้ครบ แล้วค่อยบันทึกลง database
                      print(
                        "ข้อมูลผู้ใช้ Google สมบูรณ์: ID=${google_id}, Email=${gmail}",
                      );
                    } else {
                      print(
                        "ข้อมูลผู้ใช้ Google ไม่สมบูรณ์: ID=${google_id}, Email=${gmail}",
                      );
                      //ทำการ register ให้ครบ
                    }
                  }
                },
                child: const Text("สมัคร/เข้าสู่ระบบด้วย Google"),
              ),

              const SizedBox(height: 10),

              /// REGISTER
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text("สมัครสมาชิก"),
              ),

              /// FORGOT PASSWORD
              TextButton(
                onPressed: () {},
                child: const Text("Forgot password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signInEmail() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailctl.text.trim(),
        password: passwordctl.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Error: $e")));
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  Future<void> callRegister() async {
    Get.to(
      () => const RegisterPage(),
      arguments: {
        "email": FirebaseAuth.instance.currentUser?.email,
        "google_id": FirebaseAuth.instance.currentUser?.uid,
      },
    );
  }
}
