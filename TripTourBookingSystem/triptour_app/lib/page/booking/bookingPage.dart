import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';
import 'package:triptour_app/page/booking/widgets/step1_tour_details.dart';
import 'package:triptour_app/page/booking/widgets/step2_passenger.dart';
import 'package:triptour_app/page/booking/widgets/step3_payment.dart';
import 'package:triptour_app/services/serverApi.dart';
import 'package:triptour_app/services/serviceBookingApi.dart';

String formatCurrency(dynamic value) {
  if (value == null) return '-';
  final number = num.tryParse(value.toString());
  if (number == null) return value.toString();

  final formatted = number.toInt().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '฿$formatted';
}

class BookingTourPage extends StatefulWidget {
  final String roundId;
  final String tourId;

  const BookingTourPage({
    super.key,
    required this.roundId,
    required this.tourId,
  });

  @override
  State<BookingTourPage> createState() => _BookingTourPageState();
}

class _BookingTourPageState extends State<BookingTourPage> {
  Map<String, dynamic> tourData = {};
  List<dynamic> rounds = [];
  bool isLoading = true;
  int _currentStep = 1;
  List<PassengerFormControllers> passengerForms = [];
  Map<String, dynamic> member = {};

  final contactNameCtl = TextEditingController();
  final contactPhoneCtl = TextEditingController();
  final contactEmailCtl = TextEditingController();

  final List<String> selectedGender = ['Male', 'Female', 'Other'];

  // ตัวนับจำนวนแยกเป็น 6 ประเภทห้อง/ผู้เดินทาง
  List<int> passengerCounts = [0, 0, 0, 0, 0, 0];

  final List<String> passengerTypes = [
    'ผู้ใหญ่ 2 พัก 1 ห้อง (เหมาห้อง 2 คน)',
    'ผู้ใหญ่ 3 พัก 1 ห้อง (เหมาห้อง 3 คน)',
    'ผู้ใหญ่ 1 พักเดี่ยว (ห้องส่วนตัว)',
    'ผู้ใหญ่ 1 แชร์ห้อง 2 คน (ไกด์จัดคู่ให้)',
    'ผู้ใหญ่ 1 แชร์ห้อง 3 คน (ไกด์จัด 3 คนให้)',
    'เด็กต่ำกว่า 11 ปี (ไม่เสริมเตียง/ฟรี)',
  ];

  Map<String, dynamic> get selectedRound =>
      rounds.isNotEmpty ? Map<String, dynamic>.from(rounds.first) : {};

  int _parsePrice(dynamic value) {
    final rawValue = value ?? selectedRound['price'] ?? tourData['price'];
    final parsed = num.tryParse(rawValue?.toString() ?? '');
    return parsed?.toInt() ?? 0;
  }

  // คำนวณราคาต่อรายการ/คน
  List<int> get prices => [
    _parsePrice(selectedRound['price_double']), // Index 0: เหมาห้อง 2 คน
    _parsePrice(selectedRound['price_triple']), // Index 1: เหมาห้อง 3 คน
    _parsePrice(selectedRound['price_single']), // Index 2: พักเดี่ยว
    (_parsePrice(selectedRound['price_double']) / 2)
        .round(), // Index 3: แชร์ 2 คน (หาร 2)
    (_parsePrice(selectedRound['price_triple']) / 3)
        .round(), // Index 4: แชร์ 3 คน (หาร 3)
    0, // Index 5: เด็ก ฟรี
  ];

  // จำนวนผู้เดินทางจริงทั้งหมด
  int get actualTravelerCount {
    return (passengerCounts[0] * 2) +
        (passengerCounts[1] * 3) +
        (passengerCounts[2] * 1) +
        (passengerCounts[3] * 1) +
        (passengerCounts[4] * 1) +
        (passengerCounts[5] * 1);
  }

  List<Map<String, dynamic>> get roomSelections {
    final rooms = <Map<String, dynamic>>[];
    if (passengerCounts[0] > 0) {
      rooms.add({'room_type': 'double', 'quantity': passengerCounts[0]});
    }
    if (passengerCounts[1] > 0) {
      rooms.add({'room_type': 'triple', 'quantity': passengerCounts[1]});
    }
    if (passengerCounts[2] > 0) {
      rooms.add({'room_type': 'single', 'quantity': passengerCounts[2]});
    }
    if (passengerCounts[3] > 0) {
      rooms.add({'room_type': 'shared_double', 'quantity': passengerCounts[3]});
    }
    if (passengerCounts[4] > 0) {
      rooms.add({'room_type': 'shared_triple', 'quantity': passengerCounts[4]});
    }
    return rooms;
  }

  List<Map<String, dynamic>> get roomBreakdown {
    final breakdown = <Map<String, dynamic>>[];

    // 1. ผู้ใหญ่ 2 พัก 1 ห้อง
    if (passengerCounts[0] > 0) {
      final unitPrice = prices[0];
      breakdown.add({
        'room_type': 'double',
        'quantity': passengerCounts[0],
        'unit_price': unitPrice,
        'line_total': passengerCounts[0] * unitPrice,
      });
    }

    // 2. ผู้ใหญ่ 3 พัก 1 ห้อง
    if (passengerCounts[1] > 0) {
      final unitPrice = prices[1];
      breakdown.add({
        'room_type': 'triple',
        'quantity': passengerCounts[1],
        'unit_price': unitPrice,
        'line_total': passengerCounts[1] * unitPrice,
      });
    }

    // 3. ผู้ใหญ่ 1 พักเดี่ยว
    if (passengerCounts[2] > 0) {
      final unitPrice = prices[2];
      breakdown.add({
        'room_type': 'single',
        'quantity': passengerCounts[2],
        'unit_price': unitPrice,
        'line_total': passengerCounts[2] * unitPrice,
      });
    }

    // 4. ผู้ใหญ่ 1 แชร์ห้อง 2 คน
    if (passengerCounts[3] > 0) {
      final unitPrice = prices[3];
      breakdown.add({
        'room_type': 'shared_double',
        'quantity': passengerCounts[3],
        'unit_price': unitPrice,
        'line_total': passengerCounts[3] * unitPrice,
      });
    }

    // 5. ผู้ใหญ่ 1 แชร์ห้อง 3 คน
    if (passengerCounts[4] > 0) {
      final unitPrice = prices[4];
      breakdown.add({
        'room_type': 'shared_triple',
        'quantity': passengerCounts[4],
        'unit_price': unitPrice,
        'line_total': passengerCounts[4] * unitPrice,
      });
    }

    // 6. เด็ก (ฟรี)
    if (passengerCounts[5] > 0) {
      breakdown.add({
        'room_type': 'child',
        'quantity': passengerCounts[5],
        'unit_price': 0,
        'line_total': 0,
      });
    }

    return breakdown;
  }

  int get totalPrice {
    return roomBreakdown.fold<int>(0, (sum, room) {
      return sum + ((room['line_total'] as int?) ?? 0);
    });
  }

  // ยอดเงินที่ประหยัดได้เมื่อเลือกแชร์ห้องเทียบกับการพักเดี่ยว
  int get estimatedSavings {
    final singlePrice = prices[2];
    int savings = 0;
    if (passengerCounts[3] > 0) {
      savings += (singlePrice - prices[3]) * passengerCounts[3];
    }
    if (passengerCounts[4] > 0) {
      savings += (singlePrice - prices[4]) * passengerCounts[4];
    }
    return savings > 0 ? savings : 0;
  }

  @override
  void initState() {
    super.initState();
    loadTourData();
  }

  Future<void> loadTourData() async {
    final tourResult = await ServiceBookingApi.getTourById(widget.tourId);
    final roundResult = await ServiceBookingApi.getRoundById(widget.roundId);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null && currentUserId.isNotEmpty) {
      final detail = await Serverapi.getMemberDetail(currentUserId);
      if (detail != null) {
        member = detail;
        contactNameCtl.text =
            "${detail['first_name'] ?? ''} ${detail['last_name'] ?? ''}".trim();
        contactPhoneCtl.text = (detail['phone'] ?? '').toString();
        contactEmailCtl.text = (detail['email'] ?? '').toString();
      }
    }

    if (!mounted) return;

    setState(() {
      tourData = tourResult ?? {};
      if (roundResult != null && roundResult['statusCode'] == 200) {
        final body = roundResult['body'];
        if (body is Map && body['success'] == true) {
          final item = body['data'];
          rounds = item is List ? item : [item];
        }
      }
      isLoading = false;
    });
  }

  Future<void> _selectDateForPassenger(PassengerFormControllers form) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        form.birthdayCtl.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  void dispose() {
    for (var form in passengerForms) {
      form.dispose();
    }
    contactNameCtl.dispose();
    contactPhoneCtl.dispose();
    contactEmailCtl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get bookingPayload {
    // ส่งเฉพาะรายการผู้ร่วมเดินทางจริง (ถ้าเดินทาง 1 คน ค่าจะเป็น [] ซึ่งถูกต้องแล้ว)
    final passengers = passengerForms.map((form) => form.toJson()).toList();

    final route =
        '${selectedRound['departure'] ?? 'Unknown'} → ${selectedRound['destination'] ?? 'Unknown'}';
    final tripDates =
        '${selectedRound['start_date'] ?? 'N/A'} ถึง ${selectedRound['end_date'] ?? 'N/A'}';
    final travelerCount = actualTravelerCount;

    final roomSummary = passengerCounts
        .asMap()
        .entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${passengerTypes[entry.key]}: ${entry.value} รายการ')
        .join(', ');

    return {
      'passengers': passengers,
      'rooms': roomSelections,
      'booking': {
        'tour_id': widget.tourId,
        'round_id': widget.roundId,
        'user_id': FirebaseAuth.instance.currentUser?.uid ?? '',
        'route': route,
        'trip_dates': tripDates,
        'airline': selectedRound['airline'] ?? 'N/A',
        'room_summary': roomSummary.isNotEmpty ? roomSummary : 'ยังไม่ได้เลือก',
        'traveler_count': travelerCount,
        'total_price': totalPrice,
        'currency': 'THB',
        'contact': {
          'name': contactNameCtl.text.trim(),
          'phone': contactPhoneCtl.text.trim(),
          'email': contactEmailCtl.text.trim(),
        },
        'payment': {'method': 'QR', 'status': 'pending'},
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              _buildStepIndicator(),
              const SizedBox(height: 20),
              _buildStepContent(),
              const SizedBox(height: 20),
              if (_currentStep < 3) _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepCircle(1, '1', 'เลือกแพ็กเกจ'),
          _buildStepLine(1),
          _buildStepCircle(2, '2', 'ผู้เดินทาง'),
          _buildStepLine(2),
          _buildStepCircle(3, '3', 'ชำระเงิน'),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Step1TourDetails(
          tourData: tourData,
          selectedRound: selectedRound,
          passengerTypes: passengerTypes,
          passengerCounts: passengerCounts,
          prices: prices,
          roomBreakdown: roomBreakdown,
          totalPrice: totalPrice,
          estimatedSavings: estimatedSavings,
          onCountChanged: (index, delta) {
            final int capacity =
                int.tryParse(selectedRound['count']?.toString() ?? '0') ?? 0;
            final int totalPaid =
                int.tryParse(selectedRound['total_paid']?.toString() ?? '0') ??
                0;
            final int availableSeats = capacity - totalPaid;

            final nextCounts = List<int>.from(passengerCounts);
            final nextValue = nextCounts[index] + delta;
            if (delta > 0 && nextValue >= 0) {
              nextCounts[index] = nextValue;

              final nextTravelerCount =
                  (nextCounts[0] * 2) +
                  (nextCounts[1] * 3) +
                  (nextCounts[2] * 1) +
                  (nextCounts[3] * 1) +
                  (nextCounts[4] * 1) +
                  (nextCounts[5] * 1);

              if (nextTravelerCount > availableSeats) {
                _showSnackBar(
                  'ที่นั่งคงเหลือไม่พอ (เหลืออีกเพียง $availableSeats ที่)',
                  Colors.orange,
                );
                return;
              }
            }

            setState(() {
              final newCount = passengerCounts[index] + delta;
              if (newCount >= 0) {
                passengerCounts[index] = newCount;
              }
            });
          },
        );
      case 2:
        final expectedCount = actualTravelerCount;
        final roomSummary = passengerCounts
            .asMap()
            .entries
            .where((entry) => entry.value > 0)
            .map(
              (entry) => '${passengerTypes[entry.key]}: ${entry.value} รายการ',
            )
            .join(', ');

        return Step2PassengerForm(
          imageUrl: tourData['image_url'],
          tourTitle: tourData['tour_name'],
          passengerForms: passengerForms,
          genderOptions: selectedGender,
          onSelectDate: _selectDateForPassenger,
          expectedCount: expectedCount,
          route:
              '${selectedRound['departure'] ?? 'Unknown'} → ${selectedRound['destination'] ?? 'Unknown'}',
          tripDates:
              '${selectedRound['start_date'] ?? 'N/A'} ถึง ${selectedRound['end_date'] ?? 'N/A'}',
          airline: selectedRound['airline'] ?? 'N/A',
          roomSummary: roomSummary.isNotEmpty ? roomSummary : 'ยังไม่ได้เลือก',
          travelerSummary: '$expectedCount คน',
          contactNameCtl: contactNameCtl,
          contactPhoneCtl: contactPhoneCtl,
          contactEmailCtl: contactEmailCtl,
        );
      case 3:
        final currentMemberId = member['member_id']?.toString() ?? '';
        if (currentMemberId.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'ไม่พบข้อมูลสมาชิก กรุณาเข้าสู่ระบบก่อนทำการจอง',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            ),
          );
        }
        return Step3Payment(
          totalPrice: totalPrice,
          bookingPayload: bookingPayload,
          memberId: currentMemberId,
          roundId: widget.roundId,
          onBookingStatusChanged: (status) {},
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('ย้อนกลับ'),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
            ),
            onPressed: _handleNextStep,
            child: const Text(
              'ถัดไป',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _handleNextStep() {
    if (_currentStep == 1) {
      if (actualTravelerCount == 0) {
        _showSnackBar(
          'กรุณาเลือกจำนวนผู้เดินทางอย่างน้อย 1 รายการ',
          Colors.red,
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      final expectedCount = actualTravelerCount;
      final requiredPassengers = expectedCount > 1 ? expectedCount - 1 : 0;

      if (passengerForms.length != requiredPassengers) {
        _showSnackBar(
          'กรุณาบันทึกผู้ร่วมเดินทางให้ครบ $requiredPassengers คน ก่อนเข้าสู่ขั้นตอนถัดไป',
          Colors.red,
        );
        return;
      }

      if (contactNameCtl.text.trim().isEmpty ||
          contactPhoneCtl.text.trim().isEmpty ||
          contactEmailCtl.text.trim().isEmpty) {
        _showSnackBar('กรุณากรอกข้อมูลผู้ติดต่อให้ครบถ้วน', Colors.red);
        return;
      }

      setState(() => _currentStep++);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, String title) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isActive ? Colors.green : Colors.grey.shade300,
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? Colors.green : Colors.grey.shade300,
    );
  }
}
