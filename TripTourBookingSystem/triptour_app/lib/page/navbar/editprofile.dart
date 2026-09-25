import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triptour_app/serverApi.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> memberData;

  const EditProfilePage({super.key, required this.memberData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ==========================================================
  // Controllers
  // ==========================================================

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController numberIdController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final TextEditingController congenitalDiseaseController =
      TextEditingController();

  final TextEditingController medicineController = TextEditingController();

  final TextEditingController allergicListController = TextEditingController();

  final TextEditingController othersController = TextEditingController();

  // ==========================================================
  // Gender
  // ==========================================================

  String selectedGender = 'Other';

  final List<String> genderList = ['Male', 'Female', 'Other'];

  // ==========================================================
  // Image
  // ==========================================================

  final ImagePicker picker = ImagePicker();

  File? selectedProfileImage;
  File? selectedPassportImage;

  String? currentProfileImage;
  String? currentPassportImage;

  // ==========================================================
  // Loading
  // ==========================================================

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadDataToForm();
  }

  // ==========================================================
  // โหลดข้อมูลเดิมมาใส่ Form
  // ==========================================================

  void loadDataToForm() {
    final data = widget.memberData;

    final firstName = data['first_name']?.toString().trim() ?? '';

    final lastName = data['last_name']?.toString().trim() ?? '';

    nameController.text = '$firstName $lastName'.trim();

    phoneController.text = data['phone']?.toString() ?? '';

    numberIdController.text = data['number_id']?.toString() ?? '';

    birthdayController.text = data['birthday']?.toString() ?? '';

    addressController.text = data['address']?.toString() ?? '';

    congenitalDiseaseController.text =
        data['congenital_disease']?.toString() ?? '';

    medicineController.text = data['medicine']?.toString() ?? '';

    allergicListController.text = data['allergic_list']?.toString() ?? '';

    othersController.text = data['others']?.toString() ?? '';

    final gender = data['gender']?.toString();

    if (gender != null && genderList.contains(gender)) {
      selectedGender = gender;
    }

    currentProfileImage = data['image_profile']?.toString();

    currentPassportImage = data['image_passport']?.toString();
  }

  // ==========================================================
  // เลือกวันเกิด
  // ==========================================================

  Future<void> selectBirthday() async {
    DateTime initialDate = DateTime(2000, 1, 1);

    if (birthdayController.text.isNotEmpty) {
      try {
        final parts = birthdayController.text.split('-');

        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {}
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      birthdayController.text =
          '${pickedDate.year.toString().padLeft(4, '0')}-'
          '${pickedDate.month.toString().padLeft(2, '0')}-'
          '${pickedDate.day.toString().padLeft(2, '0')}';
    });
  }

  // ==========================================================
  // เลือกรูป Profile
  // ==========================================================

  Future<void> pickProfileImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      selectedProfileImage = File(pickedFile.path);
    });
  }

  // ==========================================================
  // เลือกรูป Passport
  // ==========================================================

  Future<void> pickPassportImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      selectedPassportImage = File(pickedFile.path);
    });
  }

  // ==========================================================
  // แสดงค่า String
  // ==========================================================

  String displayValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  // ==========================================================
  // สร้าง TextField
  // ==========================================================

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ==========================================================
  // บันทึกข้อมูล
  // ==========================================================

  Future<void> saveProfile() async {
    if (isSaving) {
      return;
    }

    // --------------------------------------------------------
    // ตรวจ Firebase User
    // --------------------------------------------------------

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบผู้ใช้งาน')));

      return;
    }

    // --------------------------------------------------------
    // ตรวจชื่อ
    // --------------------------------------------------------

    final String fullName = nameController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')));

      return;
    }

    // --------------------------------------------------------
    // แยกชื่อ / นามสกุล
    // --------------------------------------------------------

    final List<String> nameParts = fullName.split(RegExp(r'\s+'));

    final String firstName = nameParts.isNotEmpty ? nameParts.first : '';

    final String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    setState(() {
      isSaving = true;
    });

    try {
      // ======================================================
      // 1. รูปเดิม
      // ======================================================

      String? profileImageUrl = currentProfileImage;

      String? passportImageUrl = currentPassportImage;

      // ======================================================
      // 2. ถ้าเลือกรูปใหม่ → Upload
      // ======================================================

      if (selectedProfileImage != null || selectedPassportImage != null) {
        final uploadResult = await Serverapi.uploadImage(
          selectedProfileImage,
          selectedPassportImage,
        );

        debugPrint('Upload result: $uploadResult');

        if (uploadResult == null) {
          throw Exception('อัปโหลดรูปภาพไม่สำเร็จ');
        }

        // ถ้ามีรูป Profile ใหม่
        if (selectedProfileImage != null) {
          profileImageUrl = uploadResult['imageUrl']?.toString();
        }

        // ถ้ามี Passport ใหม่
        if (selectedPassportImage != null) {
          passportImageUrl = uploadResult['passportUrl']?.toString();
        }
      }

      // ======================================================
      // 3. UPDATE Member
      // ======================================================

      final result = await Serverapi.updateMember(
        googleId: user.uid,
        firstName: firstName,
        lastName: lastName,
        phone: phoneController.text.trim(),
        numberId: numberIdController.text.trim(),
        birthday: birthdayController.text.trim(),
        address: addressController.text.trim(),
        gender: selectedGender,
        medicine: medicineController.text.trim(),
        congenitalDisease: congenitalDiseaseController.text.trim(),
        allergicList: allergicListController.text.trim(),
        others: othersController.text.trim(),
        imageProfile: profileImageUrl,
        imagePassport: passportImageUrl,
      );

      // ======================================================
      // 4. ตรวจผลลัพธ์
      // ======================================================

      if (!mounted) {
        return;
      }

      if (result['statusCode'] == 200 && result['body']?['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );

        // ส่ง true กลับ ProfilePage
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['body']?['message'] ?? 'บันทึกข้อมูลไม่สำเร็จ',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Save profile error: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ==========================================================
  // Profile Image
  // ==========================================================

  Widget buildProfileImage() {
    // รูปใหม่ที่เพิ่งเลือก
    if (selectedProfileImage != null) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: FileImage(selectedProfileImage!),
      );
    }

    // รูปเดิมจาก Cloud
    if (currentProfileImage != null && currentProfileImage!.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: NetworkImage(currentProfileImage!),
      );
    }

    // ไม่มีรูป
    return const CircleAvatar(radius: 55, child: Icon(Icons.person, size: 55));
  }

  // ==========================================================
  // Passport Image
  // ==========================================================

  Widget buildPassportImage() {
    if (selectedPassportImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          selectedPassportImage!,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
        ),
      );
    }

    if (currentPassportImage != null && currentPassportImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          currentPassportImage!,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey.shade200,
              child: const Center(child: Text('โหลดรูปเอกสารไม่สำเร็จ')),
            );
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('ยังไม่มีรูปเอกสาร')),
    );
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final String email = displayValue(widget.memberData['email']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลส่วนตัว'),
        backgroundColor: Colors.greenAccent,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // รูป Profile
            // ==================================================
            Center(
              child: Column(
                children: [
                  buildProfileImage(),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: isSaving ? null : pickProfileImage,
                    icon: const Icon(Icons.image),
                    label: const Text('เปลี่ยนรูป Profile'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ข้อมูลบัญชี
            // ==================================================
            const Text(
              'ข้อมูลบัญชี',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: TextEditingController(text: email),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'อีเมล',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // ข้อมูลส่วนตัว
            // ==================================================
            const Text(
              'ข้อมูลส่วนตัว',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            buildTextField(label: 'ชื่อ-นามสกุล', controller: nameController),

            buildTextField(
              label: 'เบอร์โทรศัพท์',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),

            // ==================================================
            // เพศ
            // ==================================================
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'เพศ',
                  border: OutlineInputBorder(),
                ),
                items: genderList
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedGender = value;
                        });
                      },
              ),
            ),

            // ==================================================
            // วันเกิด
            // ==================================================
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: birthdayController,
                readOnly: true,
                onTap: isSaving ? null : selectBirthday,
                decoration: const InputDecoration(
                  labelText: 'วันเกิด',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
              ),
            ),

            buildTextField(
              label: 'ที่อยู่',
              controller: addressController,
              maxLines: 3,
            ),

            buildTextField(
              label: 'เลขบัตรประชาชน / Passport',
              controller: numberIdController,
            ),

            const Divider(height: 30),

            // ==================================================
            // ข้อมูลสุขภาพ
            // ==================================================
            const Text(
              'ข้อมูลสุขภาพ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            buildTextField(
              label: 'โรคประจำตัว',
              controller: congenitalDiseaseController,
            ),

            buildTextField(
              label: 'ยาที่ใช้ประจำ',
              controller: medicineController,
            ),

            buildTextField(
              label: 'ประวัติการแพ้ยา/อาหาร',
              controller: allergicListController,
            ),

            buildTextField(
              label: 'อื่น ๆ',
              controller: othersController,
              maxLines: 3,
            ),

            const Divider(height: 30),

            // ==================================================
            // Passport
            // ==================================================
            const Text(
              'เอกสารยืนยันตัวตน',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            buildPassportImage(),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : pickPassportImage,
                icon: const Icon(Icons.badge),
                label: const Text('เปลี่ยนรูป Passport / ID Card'),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // Save Button
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveProfile,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    numberIdController.dispose();
    birthdayController.dispose();
    addressController.dispose();
    congenitalDiseaseController.dispose();
    medicineController.dispose();
    allergicListController.dispose();
    othersController.dispose();

    super.dispose();
  }
}
