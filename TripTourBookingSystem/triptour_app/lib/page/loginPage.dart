import 'package:flutter/material.dart';
import 'package:triptour_app/page/registerPage.dart';

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
      backgroundColor: Colors.grey,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              Image.asset("assets/images/login.png", height: 200),
              TextField(
                controller: emailctl,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordctl,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: Text("ดำเนินการต่อด้วย google"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => login(),
                child: Text("เข้าสู่ระบบ"),
              ),

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                ),
                child: Text("สมัครสมาชิก"),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(title: Text("Login")),
    );
  }

  login() {
    print("email: ${emailctl.text} password: ${passwordctl.text}");
  }
}
