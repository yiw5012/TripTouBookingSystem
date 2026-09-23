import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';

class AddPassengerPage extends StatefulWidget {
  final int index;
  final List<String> genderOptions;
  final PassengerFormControllers? existingPassenger;

  const AddPassengerPage({
    super.key,
    required this.index,
    required this.genderOptions,
    this.existingPassenger,
  });

  @override
  State<AddPassengerPage> createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  // 1. Controllers ข้อมูลส่วนตัว
  final nameCtl = TextEditingController();
  final numberIdCtl = TextEditingController();
  final birthdayCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final addressCtl = TextEditingController();
  late String gender;

  // 2. Controllers ข้อมูลสุขภาพ / อื่นๆ
  final congenitalDiseaseCtl = TextEditingController(); // โรคประจำตัว
  final medicineCtl = TextEditingController(); // ยาที่ใช้ประจำ
  final allergicListCtl = TextEditingController(); // รายการแพ้ยา/อาหาร
  final otherCtl = TextEditingController(); // อื่น ๆ

  File? _selectedPassportImage;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    gender = widget.genderOptions.isNotEmpty
        ? widget.genderOptions.first
        : 'ชาย';

    final existing = widget.existingPassenger;
    if (existing != null) {
      nameCtl.text = existing.nameCtl.text;
      numberIdCtl.text = existing.numberIdCtl.text;
      birthdayCtl.text = existing.birthdayCtl.text;
      phoneCtl.text = existing.phoneCtl.text;
      addressCtl.text = existing.addressCtl.text;
      if (widget.genderOptions.contains(existing.gender)) {
        gender = existing.gender;
      }
      congenitalDiseaseCtl.text = existing.congenitalDiseaseCtl.text;
      medicineCtl.text = existing.medicineCtl.text;
      allergicListCtl.text = existing.allergicListCtl.text;
      otherCtl.text = existing.otherCtl.text;
      _selectedPassportImage = existing.passportImage;
    }
  }

  @override
  void dispose() {
    // Dispose Controller ครบทุกตัว ป้องกัน Memory Leak
    nameCtl.dispose();
    numberIdCtl.dispose();
    birthdayCtl.dispose();
    phoneCtl.dispose();
    addressCtl.dispose();
    congenitalDiseaseCtl.dispose();
    medicineCtl.dispose();
    allergicListCtl.dispose();
    otherCtl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthdayCtl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickPassportImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedPassportImage = File(pickedFile.path);
      });
    }
  }

  void _save() {
    if (nameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อ-นามสกุล'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final existing = widget.existingPassenger;
    final ctrl =
        existing ??
        PassengerFormControllers(
          passengerIndex: widget.index,
          typeName: 'ผู้ร่วมเดินทาง',
        );

    ctrl.nameCtl.text = nameCtl.text;
    ctrl.numberIdCtl.text = numberIdCtl.text;
    ctrl.birthdayCtl.text = birthdayCtl.text;
    ctrl.phoneCtl.text = phoneCtl.text;
    ctrl.addressCtl.text = addressCtl.text;
    ctrl.gender = gender;

    ctrl.congenitalDiseaseCtl.text = congenitalDiseaseCtl.text;
    ctrl.medicineCtl.text = medicineCtl.text;
    ctrl.allergicListCtl.text = allergicListCtl.text;
    ctrl.otherCtl.text = otherCtl.text;
    ctrl.passportImage = _selectedPassportImage;

    Navigator.of(context).pop(ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.existingPassenger != null
              ? 'แก้ไขข้อมูลผู้เดินทาง'
              : 'เพิ่มผู้เดินทาง',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 47, 238, 143),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. หมวดหมู่ข้อมูลส่วนตัว
              _buildSectionCard(
                title: "ข้อมูลส่วนตัว",
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    ctl: nameCtl,
                    label: "ชื่อ-นามสกุล",
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    ctl: numberIdCtl,
                    label: "เลขบัตรประชาชน / Passport",
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: IgnorePointer(
                            child: _buildTextField(
                              ctl: birthdayCtl,
                              label: "วันเกิด",
                              icon: Icons.calendar_today_outlined,
                              hint: "YYYY-MM-DD",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: gender,
                          decoration: InputDecoration(
                            labelText: "เพศ",
                            prefixIcon: const Icon(Icons.wc, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => gender = v ?? gender),
                          items: widget.genderOptions
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(
                                    g,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    ctl: phoneCtl,
                    label: "เบอร์โทรศัพท์",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    ctl: addressCtl,
                    label: "ที่อยู่",
                    icon: Icons.home_outlined,
                    maxLines: 2,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. หมวดหมู่ข้อมูลสุขภาพ & รายละเอียดเพิ่มเติม
              _buildSectionCard(
                title: "ข้อมูลสุขภาพ ",
                icon: Icons.medical_services_outlined,
                children: [
                  _buildTextField(
                    ctl: congenitalDiseaseCtl,
                    label: "โรคประจำตัว",
                    hint: "ถ้าไม่มีให้เว้นว่างไว้",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(ctl: medicineCtl, label: "ยาที่ใช้ประจำ"),
                  const SizedBox(height: 12),
                  _buildTextField(
                    ctl: allergicListCtl,
                    label: "รายการแพ้ยา / อาหาร",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(ctl: otherCtl, label: "อื่น ๆ", maxLines: 3),
                ],
              ),

              const SizedBox(height: 16),

              // 3. หมวดหมู่เอกสารยืนยันตัวตน (Passport / ID Card)
              _buildSectionCard(
                title: "เอกสารยืนยันตัวตน",
                icon: Icons.article_outlined,
                children: [
                  GestureDetector(
                    onTap: _pickPassportImage,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _selectedPassportImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    _selectedPassportImage!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _selectedPassportImage = null,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: Colors.teal.shade600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'แตะเพื่ออัปโหลด Passport ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'รองรับไฟล์ภาพ JPG, PNG',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _save,
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Build UI Widgets ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctl,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
