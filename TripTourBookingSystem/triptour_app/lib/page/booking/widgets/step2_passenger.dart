import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/widgets/addpassenger.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';
import 'package:triptour_app/page/booking/widgets/tourCardWiget.dart';

class Step2PassengerForm extends StatefulWidget {
  final List<PassengerFormControllers> passengerForms;
  final List<String> genderOptions;
  final Function(PassengerFormControllers form) onSelectDate;
  final int expectedCount; // จำนวนผู้เดินทางรวมทั้งหมด
  final String route;
  final String tripDates;
  final String airline;
  final String roomSummary;
  final String travelerSummary;
  final TextEditingController contactNameCtl;
  final TextEditingController contactPhoneCtl;
  final TextEditingController contactEmailCtl;
  final String? imageUrl; // เพิ่มรองรับรูปภาพทัวร์
  final String? tourTitle; // เพิ่มรองรับชื่อทัวร์

  const Step2PassengerForm({
    super.key,
    required this.passengerForms,
    required this.genderOptions,
    required this.onSelectDate,
    required this.expectedCount,
    required this.route,
    required this.tripDates,
    required this.airline,
    required this.roomSummary,
    required this.travelerSummary,
    required this.contactNameCtl,
    required this.contactPhoneCtl,
    required this.contactEmailCtl,
    this.imageUrl,
    this.tourTitle,
  });

  @override
  State<Step2PassengerForm> createState() => _Step2PassengerFormState();
}

class _Step2PassengerFormState extends State<Step2PassengerForm> {
  // คำนวณจำนวน Passenger ที่ต้องกรอกเพิ่ม (คนทั้งหมด - 1 ผู้จอง)
  int get requiredPassengerCount =>
      widget.expectedCount > 1 ? widget.expectedCount - 1 : 0;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  @override
  void didUpdateWidget(covariant Step2PassengerForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ถ้ามีการเปลี่ยนจำนวนผู้เดินทางจาก Step 1
    if (oldWidget.expectedCount != widget.expectedCount) {
      _adjustPassengerForms();
    }
  }

  void _initUserData() {
    _adjustPassengerForms();
  }

  void _adjustPassengerForms() {
    final requiredCount = requiredPassengerCount;
    // ถ้าเดินทาง 1 คน หรือมีฟอร์มเกินจำนวนที่ต้องกรอก ให้เคลียร์/ตัดส่วนเกินออก
    if (requiredCount == 0) {
      widget.passengerForms.clear();
    } else if (widget.passengerForms.length > requiredCount) {
      widget.passengerForms.removeRange(
        requiredCount,
        widget.passengerForms.length,
      );
    }
  }

  Future<void> _openAddPassenger({
    PassengerFormControllers? existing,
    int? customIndex,
  }) async {
    final requiredCount = requiredPassengerCount;

    if (existing == null && widget.passengerForms.length >= requiredCount) {
      return;
    }

    // ใช้ customIndex ถ้ามี หรือใช้ลำดับตามรายการถัดไป
    final idx =
        customIndex ??
        (existing?.passengerIndex ?? widget.passengerForms.length + 1);

    final result = await Navigator.of(context).push<PassengerFormControllers>(
      MaterialPageRoute(
        builder: (_) => AddPassengerPage(
          index: idx,
          genderOptions: widget.genderOptions,
          existingPassenger: existing,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      if (existing != null) {
        final replaceIndex = widget.passengerForms.indexOf(existing);
        if (replaceIndex >= 0) {
          widget.passengerForms[replaceIndex] = result;
        }
      } else {
        widget.passengerForms.add(result);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.passengerForms.length;
    final requiredCount = requiredPassengerCount;

    if (widget.expectedCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            'กรุณาเลือกจำนวนผู้เดินทางอย่างน้อย 1 คน ในขั้นตอนที่ 1',
            style: TextStyle(color: Colors.red, fontSize: 15),
          ),
        ),
      );
    }

    return Column(
      children: [
        // [1] รายละเอียดการจอง
        TourBookingCardWidget(
          imageUrl: widget.imageUrl, // ส่ง URL รูปภาพ
          tourTitle: widget.tourTitle.toString(),
          route: widget.route,
          tripDates: widget.tripDates,
          airline: widget.airline,
          roomSummary: widget.roomSummary,
          travelerSummary: widget.travelerSummary,
        ),
        const SizedBox(height: 16),

        // [2] ส่วนผู้เดินทาง
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // เดินทาง 1 คน: ผู้เดินทางคือผู้จองคนเดียว ไม่ต้องกรอก Passenger
                if (widget.expectedCount == 1) ...[
                  const Text(
                    '[2] ข้อมูลผู้เดินทาง',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'เดินทาง 1 คน: ระบบใช้ข้อมูลจากบัญชีผู้จองโดยตรง ไม่ต้องกรอกข้อมูลผู้ร่วมเดินทางเพิ่มเติม',
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '[2] ข้อมูลผู้ร่วมเดินทาง ($current/$requiredCount คน)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (current < requiredCount)
                        ElevatedButton.icon(
                          onPressed: () => _openAddPassenger(),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('เพิ่ม'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'เดินทางทั้งหมด ${widget.expectedCount} คน (ผู้จอง 1 คน + ผู้ร่วมเดินทาง $requiredCount คน)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),

                  if (current == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'ยังไม่ได้เพิ่มผู้ร่วมเดินทาง กด “เพิ่ม” เพื่อกรอกข้อมูลผู้ร่วมเดินทางอีก $requiredCount คน',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.passengerForms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final form = widget.passengerForms[index];
                      final summaryName = form.nameCtl.text.trim().isNotEmpty
                          ? form.nameCtl.text.trim()
                          : 'ยังไม่กรอกชื่อ';
                      final summaryPhone = form.phoneCtl.text.trim().isNotEmpty
                          ? form.phoneCtl.text.trim()
                          : 'ยังไม่กรอกเบอร์';
                      final summaryId = form.numberIdCtl.text.trim().isNotEmpty
                          ? form.numberIdCtl.text.trim()
                          : 'ยังไม่กรอกเลขบัตร/Passport';

                      return Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'ผู้ร่วมเดินทางคนที่ ${index + 1} (${form.typeName})',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),

                                TextButton.icon(
                                  onPressed: () =>
                                      _openAddPassenger(existing: form),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('แก้ไข'),
                                ),
                              ],
                            ),
                            const Divider(height: 8),
                            Text('ชื่อ: $summaryName'),
                            const SizedBox(height: 4),
                            Text('โทร: $summaryPhone'),
                            const SizedBox(height: 4),
                            Text('เลขบัตร/Passport: $summaryId'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // [3] ข้อมูลผู้ติดต่อ
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลผู้ติดต่อ (ผู้จอง)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.contactNameCtl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล ผู้ติดต่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.contactPhoneCtl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์ ผู้ติดต่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.contactEmailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล ผู้ติดต่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
