import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/widgets/addpassenger.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';
import 'package:triptour_app/page/booking/widgets/tourCardWiget.dart';

class Step2PassengerForm extends StatefulWidget {
  final List<PassengerFormControllers> passengerForms;
  final List<String> genderOptions;
  final Function(PassengerFormControllers form) onSelectDate;
  final int expectedCount;
  final String route;
  final String tripDates;
  final String airline;
  final String roomSummary;
  final String travelerSummary;
  final TextEditingController contactNameCtl;
  final TextEditingController contactPhoneCtl;
  final TextEditingController contactEmailCtl;
  final String? imageUrl;
  final String? tourTitle;

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
  int get requiredPassengerCount =>
      widget.expectedCount > 1 ? widget.expectedCount - 1 : 0;

  @override
  void initState() {
    super.initState();
    _adjustPassengerForms();
  }

  @override
  void didUpdateWidget(covariant Step2PassengerForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expectedCount != widget.expectedCount) {
      _adjustPassengerForms();
    }
  }

  void _adjustPassengerForms() {
    final requiredCount = requiredPassengerCount;
    if (requiredCount == 0) {
      for (final form in widget.passengerForms) {
        form.dispose();
      }
      widget.passengerForms.clear();
      return;
    }

    if (widget.passengerForms.length > requiredCount) {
      final removedForms = widget.passengerForms.sublist(requiredCount);
      for (final form in removedForms) {
        form.dispose();
      }
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

    final index =
        customIndex ??
        (existing?.passengerIndex ?? widget.passengerForms.length + 1);

    final result = await Navigator.of(context).push<PassengerFormControllers>(
      MaterialPageRoute(
        builder: (_) => AddPassengerPage(
          index: index,
          genderOptions: widget.genderOptions,
          existingPassenger: existing,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final current = widget.passengerForms.length;
    final requiredCount = requiredPassengerCount;
    final progress = requiredCount == 0 ? 1.0 : current / requiredCount;

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
        TourBookingCardWidget(
          imageUrl: widget.imageUrl,
          tourTitle: widget.tourTitle.toString(),
          route: widget.route,
          tripDates: widget.tripDates,
          airline: widget.airline,
          roomSummary: widget.roomSummary,
          travelerSummary: widget.travelerSummary,
        ),
        const SizedBox(height: 16),
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
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requiredCount == 0
                          ? 'ผู้จองเดินทางเอง ไม่ต้องเพิ่มผู้ร่วมเดินทาง'
                          : 'เพิ่มข้อมูลผู้ร่วมเดินทางให้ครบก่อนเข้าสู่ขั้นตอนชำระเงิน',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                requiredCount == 0
                    ? 'ระบบจะใช้ข้อมูลผู้ติดต่อด้านล่างเป็นข้อมูลผู้เดินทางหลักโดยอัตโนมัติ'
                    : 'บันทึกแล้ว $current จาก $requiredCount คน',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.expectedCount == 1) ...[
                  const Text(
                    '[2] ข้อมูลผู้เดินทาง',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'เดินทาง 1 คน: ระบบจะใช้ข้อมูลจากผู้ติดต่อ/ผู้จองโดยอัตโนมัติ ไม่ต้องกรอกข้อมูลผู้ร่วมเดินทางเพิ่มเติม',
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
                const SizedBox(height: 4),
                const Text(
                  'ข้อมูลส่วนนี้จะถูกใช้สำหรับติดต่อกลับและยืนยันการจอง',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.contactNameCtl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล ผู้ติดต่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outline),
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
                    prefixIcon: Icon(Icons.phone_outlined),
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
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
