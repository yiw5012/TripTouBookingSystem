import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';
import 'package:triptour_app/page/booking/widgets/passenger_counter.dart';

class Step1TourDetails extends StatefulWidget {
  final Map<String, dynamic> tourData;
  final Map<String, dynamic> selectedRound;
  final List<String> passengerTypes;
  final List<int> passengerCounts;
  final List<int> prices;
  final List<Map<String, dynamic>> roomBreakdown;
  final int totalPrice;
  final int estimatedSavings;
  final Function(int index, int delta) onCountChanged;

  const Step1TourDetails({
    super.key,
    required this.tourData,
    required this.selectedRound,
    required this.passengerTypes,
    required this.passengerCounts,
    required this.prices,
    required this.roomBreakdown,
    required this.totalPrice,
    required this.estimatedSavings,
    required this.onCountChanged,
  });

  @override
  State<Step1TourDetails> createState() => _Step1TourDetailsState();
}

class _Step1TourDetailsState extends State<Step1TourDetails> {
  // 0 = เหมาห้องพัก/กลุ่ม, 1 = พักแชร์ประหยัด (Solo)
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // หากผู้ใช้มีรายการเลือกแชร์ห้องอยู่แล้ว ให้เปิดมาที่ Tab แชร์ห้องอัตโนมัติ
    if (widget.passengerCounts[3] > 0 || widget.passengerCounts[4] > 0) {
      _selectedTab = 1;
    }
  }

  // ดึงรายการ Index ตาม Tab ที่เลือก
  List<int> get _currentIndices {
    if (_selectedTab == 0) {
      return [0, 1, 2, 5]; // เหมา 2 คน, เหมา 3 คน, พักเดี่ยว, เด็ก
    } else {
      return [3, 4]; // แชร์ 2 คน, แชร์ 3 คน
    }
  }

  // คำนวณจำนวนรายการที่เลือกในแต่ละ Tab (ใช้แสดงบน Badge ของ Tab)
  int _getTabCount(int tabIndex) {
    if (tabIndex == 0) {
      return widget.passengerCounts[0] +
          widget.passengerCounts[1] +
          widget.passengerCounts[2] +
          widget.passengerCounts[5];
    } else {
      return widget.passengerCounts[3] + widget.passengerCounts[4];
    }
  }

  // ตรวจสอบสิทธิ์การกดเพิ่ม (+)
  bool _canIncrement(int index) {
    final bool isSharedIndex = index == 3 || index == 4;
    final bool isChildIndex = index == 5;
    final bool hasSharedSelected =
        widget.passengerCounts[3] > 0 || widget.passengerCounts[4] > 0;
    final bool hasNonSharedSelected =
        widget.passengerCounts[0] > 0 ||
        widget.passengerCounts[1] > 0 ||
        widget.passengerCounts[2] > 0 ||
        widget.passengerCounts[5] > 0;
    final bool hasAdultSelected =
        widget.passengerCounts[0] > 0 ||
        widget.passengerCounts[1] > 0 ||
        widget.passengerCounts[2] > 0 ||
        widget.passengerCounts[3] > 0 ||
        widget.passengerCounts[4] > 0;

    if (isChildIndex && !hasAdultSelected) {
      return false;
    }

    if (isSharedIndex) {
      if (hasNonSharedSelected) return false;
      if (index == 3 && widget.passengerCounts[4] > 0) return false;
      if (index == 4 && widget.passengerCounts[3] > 0) return false;
    } else {
      if (hasSharedSelected) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tourName = widget.tourData['tour_name'] ?? 'Tour';
    final departure = widget.selectedRound['departure'] ?? 'Unknown';
    final destination = widget.selectedRound['destination'] ?? 'Unknown';
    final startDate = _formatDate(widget.selectedRound['start_date']);
    final endDate = _formatDate(widget.selectedRound['end_date']);
    final airline = widget.selectedRound['airline'] ?? 'N/A';

    final int capacity =
        int.tryParse(widget.selectedRound['count']?.toString() ?? '0') ?? 0;
    final int totalPaid =
        int.tryParse(widget.selectedRound['total_paid']?.toString() ?? '0') ??
        0;
    final int availableSeats = capacity - totalPaid;

    final bool hasSharedSelected =
        widget.passengerCounts[3] > 0 || widget.passengerCounts[4] > 0;
    final bool hasChildSelected = widget.passengerCounts[5] > 0;
    final bool hasAdultSelected =
        widget.passengerCounts[0] > 0 ||
        widget.passengerCounts[1] > 0 ||
        widget.passengerCounts[2] > 0 ||
        widget.passengerCounts[3] > 0 ||
        widget.passengerCounts[4] > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tourName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _simpleInfoRow('เส้นทาง', '$departure → $destination'),
              _simpleInfoRow('วันเดินทาง', '$startDate ถึง $endDate'),
              _simpleInfoRow('สายการบิน', airline),
              _simpleInfoRow(
                'ที่นั่งคงเหลือ',
                '$availableSeats / $capacity ที่',
                valueColor: availableSeats > 0
                    ? Colors.green.shade700
                    : Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // -------------------------------------------------------------
        // Nav Tab แยกซ้าย-ขวา (Segmented Control)
        // -------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTabButton(
                index: 0,
                icon: Icons.hotel_rounded,
                title: 'เดินทางทั่วไป',
                badgeCount: _getTabCount(0),
              ),
              const SizedBox(width: 4),
              _buildTabButton(
                index: 1,
                icon: Icons.group_add_rounded,
                title: 'พักแชร์',
                badgeCount: _getTabCount(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เงื่อนไขสำคัญ: เด็กต่ำกว่า 11 ปี ต้องเดินทางพร้อมผู้ใหญ่อย่างน้อย 1 คน และไม่สามารถจองเดินทางลำพังได้',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Banner แจ้งเตือนสิทธิประโยชน์/เงื่อนไขตาม Tab
        if (_selectedTab == 1) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.green, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ตัวเลือกพักแชร์สำหรับ Solo Traveler',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ระบบจะจัดจับคู่ห้องพักให้โดยอัตโนมัติ',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      if (widget.estimatedSavings > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'ประหยัดได้ประมาณ ${formatCurrency(widget.estimatedSavings)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (hasSharedSelected) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'คุณกำลังเลือกตัวเลือกพักแชร์อยู่ หากต้องการเปลี่ยนเป็นห้องเหมา ให้ลดจำนวนใน Tab พักแชร์ เป็น 0 ก่อน',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (hasChildSelected && hasAdultSelected) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'มีเด็กอยู่ในรายการจองแล้ว กรุณาคงผู้ใหญ่อย่างน้อย 1 คนไว้เสมอ',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        const Divider(),

        // -------------------------------------------------------------
        // รายการปุ่มเลือกห้องพักตาม Tab ที่แอ็กทีฟ
        // -------------------------------------------------------------
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentIndices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final index = _currentIndices[i];
            final bool canInc = _canIncrement(index);
            return PassengerCounterRow(
              title: widget.passengerTypes[index],
              count: widget.passengerCounts[index],
              price: widget.prices[index],
              onIncrement: canInc
                  ? () => widget.onCountChanged(index, 1)
                  : null,
              onDecrement: () => widget.onCountChanged(index, -1),
            );
          },
        ),

        const Divider(height: 24),

        // สรุปยอดและรายละเอียดห้องพัก
        if (widget.roomBreakdown.isNotEmpty) ...[
          const Text(
            'รายละเอียดที่เลือก',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.roomBreakdown.map((room) {
            final roomType = room['room_type'] as String? ?? 'single';
            final quantity = (room['quantity'] as int?) ?? 0;
            final unitPrice = (room['unit_price'] as int?) ?? 0;
            final lineTotal = (room['line_total'] as int?) ?? 0;

            final label = switch (roomType) {
              'double' => 'ผู้ใหญ่ 2 พัก 1 ห้อง',
              'triple' => 'ผู้ใหญ่ 3 พัก 1 ห้อง',
              'single' => 'ผู้ใหญ่ 1 พักเดี่ยว (ห้องส่วนตัว)',
              'shared_double' => 'ผู้ใหญ่ 1 แชร์ห้อง 2 คน (ให้ไกด์จัดคู่)',
              'shared_triple' => 'ผู้ใหญ่ 1 แชร์ห้อง 3 คน (ให้ไกด์จัด 3 คน)',
              'child' => 'เด็ก (เตียงเดียวกับผู้ปกครอง)',
              _ => roomType,
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$label x$quantity ${unitPrice > 0 ? "• ${formatCurrency(unitPrice)}/รายการ" : "(ฟรี)"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    formatCurrency(lineTotal),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดรวมปัจจุบัน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                formatCurrency(widget.totalPrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(value.toString());
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      return '$day/$month/$year';
    } catch (_) {
      return value.toString();
    }
  }

  Widget _simpleInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? const Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ปุ่มสร้าง Tab Nav
  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String title,
    required int badgeCount,
  }) {
    final bool isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
