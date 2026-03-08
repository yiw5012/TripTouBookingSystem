import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/page/registerPage.dart';
import 'package:triptour_app/page/wrapper.dart';
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
}
