import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/widgets/addpassenger.dart';
import 'package:triptour_app/page/booking/widgets/passengerform.dart';

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
  });

  @override
  State<Step2PassengerForm> createState() => _Step2PassengerFormState();
}

class _Step2PassengerFormState extends State<Step2PassengerForm> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (widget.contactNameCtl.text.isEmpty) {
      widget.contactNameCtl.text = user?.displayName ?? '';
    }
    if (widget.contactPhoneCtl.text.isEmpty) {
      widget.contactPhoneCtl.text = user?.phoneNumber ?? '';
    }
    if (widget.contactEmailCtl.text.isEmpty) {
      widget.contactEmailCtl.text = user?.email ?? '';
    }
  }

  Future<void> _openAddPassenger({PassengerFormControllers? existing}) async {
    if (existing == null &&
        widget.passengerForms.length >= widget.expectedCount) {
      return;
    }

    final idx = existing?.passengerIndex ?? widget.passengerForms.length + 1;
    final result = await Navigator.of(context).push<PassengerFormControllers>(
      MaterialPageRoute(
        builder: (_) => AddPassengerPage(
          index: idx,
          genderOptions: widget.genderOptions,
          existingPassenger: existing,
        ),
      ),
    );
    if (result != null) {
      if (existing != null) {
        final replaceIndex = widget.passengerForms.indexWhere(
          (form) => form.passengerIndex == existing.passengerIndex,
        );
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
    final expected = widget.expectedCount;

    if (expected == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'กรุณาเลือกจำนวนผู้เดินทางอย่างน้อย 1 คน ในขั้นตอนที่ 1',
            style: TextStyle(color: Colors.red, fontSize: 15),
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '[1] รายละเอียดการจอง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _infoRow('Route', widget.route),
                _infoRow('Dates', widget.tripDates),
                _infoRow('Airline', widget.airline),
                _infoRow('ห้อง', widget.roomSummary),
                _infoRow('จำนวนคน', widget.travelerSummary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '[2] กรอกข้อมูลผู้ร่วมเดินทาง ($current/$expected)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: current < expected
                            ? _openAddPassenger
                            : null,
                        icon: const Icon(Icons.person_add),
                        label: const Text(''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (current == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'ยังไม่มีผู้เดินทางที่บันทึกไว้ กด “เพิ่มผู้เดินทาง” เพื่อกรอกข้อมูล',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(height: 8),
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
                      : 'ยังไม่กรอกเลขบัตร';

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ผู้เดินทางคนที่ ${form.passengerIndex} (${form.typeName})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _openAddPassenger(existing: form),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('แก้ไข'),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text('ชื่อ: $summaryName'),
                        const SizedBox(height: 4),

                        Text('โทร: $summaryPhone'),
                        const SizedBox(height: 4),
                        Text('เลขบัตร/Passport: $summaryId'),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ],
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
                  'ข้อมูลผู้ติดต่อ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.contactNameCtl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.contactPhoneCtl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.contactEmailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
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
