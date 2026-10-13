import 'package:flutter/material.dart';
import 'package:triptour_app/page/navbar/pdfService.dart';
import 'package:triptour_app/services/serverApi.dart';

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
          backgroundColor: const Color(0xFFF5F7F3),
          appBar: AppBar(
            title: const Text("ข้อมูลลูกทัวร์"),
            centerTitle: true,
            backgroundColor: const Color(0xFF1FAE5B),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: "ส่งออก PDF",
                onPressed: () {
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1FAE5B), Color(0xFF17A85B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          backgroundImage:
                              (profileImg != null &&
                                  profileImg.toString().isNotEmpty)
                              ? NetworkImage(profileImg)
                              : null,
                          child:
                              (profileImg == null ||
                                  profileImg.toString().isEmpty)
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName.isEmpty ? "ไม่ระบุชื่อ" : fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            data['role']?.toString().toUpperCase() ?? 'USER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      PdfService.generateAndPrintMemberPdf(data);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text("ส่งออก PDF"),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1FAE5B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7EAE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ข้อมูลการติดต่อ",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1B1B),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        Icons.email_outlined,
                        "อีเมล",
                        data['email'],
                        color: const Color(0xFF1FAE5B),
                      ),
                      _buildInfoCard(
                        Icons.phone_outlined,
                        "เบอร์โทรศัพท์",
                        data['phone'],
                        color: const Color(0xFF1FAE5B),
                      ),
                      _buildInfoCard(
                        Icons.wc_outlined,
                        "เพศ / วันเกิด",
                        "${data['gender'] ?? '-'} (${data['birthday'] ?? '-'})",
                        color: const Color(0xFF1FAE5B),
                      ),
                      _buildInfoCard(
                        Icons.home_outlined,
                        "ที่อยู่",
                        data['address'],
                        color: const Color(0xFF1FAE5B),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7EAE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ข้อมูลสุขภาพ & โรคประจำตัว",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1B1B),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        Icons.medical_information_outlined,
                        "โรคประจำตัว",
                        data['congenital_disease'],
                        color: const Color(0xFF1FAE5B),
                      ),
                      _buildInfoCard(
                        Icons.medication_outlined,
                        "ยาที่ต้องพกพา",
                        data['medicine'],
                        color: const Color(0xFF1FAE5B),
                      ),
                      _buildInfoCard(
                        Icons.warning_amber_rounded,
                        "ประวัติการแพ้",
                        data['allergic_list'],
                        iconColor: Colors.red,
                        color: const Color(0xFF1FAE5B),
                      ),
                      _buildInfoCard(
                        Icons.note_alt_outlined,
                        "เพิ่มเติม",
                        data['others'],
                        color: const Color(0xFF1FAE5B),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7EAE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "เอกสารประจำตัว",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1B1B),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        Icons.badge_outlined,
                        "เลขบัตรประชาชน / พาสปอร์ต",
                        data['number_id'],
                        color: const Color(0xFF1FAE5B),
                      ),
                      if (passportImg != null &&
                          passportImg.toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "รูปหน้าพาสปอร์ต:",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            passportImg,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 100,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Text("โหลดรูปไม่สำเร็จ"),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
    Color? color,
  }) {
    final displayValue = (value == null || value.trim().isEmpty) ? "-" : value;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAE6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF1FAE5B)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color ?? const Color(0xFF1FAE5B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
