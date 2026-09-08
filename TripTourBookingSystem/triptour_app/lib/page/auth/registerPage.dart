import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/model/country.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triptour_app/severGetApi.dart';

String formatRegistrationError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความปลอดภัยมากขึ้น';
      case 'operation-not-allowed':
        return 'ระบบไม่อนุญาตให้สมัครด้วยอีเมลนี้';
      default:
        return error.message?.isNotEmpty == true
            ? error.message!
            : 'สมัครสมาชิกไม่สำเร็จ';
    }
  }

  return 'สมัครสมาชิกไม่สำเร็จ';
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailctl = TextEditingController();
  final passwordctl = TextEditingController();
  final firstname_lastnamectl = TextEditingController();
  // final lastnamectl = TextEditingController();
  final phonectl = TextEditingController();
  final number_idctl = TextEditingController();
  final birthdayctl = TextEditingController();
  final addressctl = TextEditingController();
  final genderctl = TextEditingController();
  final congenital_diseasectl = TextEditingController(); // โรคประจำตัว
  final medicinectl = TextEditingController(); // ยาที่ใช้ประจำ
  final allergic_listctl = TextEditingController(); // รายการแพ้ยา
  final otherctl = TextEditingController(); // อื่น ๆ
  List<String> selectedGender = ['Male', 'Female', 'Other'];

  List<String> selectedCountries = [];
  List<int> selectedCountryIds = [];
  String dropdownValue = 'Other';

  String _countryNameById(int countryId) {
    for (final country in countries) {
      if (country.countryId == countryId) {
        return _countryLabel(country);
      }
    }

    return countryId.toString();
  }

  String? google_id;
  int _currentStep = 1;
  File? _selectedImage;
  File? _selectedImage_passport;

  final ImagePicker _picker = ImagePicker();
  DateTime? selectedDate;

  List<Country> countries = [];
  bool isLoading = true;

  String _countryLabel(Country country) {
    final nameTh = country.countryNameTH.trim();
    final nameEn = country.countryNameEn.trim();
    return nameTh.isNotEmpty ? nameTh : nameEn;
  }

  @override
  void initState() {
    super.initState();
    fecthData();
    // รับข้อมูลจากหน้า LoginPage ผ่าน Get.arguments
    final args = Get.arguments;
    if (args != null) {
      emailctl.text = args["email"] ?? "";
      google_id = args["google_id"];
    }
    if (google_id != null) {
      _nextStep(); // ถ้ามี google_id ให้ข้ามไป Step 2 เลย
    }
  }

  Future<void> fecthData() async {
    setState(() {
      isLoading = true;
    });

    List<Country> result = await Severgetapi.getCountry();

    if (mounted) {
      setState(() {
        countries = result;
        isLoading = false; // ปิดสถานะกำลังโหลด
      });
      print(countries);
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++; // เพิ่มค่า Step +1
        });
      }
    } else {
      await signUp();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2021, 7, 25),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        birthdayctl.text = "${pickedDate.toLocal()}".split(' ')[0];
        print("Selected date: ${birthdayctl.text}");
      });
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 1 && google_id == null) {
      final email = emailctl.text.trim();
      final password = passwordctl.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอก Email และ Password ให้ครบ')),
        );
        return false;
      }

      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('รูปแบบอีเมลไม่ถูกต้อง')));
        return false;
      }

      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร")),
        );
        return false;
      }
    }

    if (_currentStep == 2) {
      if (firstname_lastnamectl.text.trim().isEmpty
      // phonectl.text.trim().isEmpty
      ) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลส่วนตัวให้ครบ')),
        );
        return false;
      }
    }

    return true;
  }

  // ฟังก์ชันกดย้อนกลับ (-1 Step)
  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--; // ลดค่า Step -1
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource
          .gallery, // หากต้องการใช้กล้อง เปลี่ยนเป็น ImageSource.camera
      imageQuality: 80, // บีบอัดไฟล์เล็กน้อยเพื่อลดขนาด
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  ///ยังไม่ทำดาต้าเบสจริง
  Future<void> _showCountrySelectionDialog() async {
    if (countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังโหลดรายชื่อประเทศ...')),
      );
      return;
    }

    final selectedIds = Set<int>.from(selectedCountryIds);
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เลือกประเทศที่ชอบ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: countries.map((country) {
                    final countryName = _countryLabel(country);
                    final isChecked = selectedIds.contains(country.countryId);
                    return CheckboxListTile(
                      title: Text(countryName),
                      value: isChecked,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedIds.add(country.countryId);
                          } else {
                            selectedIds.remove(country.countryId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedIds),
                  child: const Text('เลือก'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedCountryIds = result.toList()..sort();
        selectedCountries = selectedCountryIds
            .map((countryId) => _countryNameById(countryId))
            .where((name) => name.isNotEmpty)
            .toList();
        print('selectedCountryIds=$selectedCountryIds');
        print('selectedCountries=$selectedCountries');
      });
    }
  }

  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Image.asset("assets/logo.png", height: 50, width: 50),
              const SizedBox(height: 10),
              Text(
                "Sigen Up TripTour",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStepCircle(1, "บัญชีผู้ใช้"),
                  _buildStepLine(1),
                  _buildStepCircle(2, "ข้อมูลส่วนตัว"),
                  _buildStepLine(2),
                  _buildStepCircle(3, "รายละเอียด"),
                ],
              ),

              const SizedBox(height: 10),

              _buildStepContent(),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    if (_currentStep >= 2)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          child: const Text('ย้อนกลับ'),
                        ),
                      ),
                    if (_currentStep > 1) const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // ทำขอบมน
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.green, // Set the background color
                          ),
                          onPressed: _nextStep,
                          child: Text(
                            _currentStep == 3 ? 'ยืนยันการสมัคร' : 'ถัดไป',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
                  Get.offAll(() => const Wrapper());
                },
                child: Text("ยกเลิกการสมัครสมาชิก"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, // Set the text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (google_id == null) ...[
              const Text(
                "Email",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              const SizedBox(
                height: 8,
              ), // เว้นระยะห่างระหว่าง label กับช่องกรอก
              TextField(
                controller: emailctl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "กรอก Email ของคุณ",
                ),
              ),
              const SizedBox(height: 30),
            ],
            if (google_id == null) ...[
              Text(
                "Password",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              TextField(
                controller: passwordctl,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "กรอก Password ของคุณ",
                ),
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ), // เพิ่มความสูงปุ่ม
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // ทำขอบมน
                    ),
                  ),
                  onPressed: () async {
                    final userCredential = await signInWithGoogle();
                    if (userCredential != null) {
                      String? googleId = userCredential.user?.uid;
                      String? gmail = userCredential.user?.email;
                      print(
                        "Google Sign In Success: ID=${googleId}, Email=${gmail}",
                      );

                      Get.offAll(() => const Wrapper());
                    }
                  },

                  child: const Text("สมัคร/เข้าสู่ระบบด้วย Google"),
                ),
              ),
            ),
          ],
        );
      case 2:
        return dataPersonal();
      case 3:
        return dataDetail();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepCircle(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isActive ? Colors.blue : Colors.grey[300],
          child: Text(
            '$step',
            style: TextStyle(color: isActive ? Colors.white : Colors.black54),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Widget เส้นเชื่อมระหว่างวงกลม Step
  Widget _buildStepLine(int step) {
    bool isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
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

  Future<void> signUp() async {
    try {
      print(google_id);
      if (google_id == null) {
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

      final fullName = firstname_lastnamectl.text.trim();
      final nameParts = fullName.split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final resultUpload = await Serverapi.uploadImage(
        _selectedImage,
        _selectedImage_passport,
      );
      print("Image uploaded: $resultUpload");

      if ((resultUpload == null) &&
          (_selectedImage != null || _selectedImage_passport != null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัปโหลดรูปภาพไม่สำเร็จ กรุณาลองใหม่'),
            ),
          );
        }
        return;
      }

      String? imageUrl = resultUpload != null ? resultUpload['imageUrl'] : null;
      String? passportUrl = resultUpload != null
          ? resultUpload['passportUrl']
          : null;
      print("Image URL: $imageUrl");
      print("Passport URL: $passportUrl");
      final result = await Serverapi.registerUser(
        google_id!,
        emailctl.text.trim(),
        firstName,
        lastName,
        phonectl.text.trim(),
        number_idctl.text.trim(),
        birthdayctl.text.trim(),
        addressctl.text.trim(),
        genderctl.text.trim(),
        medicinectl.text.trim(),
        congenital_diseasectl.text.trim(),
        allergic_listctl.text.trim(),
        otherctl.text.trim(),
        imageProfileUrl: imageUrl,
        passportUrl: passportUrl,
        favoriteCountries: selectedCountryIds,
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
    } on FirebaseAuthException catch (e) {
      final message = formatRegistrationError(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("สมัครสมาชิกไม่สำเร็จ: $e")));
      }
    }
  }

  Widget dataPersonal() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          Card(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("ยังไม่ได้เลือกรูป")),
            ),
          ),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Image Profile"),
          ),
          const SizedBox(height: 10),

          // ปุ่มเลือกรูป
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40, // กำหนดความสูงของ TextField
                  child: TextField(
                    controller: firstname_lastnamectl,
                    decoration: const InputDecoration(
                      labelText: "ชื่อ-นามสกุล",
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(),
                  ),
                ),
              ),

              const SizedBox(width: 10), // เว้นระยะห่างระหว่าง 2 ช่อง
              // Expanded(
              //   child: SizedBox(
              //     height: 40, // กำหนดความสูงของ TextField
              //     child: TextField(
              //       controller: lastnamectl,
              //       decoration: const InputDecoration(
              //         labelText: "นามสกุล",
              //         border: OutlineInputBorder(),
              //       ),
              //     ),
              //   ),
              // ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 40, // ความสูงให้รับกับ TextField พอดี
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    icon: const Icon(Icons.arrow_drop_down),
                    elevation: 16,

                    onChanged: (String? value) {
                      setState(() {
                        dropdownValue = value!;
                        genderctl.text = value;
                        print(genderctl.text);
                      });
                    },
                    items: selectedGender.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: TextField(
              controller: number_idctl,
              decoration: const InputDecoration(
                labelText: "ID Card Number",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // birthday and phone number
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Birthday",
                        border: OutlineInputBorder(),
                        isDense: true,

                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),

                      child: Text(
                        birthdayctl.text.isEmpty
                            ? "Select Date"
                            : birthdayctl.text,
                        style: TextStyle(
                          color: birthdayctl.text.isEmpty
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: phonectl,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ), // เว้นระยะห่างระหว่าง 2 ช่อง
          //ที่อยู๋
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: TextField(
              controller: addressctl,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ประเทศที่ชอบ (เลือกได้มากกว่า 1)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showCountrySelectionDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCountries.isEmpty
                          ? 'เลือกประเทศที่ชอบ'
                          : selectedCountries.join(', '),
                      style: TextStyle(
                        color: selectedCountries.isEmpty
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dataDetail() {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // ปรับขอบ Card ให้โค้งมนสวยงาม
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // เพิ่มระยะห่างขอบในให้ดูไม่อึดอัด
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.assignment_outlined,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "รายละเอียดเพิ่มเติม",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 24,
                  thickness: 1,
                ), // เส้นคั่นเพิ่มความมีระเบียบ
                // 1. ช่อง โรคประจำตัว
                TextField(
                  controller: congenital_diseasectl,
                  decoration: const InputDecoration(
                    labelText: "โรคประจำตัว",
                    hintText: "ถ้าไม่มีให้เว้นว่างไว้",
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. ช่อง ยาที่ใช้ประจำ
                TextField(
                  controller: medicinectl,
                  decoration: const InputDecoration(
                    labelText: "ยาที่ใช้ประจำ",
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. ช่อง รายการแพ้ยา
                TextField(
                  controller: allergic_listctl,
                  decoration: const InputDecoration(
                    labelText: "รายการแพ้ยา/อาหาร",
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. ช่อง อื่น ๆ (ขยายบรรทัดได้)
                TextField(
                  controller: otherctl,
                  maxLines: 3, // ขยายกล่องให้พิมพ์รายละเอียดอื่นๆ ได้หลายบรรทัด
                  decoration: const InputDecoration(
                    labelText: "อื่น ๆ",
                    alignLabelWithHint:
                        true, // ให้ Label อยู่ด้านบนเมื่อมีหลายบรรทัด
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.assignment_outlined,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "เอกสารยืนยันตัวตน",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: _selectedImage_passport != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage_passport!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(child: Text("ยังไม่ได้เลือกรูป")),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final XFile? pickedFile = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage_passport = File(pickedFile.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Upload Passport/ID Card"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
