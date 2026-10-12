import 'dart:io';
import 'package:flutter/material.dart';

class PassengerFormControllers {
  final int passengerIndex; // ลำดับ
  final String typeName; // ประเภท

  final TextEditingController nameCtl = TextEditingController();
  final TextEditingController numberIdCtl = TextEditingController();
  final TextEditingController birthdayCtl = TextEditingController();
  final TextEditingController phoneCtl = TextEditingController();
  final TextEditingController addressCtl = TextEditingController();
  String gender = 'Male';

  final TextEditingController congenitalDiseaseCtl =
      TextEditingController(); // โรคประจำตัว
  final TextEditingController medicineCtl =
      TextEditingController(); // ยาที่ใช้ประจำ
  final TextEditingController allergicListCtl =
      TextEditingController(); // รายการแพ้ยา/อาหาร
  final TextEditingController otherCtl = TextEditingController(); // อื่น ๆ

  File? passportImage;

  PassengerFormControllers({
    required this.passengerIndex,
    required this.typeName,
    this.passportImage,
  });

  /// คืนค่าข้อมูลเป็น Map เพื่อนำไปส่ง API ได้ง่าย
  Map<String, dynamic> toJson() {
    String fullName = nameCtl.text.trim();
    List<String> nameParts = fullName.split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';
    return {
      'passenger_number': passengerIndex,
      'type': typeName,
      'name': nameCtl.text.trim(),
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'id_card': numberIdCtl.text.trim(),
      'birthday': birthdayCtl.text.trim(),
      'phone': phoneCtl.text.trim(),
      'address': addressCtl.text.trim(),
      'congenital_disease': congenitalDiseaseCtl.text.trim(),
      'medicine': medicineCtl.text.trim(),
      'allergic_list': allergicListCtl.text.trim(),
      'other': otherCtl.text.trim(),
      'passport_image_path': passportImage?.path,
    };
  }

  /// ล้างข้อมูล Controllers เมื่อไม่ใช้งานแล้ว เพื่อป้องกัน Memory Leak
  void dispose() {
    nameCtl.dispose();
    numberIdCtl.dispose();
    birthdayCtl.dispose();
    phoneCtl.dispose();
    addressCtl.dispose();

    // Dispose Controllers ข้อมูลสุขภาพ
    congenitalDiseaseCtl.dispose();
    medicineCtl.dispose();
    allergicListCtl.dispose();
    otherCtl.dispose();
  }
}
