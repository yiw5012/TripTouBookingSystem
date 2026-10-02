import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/forgetpassword.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/page/auth/registerPage.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/serverApi.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailforgetclt = TextEditingController();

  final emailctl = TextEditingController();
  final passwordctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.asset("assets/logo.png", height: 200),

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
                      "Google Sign In Success: ID=${google_id}, Email=${gmail}",
                    );

                    Get.offAll(() => Wrapper());
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
                onPressed: () {
                  //callForgetPassword(context);
                  Get.offAll(Forgetpassword());
                },
                child: const Text("Forgot password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signInEmail() async {
    final email = emailctl.text.trim();
    final password = passwordctl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่านให้ครบ')),
      );
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รูปแบบอีเมลไม่ถูกต้อง')));
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'user-not-found' => 'ไม่พบผู้ใช้นี้ในระบบ',
        'wrong-password' => 'รหัสผ่านไม่ถูกต้อง',
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        _ => e.message ?? 'เข้าสู่ระบบไม่สำเร็จ',
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เข้าสู่ระบบไม่สำเร็จ: $e')));
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Google Sign In Error: $e")));
      }
      return null;
    }
  }
}

Future<void> callForgetPassword(BuildContext context) async {
  final emailforgetpass = TextEditingController();
  showDialog(
    context: context, // ต้องส่ง context มาด้วย
    builder: (context) => SimpleDialog(
      title: ListTile(title: Text("ลืมรหัสผ่าน")),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            children: [
              Text("กรุณากรอกอีเมลที่คุณลืมรหัสผ่าน"),
              SizedBox(height: 10),
              TextField(
                controller: emailforgetpass,
                decoration: const InputDecoration(
                  labelText: "อีเมล",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            // reset(emailforgetpass.text, context);
          },
          child: Text("ตกลง"),
        ),
        TextButton(
          onPressed: () {
            navigator?.pop();
          },
          child: Text("ยกเลิก"),
        ),
      ],
    ),
  );
}

Future<void> reset(String emailforget, BuildContext context) async {
  if (emailforget.trim().isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("กรุณากรอกอีเมล")));
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailforget.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลแล้ว")),
    );

    Navigator.pop(context); // ปิด dialog
  } on FirebaseAuthException catch (e) {
    String message = "เกิดข้อผิดพลาด";

    if (e.code == "user-not-found") {
      message = "ไม่พบอีเมลนี้ในระบบ";
    }

    if (e.code == "invalid-email") {
      message = "รูปแบบอีเมลไม่ถูกต้อง";
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error: $e")));
  }

  Future<void> callForgetPassword(BuildContext context) async {
    final emailforgetpass = TextEditingController();
    showDialog(
      context: context, // ต้องส่ง context มาด้วย
      builder: (context) => SimpleDialog(
        title: ListTile(title: Text("ลืมรหัสผ่าน")),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),

            child: Column(
              children: [
                Text("กรุณากรอกอีเมลที่คุณลืมรหัสผ่าน"),
                SizedBox(height: 10),
                TextField(
                  controller: emailforgetpass,
                  decoration: const InputDecoration(
                    labelText: "อีเมล",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              reset(emailforgetpass.text, context);
            },
            child: Text("ตกลง"),
          ),
          TextButton(
            onPressed: () {
              navigator?.pop();
            },
            child: Text("ยกเลิก"),
          ),
        ],
      ),
    );
  }
}

// Future<void> reset(String emailforget, BuildContext context) async {
//   if (emailforget.trim().isEmpty) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("กรุณากรอกอีเมล")));
//     return;
//   }

//   try {
//     await FirebaseAuth.instance.sendPasswordResetEmail(
//       email: emailforget.trim(),
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลแล้ว")),
//     );

//     Navigator.pop(context); // ปิด dialog
//   } on FirebaseAuthException catch (e) {
//     String message = "เกิดข้อผิดพลาด";

//     if (e.code == "user-not-found") {
//       message = "ไม่พบอีเมลนี้ในระบบ";
//     }

//     if (e.code == "invalid-email") {
//       message = "รูปแบบอีเมลไม่ถูกต้อง";
//     }

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   } catch (e) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text("Error: $e")));
//   }
// }
