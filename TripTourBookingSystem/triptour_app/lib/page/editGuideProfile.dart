import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triptour_app/services/serverApi.dart';

class EditGuideProfile extends StatefulWidget {
  final Map<String, dynamic> guide;

  const EditGuideProfile({super.key, required this.guide});

  @override
  State<EditGuideProfile> createState() => _EditGuideProfileState();
}

class _EditGuideProfileState extends State<EditGuideProfile> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailCtl;
  late final TextEditingController ageController;
  late final TextEditingController birthdayController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;
  late final TextEditingController passwordCtl;

  // ==========================================================
  // STATE
  // ==========================================================
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  bool isSaving = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(
      text: getValue(widget.guide['first_name']),
    );

    lastNameController = TextEditingController(
      text: getValue(widget.guide['last_name']),
    );

    ageController = TextEditingController(text: getValue(widget.guide['age']));

    birthdayController = TextEditingController(
      text: normalizeBirthday(widget.guide['birthday']),
    );

    phoneController = TextEditingController(
      text: getValue(widget.guide['phone']),
    );

    addressController = TextEditingController(
      text: getValue(widget.guide['address']),
    );
    emailCtl = TextEditingController(text: getValue(widget.guide['email']));
    passwordCtl = TextEditingController();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailCtl.dispose();
    ageController.dispose();
    birthdayController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordCtl.dispose();

    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  // ==========================================================
  // GET VALUE
  // ==========================================================

  String getValue(dynamic value) {
    if (value == null) {
      return '';
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null' || text == '-') {
      return '';
    }

    return text;
  }

  // ==========================================================
  // NORMALIZE BIRTHDAY
  // ==========================================================

  String normalizeBirthday(dynamic value) {
    final String text = getValue(value);

    if (text.isEmpty) {
      return '';
    }

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  // ==========================================================
  // SELECT BIRTHDAY
  // ==========================================================

  Future<void> selectBirthday() async {
    DateTime initialDate = DateTime.now();

    final String currentBirthday = birthdayController.text.trim();

    // ========================================================
    // USE CURRENT BIRTHDAY
    // ========================================================

    if (currentBirthday.isNotEmpty) {
      final DateTime? parsedDate = DateTime.tryParse(currentBirthday);

      if (parsedDate != null) {
        initialDate = parsedDate;
      }
    }

    // ========================================================
    // SHOW DATE PICKER
    // ========================================================

    final DateTime? pickedDate = await showDatePicker(
      context: context,

      initialDate: initialDate,

      firstDate: DateTime(1900),

      lastDate: DateTime.now(),

      helpText: 'เลือกวันเกิด',

      cancelText: 'ยกเลิก',

      confirmText: 'ตกลง',
    );

    if (pickedDate == null) {
      return;
    }

    // ========================================================
    // FORMAT YYYY-MM-DD
    // ========================================================

    final String year = pickedDate.year.toString();

    final String month = pickedDate.month.toString().padLeft(2, '0');

    final String day = pickedDate.day.toString().padLeft(2, '0');

    birthdayController.text = '$year-$month-$day';

    // ========================================================
    // AUTO CALCULATE AGE
    // ========================================================

    final int age = calculateAge(pickedDate);

    ageController.text = age.toString();
  }

  // ==========================================================
  // CALCULATE AGE
  // ==========================================================

  int calculateAge(DateTime birthday) {
    final DateTime today = DateTime.now();

    int age = today.year - birthday.year;

    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }

    return age;
  }

  // ==========================================================
  // VALIDATE
  // ==========================================================

  bool validateForm() {
    final String firstName = firstNameController.text.trim();

    final String lastName = lastNameController.text.trim();

    final String ageText = ageController.text.trim();

    final String phone = phoneController.text.trim();

    // ========================================================
    // FIRST NAME
    // ========================================================

    if (firstName.isEmpty) {
      showMessage('กรุณากรอกชื่อ');

      return false;
    }

    // ========================================================
    // LAST NAME
    // ========================================================

    if (lastName.isEmpty) {
      showMessage('กรุณากรอกนามสกุล');

      return false;
    }

    // ========================================================
    // AGE
    // ========================================================

    if (ageText.isNotEmpty) {
      final int? age = int.tryParse(ageText);

      if (age == null || age < 1 || age > 120) {
        showMessage('กรุณากรอกอายุระหว่าง 1-120 ปี');

        return false;
      }
    }

    // ========================================================
    // PHONE
    // ========================================================

    if (phone.isNotEmpty) {
      final bool validPhone = RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch(phone);

      if (!validPhone) {
        showMessage('กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง');

        return false;
      }
    }

    return true;
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================
  // SAVE PROFILE
  // ==========================================================

  Future<void> saveProfile() async {
    // ========================================================
    // VALIDATE FORM
    // ========================================================

    if (!validateForm()) {
      return;
    }

    // ========================================================
    // GET FIREBASE USER
    // ========================================================

    // final User? user = FirebaseAuth.instance.currentUser;

    // if (user == null) {
    //   showMessage('กรุณาเข้าสู่ระบบก่อน');

    //   return;
    // }
    final String googleId = widget.guide['google_id'] ?? '';
    if (googleId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบ Google ID ของไกด์')));
      return;
    }
    // ========================================================
    // START SAVING
    // ========================================================

    setState(() {
      isSaving = true;
    });

    try {
      // ======================================================
      // UPDATE GUIDE PROFILE
      // ======================================================

      final result = await Serverapi.updateGuideProfile(
        googleId: googleId,

        firstName: firstNameController.text.trim(),

        lastName: lastNameController.text.trim(),
        email: emailCtl.text.trim(),

        age: ageController.text.trim(),

        birthday: birthdayController.text.trim(),

        phone: phoneController.text.trim(),

        address: addressController.text.trim(),
        password: passwordCtl.text.trim(),
        imageProfileFile: _selectedImage,
      );
      // เพิ่ม print เพื่อดูค่าที่ Backend ตอบกลับมาจริง ๆ ใน Debug Console
      print("StatusCode: ${result['statusCode']}");
      print("ResponseBody: ${result['body']}");
      if (!mounted) {
        return;
      }

      // ======================================================
      // SUCCESS
      // ======================================================

      if (result['statusCode'] == 200 &&
          result['body'] != null &&
          result['body']['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));

        // ส่ง true กลับไปหน้า Profile
        Navigator.pop(context, true);

        return;
      }

      // ======================================================
      // FAILED
      // ======================================================

      showMessage(result['body']?['message'] ?? 'ไม่สามารถบันทึกข้อมูลได้');
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Save guide profile error: $e');

      showMessage('เกิดข้อผิดพลาดในการบันทึกข้อมูล');
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  Widget build(BuildContext context) {
    final String currentImageUrl = widget.guide['image_profile'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลไกด์'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (currentImageUrl.isNotEmpty &&
                                          currentImageUrl != '-'
                                      ? NetworkImage(currentImageUrl)
                                      : null),
                            child:
                                (_selectedImage == null &&
                                    (currentImageUrl.isEmpty ||
                                        currentImageUrl == '-'))
                                ? const Icon(
                                    Icons.person,
                                    size: 55,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ข้อมูลบัญชีผู้ใช้ (Firebase & System)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: emailCtl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'อีเมล',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return 'กรุณากรอกอีเมล';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: passwordCtl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText:
                                    'รหัสผ่านใหม่ (เว้นว่างไว้หากไม่ต้องการเปลี่ยน)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ส่วนแก้ไขข้อมูลส่วนตัว
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ข้อมูลส่วนตัว',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'ชื่อ',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) => val!.trim().isEmpty
                                        ? 'กรุณากรอกชื่อ'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'นามสกุล',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) => val!.trim().isEmpty
                                        ? 'กรุณากรอกนามสกุล'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'เบอร์โทรศัพท์',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: ageController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'อายุ',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: selectBirthday,
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: birthdayController,
                                  decoration: const InputDecoration(
                                    labelText: 'วันเกิด',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'ที่อยู่',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'บันทึกการเปลี่ยนแปลง',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
