import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/navbar/chat.dart'; // 👈 นำเข้าไฟล์ ChatPage ของคุณ

class Guidehome extends StatefulWidget {
  const Guidehome({super.key});

  @override
  State<Guidehome> createState() => _GuidehomeState();
}

class _GuidehomeState extends State<Guidehome> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("หน้าหลักสำหรับไกด์ 🧭"),
        backgroundColor: Colors.amber.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // StreamBuilder ใน Wrapper จะตรวจพบการ Logout และพากลับหน้า Login อัตโนมัติ
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. การ์ดแสดงข้อมูลไกด์
            Card(
              color: Colors.amber.shade100,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.explore, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ยินดีต้อนรับ, ไกด์!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentUser?.email ?? '',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. เมนูด่วน (Quick Navigation)
            const Text(
              "เมนูการทำงาน",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    title: "ห้องแชตลูกทัวร์",
                    icon: Icons.chat_bubble_outline,
                    color: Colors.orange,
                    onTap: () {
                      // ส่ง userRole: 'guide' เข้าหน้าแชต
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ChatPage(userRole: 'guide'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuCard(
                    title: "ตารางทริปทัวร์",
                    icon: Icons.calendar_month_outlined,
                    color: Colors.amber.shade700,
                    onTap: () {
                      // TODO: นำไปหน้าดูตารางงาน
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. รายการทริปปัจจุบัน
            const Text(
              "ทริปที่กำลังดูแลอยู่",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.map, color: Colors.amber, size: 36),
                title: const Text("ทริปเกาะช้าง 3 วัน 2 คืน 🏝️"),
                subtitle: const Text("ลูกทัวร์: 12 คน | สถานะ: กำลังดำเนินการ"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(userRole: 'guide'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
