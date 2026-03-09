import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/serverApi.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  final emailCtl = TextEditingController();
  final otpclt = TextEditingController();
  final repassword = TextEditingController();
  final repassword2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                "ลืมรหัสผ่าน",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                color: const Color(0xff1e7d32),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Text(
                        "โปรดป้อนอีเมลของคุณเพื่อค้นหาบัญชีของคุณ",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: emailCtl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            onPressed: () {
                              Get.to(Wrapper());
                            },
                            child: const Text("ยกเลิก"),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent[400],
                            ),
                            onPressed: () async {
                              print(emailCtl.text);

                              //ไปกรอก otp
                              if (emailCtl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("กรุณากรอก Email"),
                                  ),
                                );

                                return;
                              }
                              //เรียก api ส่ง otp ไป email
                              await Serverapi.sendOtp(emailCtl.text);
                              showDialog(
                                barrierColor: Color.fromARGB(1, 0, 0, 0),
                                context: context,
                                builder: (context) => SimpleDialog(
                                  title: Text(
                                    "โปรดตรวจสอบอีเมลของคุณเพื่อดูรหัสผ่าน รหัสมีความยาว 6 หลัก",
                                  ),
                                  children: [
                                    TextField(
                                      controller: otpclt,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        //check otpclt ว่าตรงมั้ย call api
                                        print("process 1");
                                        bool result = await Serverapi.verifyOtp(
                                          emailCtl.text,
                                          otpclt.text,
                                        );
                                        print("Email: ${emailCtl.text}");
                                        print("OTP: ${otpclt.text}");
                                        //ถ้าตรงไปต่อ
                                        if (result) {
                                          print("OTP ถูกต้อง");
                                          print("Verify result: $result");

                                          showDialog(
                                            context: context,
                                            builder: (context) => SimpleDialog(
                                              title: Text(
                                                " โปรดสร้างรหัสผ่านใหม่",
                                              ),
                                              children: [
                                                TextField(
                                                  controller: repassword,
                                                  decoration: InputDecoration(
                                                    label: Text("รหัสผ่าน"),
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                TextField(
                                                  controller: repassword2,
                                                  decoration: InputDecoration(
                                                    label: Text(
                                                      "ยืนยันรหัสผ่าน",
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (repassword.text !=
                                                        repassword2.text) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "รหัสผ่านไม่ตรงกัน",
                                                          ),
                                                        ),
                                                      );

                                                      return;
                                                    }

                                                    bool result =
                                                        await Serverapi.resetpassword(
                                                          emailCtl.text,
                                                          repassword.text,
                                                        );

                                                    if (result) {
                                                      print(
                                                        "รหัสผ่านถูก reset แล้ว",
                                                      );

                                                      Get.offAll(Wrapper());
                                                    }
                                                  },
                                                  child: const Text("ยืนยัน"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Get.offAll(Forgetpassword);
                                                  },
                                                  child: Text("ยกเลิก"),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("OTP ไม่ถูกต้อง"),
                                            ),
                                          );
                                        }
                                        //ถ้าไม่ตรง ขึ้นรหัสOTPไม่ถูกต้อง
                                      },
                                      child: Text("ตกลง"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      child: Text("ยกเลิก"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("ค้นหา"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
