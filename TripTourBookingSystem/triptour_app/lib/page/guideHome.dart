import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/guideProfile.dart';
import 'package:triptour_app/page/guideTripSchedule.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:triptour_app/severGetApi.dart';

class Guidehome extends StatefulWidget {
  const Guidehome({super.key});

  static bool canFinishRound(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    return normalized == 'open' ||
        normalized == 'pending' ||
        normalized == 'active' ||
        normalized == 'closed';
  }

  @override
  State<Guidehome> createState() => _GuidehomeState();
}

class _GuidehomeState extends State<Guidehome> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  int? _guideId;
  List<dynamic> _managedRounds = [];

  @override
  void initState() {
    super.initState();
    _loadGuideData();
  }

  Future<void> _loadGuideData() async {
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final profileResult = await Serverapi.getGuideProfile(
      googleId: currentUser!.uid,
    );
    final profileBody = profileResult['body'];

    if (!mounted) return;

    if (profileResult['statusCode'] == 200 && profileBody['success'] == true) {
      final guideData = profileBody['data'] as Map<String, dynamic>;
      final parsedGuideId = int.tryParse(
        guideData['guide_id']?.toString() ?? '',
      );

      if (parsedGuideId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลไกด์ที่เชื่อมกับบัญชีนี้')),
        );
        return;
      }

      _guideId = parsedGuideId;
      await _loadManagedRounds();
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(profileBody['message'] ?? 'โหลดข้อมูลไกด์ไม่สำเร็จ'),
      ),
    );
  }

  Future<void> _loadManagedRounds() async {
    if (_guideId == null) return;

    final result = await Severgetapi.getGuideTourRounds(guideId: _guideId!);

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      setState(() {
        _managedRounds = result['body']['data'] ?? [];
      });
      return;
    }

    setState(() => _managedRounds = []);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['body']['message'] ?? 'ไม่สามารถโหลดรอบทัวร์ที่ไกด์ดูแลได้',
        ),
      ),
    );
  }

  Future<void> _finishRound(Map<String, dynamic> round) async {
    final roundId = int.tryParse(round['round_id']?.toString() ?? '');
    if (_guideId == null || roundId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันสิ้นสุดทริป'),
        content: Text(
          'คุณต้องการบันทึกว่าทริป "${round['tour_name'] ?? 'ทัวร์'}" นี้ออกทริปเสร็จสิ้นแล้วใช่หรือไม่?\n\n'
          '*ระบบจะทำการปรับสถานะของลูกทัวร์ที่ชำระเงินแล้วให้เป็น "สำเร็จทริป"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ยืนยันสำเร็จทริป'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await Serverapi.closeGuideTourRound(
      roundId: roundId,
      guideId: _guideId!,
    );

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      await _loadManagedRounds();
      final msg = result['body']['message'] ?? 'บันทึกสำเร็จทริปเรียบร้อย';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['body']['message'] ?? 'ไม่สามารถอัปเดตสถานะได้'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').trim().toLowerCase()) {
      case 'finish':
      case 'completed':
        return 'สิ้นสุดแล้ว';
      case 'open':
        return 'กำลังเปิดให้จอง';
      case 'closed':
        return 'ปิดรับจอง';
      case 'pending':
        return 'รอดำเนินการ';
      default:
        return status ?? 'ไม่ระบุ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลักสำหรับไกด์ 🧭'),
        backgroundColor: Colors.amber.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'โปรไฟล์',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuideProfile()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadManagedRounds,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              child: Icon(
                                Icons.explore,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ยินดีต้อนรับ, ไกด์!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'แก้ไขโปรไฟล์',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GuideProfile(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'เมนูการทำงาน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuCard(
                            title: 'ห้องแชตลูกทัวร์',
                            icon: Icons.chat_bubble_outline,
                            color: Colors.orange,
                            onTap: () {
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
                            title: 'ตารางทริปทัวร์',
                            icon: Icons.calendar_month_outlined,
                            color: Colors.amber.shade700,
                            onTap: () {
                              if (_guideId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GuideTripSchedulePage(
                                      guideId: _guideId!,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ทริปที่ดูแลอยู่ (${_managedRounds.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_managedRounds.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: Text('ยังไม่มีรอบทัวร์ที่ไกด์ดูแลอยู่'),
                          ),
                        ),
                      )
                    else
                      ..._managedRounds.take(3).map((round) {
                        final status = (round['status'] ?? '').toString();
                        final tourName = round['tour_name'] ?? 'ทัวร์';
                        final startDate = round['start_date'] ?? '-';
                        final endDate = round['end_date'] ?? '-';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(
                              Icons.map,
                              color: Colors.amber,
                              size: 32,
                            ),
                            title: Text(tourName),
                            subtitle: Text(
                              '$startDate - $endDate\nสถานะ: ${_statusLabel(status)}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                  ],
                ),
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
