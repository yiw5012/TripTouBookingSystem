import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';
import 'package:triptour_app/page/booking/widgets/step1_tour_details.dart';
import 'package:triptour_app/page/booking/widgets/step2_passenger.dart';
import 'package:triptour_app/page/booking/widgets/step3_payment.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:triptour_app/serviceBookingApi.dart';

////////////////////////////////////////////////////////////////////////////////
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
  final GlobalKey? _step3Key = GlobalKey();
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

  bool _isBooking = false;

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

  void updatePassengerForms() {
    List<PassengerFormControllers> newForms = [];
    int passengerIndex = 1;

    for (int i = 0; i < passengerCounts.length; i++) {
      int count = passengerCounts[i];
      int totalPeople = count * passengerMultipliers[i];

      for (int j = 0; j < totalPeople; j++) {
        if (passengerForms.length >= passengerIndex) {
          newForms.add(passengerForms[passengerIndex - 1]);
        } else {
          newForms.add(
            PassengerFormControllers(
              passengerIndex: passengerIndex,
              typeName: passengerTypes[i],
            ),
          );
        }
        passengerIndex++;
      }
    }
    passengerForms = newForms;
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

  set isBooking(bool status) {
    setState(() {
      _isBooking = status;
    });
  }

  Future<Map<String, dynamic>> _submitPassengerBooking() async {
    return ServiceBookingApi.submitPassengers(bookingPayload);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tourName = tourData['tour_name'] ?? 'Tour ${widget.tourId}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking $tourName'),
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStepCircle(1, '[1]'),
                  _buildStepLine(1),
                  _buildStepCircle(2, '[2]'),
                  _buildStepLine(2),
                  _buildStepCircle(3, '[3]'),
                ],
              ),
              const SizedBox(height: 12),

              _buildStepContent(),

              const SizedBox(height: 20),

              Row(
                children: [
                  if (_currentStep >= 2)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => {
                          if (_currentStep == 3)
                            {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const Homepage(),
                                ),
                                (route) => false,
                              ),
                              //ยกเลิก
                            }
                          else
                            {setState(() => _currentStep--)},
                        },
                        child: Text(_currentStep == 3 ? 'ยกเลิก' : 'ย้อนกลับ'),
                      ),
                    ),

                  if (_currentStep > 1) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        if (_currentStep == 1) {
                          final totalSelected = List<int>.generate(
                            passengerCounts.length,
                            (i) => passengerCounts[i] * passengerMultipliers[i],
                          ).fold<int>(0, (sum, v) => sum + v);

                          if (totalSelected == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'กรุณาเลือกจำนวนผู้เดินทางอย่างน้อย 1 รายการ',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _currentStep++;
                          });
                        } else if (_currentStep == 2) {
                          final expectedCount = List<int>.generate(
                            passengerCounts.length,
                            (i) => passengerCounts[i] * passengerMultipliers[i],
                          ).fold<int>(0, (sum, v) => sum + v);

                          if (passengerForms.length != expectedCount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'กรุณาบันทึกผู้เดินทางครบ $expectedCount คน ก่อนเข้าสู่ขั้นตอนถัดไป',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final currentMemberId =
                              memberId['member_id']?.toString() ?? '';
                          if (currentMemberId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('กรุณาเข้าสู่ระบบก่อนทำการจอง'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => _currentStep++);
                        } else if (_currentStep == 3) {
                          if (_isBooking == true) {
                            final res = await _submitPassengerBooking();
                            print(res.toString());

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const Homepage(),
                              ),
                              (route) => false,
                            );
                          } else {
                            try {
                              final state = _step3Key?.currentState;
                              if (state != null) {
                                (state as dynamic).startBooking();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ไม่พบหน้าจอการจ่ายเงิน'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เริ่มการจองล้มเหลว: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Text(_currentStep == 3 ? 'Confirm' : 'ถัดไป'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            setState(() {
              _isBooking = status;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return CircleAvatar(
      radius: 18,
      backgroundColor: isActive ? Colors.green : Colors.grey.shade300,
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.green : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
