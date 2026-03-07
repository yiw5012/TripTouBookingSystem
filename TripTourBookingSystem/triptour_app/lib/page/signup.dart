// import 'dart:math';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:triptour_app/page/wrapper.dart';

// class Signup extends StatefulWidget {
//   const Signup({super.key});

//   @override
//   State<Signup> createState() => _SignupState();
// }

// class _SignupState extends State<Signup> {
//   final emailctl = TextEditingController();
//   final passwordctl = TextEditingController();
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Sign Up")),
//       body: Center(
//         child: Column(
//           children: [
//             TextField( 
//               controller: emailctl,
//               decoration: const InputDecoration(
//                 labelText: "Email",
//                 border: OutlineInputBorder(),
//               ),
//             ), 
//              TextField(
//               controller: passwordctl,
//               decoration: const InputDecoration(
//                 labelText: "Password",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () => singnUp(),
//               child: const Text("สมัครสมาชิก"),
//             ),
//           ],
//         )
        
//         ),
      
//     );
//   }

//   singnUp() async {
//     await FirebaseAuth.instance.createUserWithEmailAndPassword(
//       email: emailctl.text,
//       password: passwordctl.text,
//     );
//     Get.offAll(() => const Wrapper());
//   }
// }
