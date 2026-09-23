import 'package:flutter/material.dart';

class TourHeader extends StatelessWidget {
  final Map<String, dynamic> tour;
  final List<dynamic> images;

  const TourHeader({super.key, required this.tour, required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(children: [buildTourImage(), buildTourSummary()]);
  }

  // ==========================================================
  // IMAGE
  // ==========================================================

  Widget buildTourImage() {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 230,
        color: const Color(0xFFE0E0E0),
        child: const Center(
          child: Icon(Icons.image, size: 70, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 230,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          final String imageUrl = images[index]['image']?.toString() ?? '';

          if (imageUrl.isEmpty) {
            return Container(
              color: const Color(0xFFE0E0E0),
              child: const Center(
                child: Icon(Icons.image, size: 70, color: Colors.grey),
              ),
            );
          }

          return Image.network(
            imageUrl,
            width: double.infinity,
            height: 230,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFE0E0E0),
                child: const Center(
                  child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // SUMMARY
  // ==========================================================

  Widget buildTourSummary() {
    final String tourName = tour['tour_name']?.toString() ?? 'ไม่มีชื่อทัวร์';

    final String tourId = tour['tour_id']?.toString() ?? '-';

    final String country = tour['country_name_th']?.toString() ?? '-';

    final String type = tour['type']?.toString() ?? '-';

    final String duration = tour['duration_day']?.toString() ?? '-';

    final String price = formatPrice(tour['price']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // ชื่อ + รหัส
          // ------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Text(
                  tourName,

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                'รหัสทัวร์: $tourId',

                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // ประเทศ + ประเภท
          // ------------------------------------------------------
          Row(
            children: [
              const Icon(Icons.public, size: 19, color: Colors.green),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  '$country • $type',

                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // REVIEW
          // ------------------------------------------------------
          Row(
            children: [
              const Icon(Icons.star, size: 21, color: Colors.amber),

              const SizedBox(width: 5),

              Text(
                'ยังไม่มีข้อมูลคะแนน',

                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

              const SizedBox(width: 8),

              Text(
                '(ยังไม่มีข้อมูลรีวิว)',

                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // ระยะเวลา
          // ------------------------------------------------------
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.orange),

              const SizedBox(width: 6),

              Text(
                'ระยะเวลา: $duration วัน',

                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // ราคา
          // ------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              const Text(
                'ราคาเริ่มต้น',

                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(width: 8),

              Text(
                '$price บาท',

                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
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
}
