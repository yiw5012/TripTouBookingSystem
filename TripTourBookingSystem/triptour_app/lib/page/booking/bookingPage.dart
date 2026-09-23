import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';
import 'package:triptour_app/page/booking/widgets/step1_tour_details.dart';
import 'package:triptour_app/page/booking/widgets/step2_passenger.dart';
import 'package:triptour_app/page/booking/widgets/step3_payment.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:triptour_app/serviceBookingApi.dart';

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
  Map<String, dynamic> memberId = {};

  // Controllers สำหรับข้อมูลผู้ติดต่อ
  final contactNameCtl = TextEditingController();
  final contactPhoneCtl = TextEditingController();
  final contactEmailCtl = TextEditingController();

  final List<int> passengerMultipliers = [2, 3, 1, 1];
  final List<String> selectedGender = ['Male', 'Female', 'Other'];

  List<int> passengerCounts = [0, 0, 0, 0];
  final List<String> passengerTypes = [
    'ผู้ใหญ่ 2 พัก 1 ห้อง',
    'ผู้ใหญ่ 3 พัก 1 ห้อง',
    'ผู้ใหญ่ 1 พัก 1 ห้อง',
    'เด็กต่ำกว่า 11 ปี 0 ห้อง',
  ];

  Map<String, dynamic> get selectedRound =>
      rounds.isNotEmpty ? Map<String, dynamic>.from(rounds.first) : {};

  List<int> get prices => [
    _parsePrice(selectedRound['price_double']),
    _parsePrice(selectedRound['price_triple']),
    _parsePrice(selectedRound['price_single']),
    _parsePrice(selectedRound['price_child'] ?? 1),
  ];

  int _parsePrice(dynamic value) {
    final rawValue = value ?? selectedRound['price'] ?? tourData['price'];
    final parsed = num.tryParse(rawValue?.toString() ?? '');
    return parsed?.toInt() ?? 0;
  }

  int get totalPrice {
    var total = 0;
    for (var i = 0; i < passengerCounts.length; i++) {
      total += passengerCounts[i] * prices[i];
    }
    return total;
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
        memberId = detail;

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
    final passengers = passengerForms.map((form) => form.toJson()).toList();
    final route =
        '${selectedRound['departure'] ?? 'Unknown'} → ${selectedRound['destination'] ?? 'Unknown'}';
    final tripDates =
        '${selectedRound['start_date'] ?? 'N/A'} ถึง ${selectedRound['end_date'] ?? 'N/A'}';
    final travelerCount = List<int>.generate(
      passengerCounts.length,
      (i) => passengerCounts[i] * passengerMultipliers[i],
    ).fold<int>(0, (sum, value) => sum + value);

    final roomSummary = passengerCounts
        .asMap()
        .entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${passengerTypes[entry.key]}: ${entry.value} ห้อง')
        .join(', ');

    return {
      'passengers': passengers,
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
              // 1. Step Progress Bar ด้านบน
              const SizedBox(height: 30),

              _buildStepIndicator(),
              const SizedBox(height: 20),

              // 2. เนื้อหาตามขั้นตอนที่เลือก
              _buildStepContent(),

              const SizedBox(height: 20),

              // 3. ปุ่มควบคุมล่างสุด (แสดงเฉพาะ Step 1 และ Step 2)
              if (_currentStep < 3) _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // แถบแสดงสถานะขั้นตอน (Step Indicator)
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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

  // แสดงเนื้อหาของแต่ละ Step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Step1TourDetails(
          tourData: tourData,
          selectedRound: selectedRound,
          passengerTypes: passengerTypes,
          passengerCounts: passengerCounts,
          prices: prices,
          totalPrice: totalPrice,
          onCountChanged: (index, delta) {
            setState(() {
              final newCount = passengerCounts[index] + delta;
              if (newCount >= 0) passengerCounts[index] = newCount;
            });
          },
        );
      case 2:
        final expectedCount = List<int>.generate(
          passengerCounts.length,
          (i) => passengerCounts[i] * passengerMultipliers[i],
        ).fold<int>(0, (s, v) => s + v);

        final roomSummary = passengerCounts
            .asMap()
            .entries
            .where((entry) => entry.value > 0)
            .map((entry) => '${passengerTypes[entry.key]}: ${entry.value} ห้อง')
            .join(', ');

        final travelerSummary = List<int>.generate(
          passengerCounts.length,
          (i) => passengerCounts[i] * passengerMultipliers[i],
        ).fold<int>(0, (sum, v) => sum + v).toString();

        return Step2PassengerForm(
          imageUrl: tourData['image_url'], // รูปภาพทัวร์
          tourTitle: tourData['tour_name'], // ชื่อทัวร์
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
          travelerSummary: '$travelerSummary คน',
          contactNameCtl: contactNameCtl,
          contactPhoneCtl: contactPhoneCtl,
          contactEmailCtl: contactEmailCtl,
        );
      case 3:
        final currentMemberId = memberId['member_id']?.toString() ?? '';
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
          onBookingStatusChanged: (status) {
            // Callback เมื่อสถานะการชำระเงินอัปเดต
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ปุ่มกดถัดไป / ย้อนกลับ สำหรับ Step 1 และ Step 2
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
      final totalSelected = List<int>.generate(
        passengerCounts.length,
        (i) => passengerCounts[i] * passengerMultipliers[i],
      ).fold<int>(0, (sum, v) => sum + v);

      if (totalSelected == 0) {
        _showSnackBar(
          'กรุณาเลือกจำนวนผู้เดินทางอย่างน้อย 1 รายการ',
          Colors.red,
        );
        return;
      }

      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      final expectedCount = List<int>.generate(
        passengerCounts.length,
        (i) => passengerCounts[i] * passengerMultipliers[i],
      ).fold<int>(0, (sum, v) => sum + v);

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

      // ผ่านเงื่อนไข ไป Step 3
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
}
