import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/serverApi.dart';

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

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController ageController;
  late final TextEditingController birthdayController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;

  // ==========================================================
  // STATE
  // ==========================================================

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
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    birthdayController.dispose();
    phoneController.dispose();
    addressController.dispose();

    super.dispose();
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

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('กรุณาเข้าสู่ระบบก่อน');

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
        googleId: user.uid,

        firstName: firstNameController.text.trim(),

        lastName: lastNameController.text.trim(),

        age: ageController.text.trim(),

        birthday: birthdayController.text.trim(),

        phone: phoneController.text.trim(),

        address: addressController.text.trim(),
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text(
          'แก้ไขข้อมูลส่วนตัว',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // PROFILE HEADER
            // ==================================================
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.amber,

              child: const Icon(Icons.explore, size: 48, color: Colors.white),
            ),

            const SizedBox(height: 20),

            const Text(
              'แก้ไขข้อมูลไกด์',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // FIRST NAME
            // ==================================================
            TextField(
              controller: firstNameController,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'ชื่อ',

                hintText: 'กรอกชื่อ',

                prefixIcon: Icon(Icons.person_outline),

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // LAST NAME
            // ==================================================
            TextField(
              controller: lastNameController,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'นามสกุล',

                hintText: 'กรอกนามสกุล',

                prefixIcon: Icon(Icons.person_outline),

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // AGE
            // ==================================================
            TextField(
              controller: ageController,

              keyboardType: TextInputType.number,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'อายุ',

                hintText: 'กรอกอายุ',

                prefixIcon: Icon(Icons.numbers_outlined),

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // BIRTHDAY
            // ==================================================
            TextField(
              controller: birthdayController,

              readOnly: true,

              onTap: selectBirthday,

              decoration: const InputDecoration(
                labelText: 'วันเกิด',

                hintText: 'เลือกวันเกิด',

                prefixIcon: Icon(Icons.cake_outlined),

                suffixIcon: Icon(Icons.calendar_month),

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // PHONE
            // ==================================================
            TextField(
              controller: phoneController,

              keyboardType: TextInputType.phone,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์',

                hintText: 'กรอกเบอร์โทรศัพท์',

                prefixIcon: Icon(Icons.phone_outlined),

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ADDRESS
            // ==================================================
            TextField(
              controller: addressController,

              maxLines: 4,

              textInputAction: TextInputAction.newline,

              decoration: const InputDecoration(
                labelText: 'ที่อยู่',

                hintText: 'กรอกที่อยู่',

                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),

                  child: Icon(Icons.home_outlined),
                ),

                border: OutlineInputBorder(),

                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SAVE BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 52,

              child: ElevatedButton(
                onPressed: isSaving ? null : saveProfile,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,

                  foregroundColor: Colors.black,

                  disabledBackgroundColor: Colors.grey.shade300,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // CANCEL BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 50,

              child: OutlinedButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.pop(context);
                      },

                child: const Text('ยกเลิก'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
