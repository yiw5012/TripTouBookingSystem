import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: "ชื่อผู",
                border: OutlineInputBorder(),
              ),
            ),
            const TextField(
              decoration: InputDecoration(
                labelText: "นามสกุล",
                border: OutlineInputBorder(),
              ),
            ),
            const TextField(
              decoration: InputDecoration(
                labelText: "เบอร์โทรศัพท์",
                border: OutlineInputBorder(),
              ),
            ),

            ElevatedButton(onPressed: () {}, child: const Text("NEXT ->")),
          ],
        ),
      ),
    );
  }
}
