import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/guideProfile.dart';
import 'package:triptour_app/page/guideTripSchedule.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/services/serverApi.dart';
import 'package:triptour_app/services/severGetApi.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';

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
    final statusCounts = <String, int>{};
    for (final round in _managedRounds) {
      final status = (round['status'] ?? '').toString();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        title: const Text('หน้าหลักไกด์'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1FAE5B),
        foregroundColor: Colors.white,
        elevation: 0,
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
            icon: const Icon(Icons.logout_rounded),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1FAE5B), Color(0xFF17A85B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1FAE5B).withOpacity(0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ยินดีต้อนรับ, ไกด์!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser?.email ?? 'guide@triptour.com',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GuideProfile(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_note_rounded),
                            color: Colors.white,
                            tooltip: 'แก้ไขข้อมูล',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'รอบทั้งหมด',
                            value: '${_managedRounds.length}',
                            icon: Icons.event_available_rounded,
                            color: const Color(0xFF1FAE5B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'กำลังดูแล',
                            value: '${statusCounts['open'] ?? 0}',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFEDB53A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'เมนูการทำงาน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuCard(
                            title: 'ห้องแชทลูกทัวร์',
                            icon: Icons.chat_bubble_outline_rounded,
                            color: const Color(0xFF1FAE5B),
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
                            icon: Icons.calendar_month_rounded,
                            color: const Color(0xFFEDB53A),
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
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ทริปที่ดูแลอยู่',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1FAE5B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_managedRounds.length} รอบ',
                            style: const TextStyle(
                              color: Color(0xFF1FAE5B),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_managedRounds.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7EAE6)),
                        ),
                        child: const Center(
                          child: Text(
                            'ยังไม่มีรอบทัวร์ที่ไกด์ดูแลอยู่',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    else
                      ..._managedRounds.take(3).map((round) {
                        final status = (round['status'] ?? '').toString();
                        final tourName = round['tour_name'] ?? 'ทัวร์';
                        final startDate = _formatDateText(round['start_date']);
                        final endDate = _formatDateText(round['end_date']);
                        final statusColor =
                            (status.toLowerCase() == 'closed' ||
                                status.toLowerCase() == 'finish')
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE7EAE6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              final int? tourId = int.tryParse(
                                round['tour_id']?.toString() ?? '',
                              );

                              if (tourId == null) {
                                debugPrint('Guide round data: $round');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'ไม่พบรหัสทัวร์ กรุณาตรวจสอบข้อมูลรอบทัวร์',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailTour(tourId: tourId, isGuide: true),
                                ),
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1FAE5B,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.map_outlined,
                                    color: Color(0xFF1FAE5B),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tourName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF8F1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_month_rounded,
                                              size: 16,
                                              color: Color(0xFF1FAE5B),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$startDate - $endDate',
                                                style: const TextStyle(
                                                  color: Color(0xFF267747),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDateText(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();
    if (text.isEmpty) return '-';

    final datePart = text.split('T').first.split(' ').first;
    final parts = datePart.split('-');

    if (parts.length == 3 && parts[0].length == 4) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year != null && month != null && day != null) {
        return '${day.toString().padLeft(2, '0')}/'
            '${month.toString().padLeft(2, '0')}/'
            '${year + 543}';
      }
    }

    return text;
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ],
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EAE6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
