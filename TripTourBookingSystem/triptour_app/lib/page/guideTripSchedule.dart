import 'package:flutter/material.dart';
import 'package:triptour_app/page/guideHome.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:triptour_app/severGetApi.dart';

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

  Future<void> _finishRound(Map<String, dynamic> round) async {
    final roundId = int.tryParse(round['round_id']?.toString() ?? '');
    if (roundId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปิดรอบทัวร์'),
        content: Text(
          'ต้องการสิ้นสุดทริป "${round['tour_name'] ?? 'ทัวร์'}" นี้หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await Serverapi.closeGuideTourRound(
      roundId: roundId,
      guideId: widget.guideId,
    );

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      await _loadManagedRounds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปิดรอบทัวร์สำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['body']['message'] ?? 'ไม่สามารถปิดรอบทัวร์ได้'),
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
        title: const Text('ตารางทริปทัวร์'),
        backgroundColor: Colors.amber.shade400,
        actions: [
          IconButton(
            onPressed: _loadManagedRounds,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _managedRounds.isEmpty
          ? const Center(child: Text('ยังไม่มีทริปที่คุณรับผิดชอบ'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _managedRounds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final round = _managedRounds[index];
                final status = (round['status'] ?? '').toString();
                final tourName = round['tour_name'] ?? 'ทัวร์';
                final startDate = round['start_date'] ?? '-';
                final endDate = round['end_date'] ?? '-';
                final count = round['count'] ?? 0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.map,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tourName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'วันที่: $startDate - $endDate',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'จำนวนที่นั่ง: $count คน',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'สถานะ: ${_statusLabel(status)}',
                                    style: TextStyle(
                                      color:
                                          status.toLowerCase() == 'finish' ||
                                              status.toLowerCase() ==
                                                  'completed'
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
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
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('ไปแชททัวร์นี้'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // if (Guidehome.canFinishRound(status))
                        //   SizedBox(
                        //     width: double.infinity,
                        //     child: FilledButton.icon(
                        //       onPressed: () => _finishRound(round),
                        //       icon: const Icon(Icons.check_circle_outline),
                        //       label: const Text('ปิดรอบทัวร์'),
                        //       style: FilledButton.styleFrom(
                        //         backgroundColor: Colors.green,
                        //         foregroundColor: Colors.white,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
