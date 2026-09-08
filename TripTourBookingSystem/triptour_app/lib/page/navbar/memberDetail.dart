import 'package:flutter/material.dart';
import 'package:triptour_app/page/navbar/pdfService.dart';
import 'package:triptour_app/serverApi.dart';

class MemberDetailPage extends StatelessWidget {
  final String targetUid;

  const MemberDetailPage({super.key, required this.targetUid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Serverapi.getMemberDetail(targetUid),
      builder: (context, snapshot) {
        // 1. สถานะกำลังโหลด
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("ข้อมูลลูกทัวร์")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // 2. สถานะเกิดข้อผิดพลาด หรือไม่พบข้อมูล
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("ข้อมูลลูกทัวร์")),
            body: const Center(child: Text("ไม่พบข้อมูลสมาชิก")),
          );
        }

        // 3. โหลดข้อมูลสำเร็จ ดึง data มาใช้งานได้เลย
        final data = snapshot.data!;
        final fullName =
            "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim();
        final profileImg = data['image_profile'];
        final passportImg = data['image_passport'];

        return Scaffold(
          appBar: AppBar(
            title: const Text("ข้อมูลลูกทัวร์"),
            backgroundColor: Colors.amber.shade300,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: "บันทึกเป็น PDF / ปริ้นท์",
                onPressed: () {
                  // เรียกใช้งาน data ได้ทันทีไม่ต้องผ่านตัวแปรแปรสภาพ
                  PdfService.generateAndPrintMemberPdf(data);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. รูปโปรไฟล์ + ชื่อ
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            (profileImg != null &&
                                profileImg.toString().isNotEmpty)
                            ? NetworkImage(profileImg)
                            : null,
                        child:
                            (profileImg == null ||
                                profileImg.toString().isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName.isEmpty ? "ไม่ระบุชื่อ" : fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          data['role']?.toString().toUpperCase() ?? 'USER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. ข้อมูลการติดต่อส่วนตัว
                const Text(
                  "ข้อมูลการติดต่อ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(Icons.email, "อีเมล", data['email']),
                _buildInfoCard(Icons.phone, "เบอร์โทรศัพท์", data['phone']),
                _buildInfoCard(
                  Icons.wc,
                  "เพศ / วันเกิด",
                  "${data['gender'] ?? '-'} (${data['birthday'] ?? '-'})",
                ),
                _buildInfoCard(Icons.home, "ที่อยู่", data['address']),

                const Divider(height: 30),

                // 3. ข้อมูลสุขภาพ & ข้อควรระวัง
                const Text(
                  "ข้อมูลสุขภาพ & โรคประจำตัว",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  Icons.medical_information,
                  "โรคประจำตัว",
                  data['congenital_disease'],
                ),
                _buildInfoCard(
                  Icons.medication,
                  "ยาที่ต้องพกพา",
                  data['medicine'],
                ),
                _buildInfoCard(
                  Icons.warning_amber_rounded,
                  "ประวัติการแพ้",
                  data['allergic_list'],
                  iconColor: Colors.red,
                ),
                _buildInfoCard(Icons.note, "เพิ่มเติม", data['others']),

                const Divider(height: 30),

                // 4. เอกสารประจำตัว & รูปพาสปอร์ต
                const Text(
                  "เอกสารประจำตัว",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  Icons.badge,
                  "เลขบัตรประชาชน / พาสปอร์ต",
                  data['number_id'],
                ),

                if (passportImg != null &&
                    passportImg.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "รูปหน้าพาสปอร์ต:",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      passportImg,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(child: Text("โหลดรูปไม่สำเร็จ")),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String? value, {
    Color? iconColor,
  }) {
    final displayValue = (value == null || value.trim().isEmpty) ? "-" : value;
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blueGrey),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          displayValue,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
