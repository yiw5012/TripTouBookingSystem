import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';

class TourBookingSection extends StatelessWidget {
  final List<dynamic> rounds;

  const TourBookingSection({super.key, required this.rounds});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'รอบทัวร์',

            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          if (rounds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),

              child: Center(
                child: Text(
                  'ยังไม่มีรอบทัวร์',

                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            for (final round in rounds) buildRoundCard(round),
        ],
      ),
    );
  }

  // ==========================================================
  // ROUND CARD
  // ==========================================================

  Widget buildRoundCard(dynamic round) {
    final String status = round['status']?.toString() ?? '';

    final bool isOpen = status == 'open';

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade300),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),

            blurRadius: 5,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // รอบ
          // ======================================================
          Text(
            'รอบทัวร์ '
            '${round['round_id'] ?? '-'}',

            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // เส้นทาง
          // ======================================================
          Row(
            children: [
              const Icon(Icons.flight_takeoff, size: 20, color: Colors.blue),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  '${round['departure'] ?? '-'}'
                  ' → '
                  '${round['destination'] ?? '-'}',

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ======================================================
          // วันที่
          // ======================================================
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: Colors.orange),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  '${formatDateText(round['start_date'])}'
                  ' - '
                  '${formatDateText(round['end_date'])}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ======================================================
          // เวลา
          // ======================================================
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.blue),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'เวลา: '
                  '${round['flight_time'] ?? '-'}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ======================================================
          // สายการบิน
          // ======================================================
          Row(
            children: [
              const Icon(Icons.flight, size: 18, color: Colors.blue),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'สายการบิน: '
                  '${round['airline'] ?? '-'}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ======================================================
          // Flight
          // ======================================================
          Row(
            children: [
              const Icon(
                Icons.confirmation_number,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Flight: '
                  '${round['flight'] ?? '-'}',
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // ======================================================
          // ราคา
          // ======================================================
          const Text(
            'ราคา',

            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          buildPriceRow('Single', round['price_single']),

          const SizedBox(height: 5),

          buildPriceRow('Double', round['price_double']),

          const SizedBox(height: 5),

          buildPriceRow('Triple', round['price_triple']),

          const SizedBox(height: 14),

          // ======================================================
          // สถานะ + จอง
          // ======================================================
          Row(
            children: [
              Expanded(
                child: Text(
                  isOpen ? 'สถานะ: เปิดจอง' : 'สถานะ: ปิดจอง',

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: isOpen
                    ? () {
                        Get.offAll(
                          () => BookingTourPage(
                            roundId: round['round_id'].toString(),

                            tourId: round['tour_id'].toString(),
                          ),
                        );
                      }
                    : null,

                child: const Text('จอง'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PRICE
  // ==========================================================

  Widget buildPriceRow(String type, dynamic price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text('$type:', style: const TextStyle(fontSize: 14)),

        Text(
          '${formatPrice(price)} บาท',

          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ==========================================================
  // FORMAT PRICE
  // ==========================================================

  String formatPrice(dynamic value) {
    if (value == null) {
      return '-';
    }

    final num? number = num.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String formatDateText(dynamic value) {
    if (value == null) {
      return '-';
    }

    final String text = value.toString();

    if (text.isEmpty) {
      return '-';
    }

    final parts = text.split('-');

    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return text;
  }
}
