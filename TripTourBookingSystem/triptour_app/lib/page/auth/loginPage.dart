import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/forgetpassword.dart';
import 'package:triptour_app/page/auth/registerPage.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/services/serverApi.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailctl = TextEditingController();
  final passwordctl = TextEditingController();

  @override
  void dispose() {
    emailctl.dispose();
    passwordctl.dispose();
    super.dispose();
  }

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
                keyboardType: TextInputType.emailAddress,
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
                    String? googleId = userCredential.user?.uid;

                    if (googleId != null) {
                      print(emailctl.text);
                      final profile = await Serverapi.checkuser(
                        googleId,
                        emailctl.text,
                      );

                      if (profile == null) {
                        // 📌 สั่ง Sign Out ออกจากแอปทันทีเนื่องจากบัญชีติด inactive (Backend ตอบ 403)
                        await FirebaseAuth.instance.signOut();
                        await GoogleSignIn().signOut();

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'บัญชีนี้ถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    Get.offAll(() => const Wrapper());
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
                  Get.to(() => const Forgetpassword());
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
        'user-disabled' =>
          'บัญชีผู้ใช้นี้ถูกปิดใช้งานหรือถูกระงับ กรุณาติดต่อผู้ดูแลระบบ',
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
    } on FirebaseAuthException catch (e) {
      print("Google Sign In FirebaseAuthException: ${e.code}");
      if (mounted) {
        String msg = "Google Sign In Error: ${e.message}";
        if (e.code == 'user-disabled') {
          msg = 'บัญชีผู้ใช้นี้ถูกปิดใช้งานหรือถูกระงับ กรุณาติดต่อผู้ดูแลระบบ';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      return null;
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
