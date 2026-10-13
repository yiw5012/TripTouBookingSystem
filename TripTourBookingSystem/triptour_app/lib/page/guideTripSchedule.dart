import 'package:flutter/material.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/services/severGetApi.dart';

class GuideTripSchedulePage extends StatefulWidget {
  final int guideId;

  const GuideTripSchedulePage({super.key, required this.guideId});

  @override
  State<GuideTripSchedulePage> createState() => _GuideTripSchedulePageState();
}

class _GuideTripSchedulePageState extends State<GuideTripSchedulePage> {
  bool _isLoading = true;
  List<dynamic> _managedRounds = [];

  @override
  void initState() {
    super.initState();
    _loadManagedRounds();
  }

  Future<void> _loadManagedRounds() async {
    setState(() => _isLoading = true);

    final result = await Severgetapi.getGuideTourRounds(
      guideId: widget.guideId,
    );

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      setState(() {
        _managedRounds = result['body']['data'] ?? [];
      });
    } else {
      setState(() => _managedRounds = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['body']['message'] ?? 'ไม่สามารถโหลดตารางทริปได้',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => _isLoading = false);
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
    final openCount = _managedRounds.where((round) {
      final status = (round['status'] ?? '').toString().toLowerCase();
      return status == 'open';
    }).length;

    final closedCount = _managedRounds.where((round) {
      final status = (round['status'] ?? '').toString().toLowerCase();
      return status == 'closed' || status == 'finish' || status == 'completed';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        title: const Text('ตารางทริปทัวร์'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1FAE5B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadManagedRounds,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _managedRounds.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7EAE6)),
                ),
                child: const Text(
                  'ยังไม่มีทริปที่คุณรับผิดชอบ',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1FAE5B), Color(0xFF17A85B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ภาพรวมรอบทัวร์',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_managedRounds.length} รอบทั้งหมด',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        label: 'กำลังเปิด',
                        value: '$openCount',
                        color: const Color(0xFF1FAE5B),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        label: 'ปิดแล้ว',
                        value: '$closedCount',
                        color: const Color(0xFFEDB53A),
                        icon: Icons.lock_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'รายการรอบทัวร์',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_managedRounds.length, (index) {
                  final round = _managedRounds[index];
                  final status = (round['status'] ?? '').toString();
                  final tourName = round['tour_name'] ?? 'ทัวร์';
                  final startDate = round['start_date'] ?? '-';
                  final endDate = round['end_date'] ?? '-';
                  final count = round['count'] ?? 0;
                  final statusText = _statusLabel(status);
                  final statusColor =
                      status.toLowerCase() == 'closed' ||
                          status.toLowerCase() == 'finish' ||
                          status.toLowerCase() == 'completed'
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1FAE5B).withOpacity(0.1),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tourName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'วันที่: $startDate - $endDate',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_alt_outlined,
                                        size: 15,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'จำนวนที่นั่ง: $count คน',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  final roomId = (round['room_id'] ?? '')
                                      .toString()
                                      .trim();
                                  final roundId = (round['round_id'] ?? '')
                                      .toString()
                                      .trim();
                                  final selectedRoomId = roomId.isNotEmpty
                                      ? roomId
                                      : (roundId.isNotEmpty
                                            ? 'round_$roundId'
                                            : 'guide_room_${widget.guideId}');

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                        userRole: 'guide',
                                        selectedRoomId: selectedRoomId,
                                        selectedRoomName: tourName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                ),
                                label: const Text('ไปแชท'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1FAE5B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
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
}
