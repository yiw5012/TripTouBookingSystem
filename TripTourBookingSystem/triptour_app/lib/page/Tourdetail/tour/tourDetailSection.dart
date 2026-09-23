import 'package:flutter/material.dart';
import 'tourTimeline.dart';

class TourDetailSection extends StatelessWidget {
  final List<dynamic> details;

  final int selectedDay;

  final ValueChanged<int> onDaySelected;

  const TourDetailSection({
    super.key,
    required this.details,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 5),

            child: Text(
              'รายละเอียด / มื้ออาหาร',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          TourTimeline(
            details: details,

            selectedDay: selectedDay,

            onDaySelected: onDaySelected,
          ),

          const Divider(height: 1),

          buildSelectedDayDetail(),
        ],
      ),
    );
  }

  // ==========================================================
  // GET SELECTED DAY
  // ==========================================================

  Map<String, dynamic>? getSelectedDayDetail() {
    for (final item in details) {
      final int? day = int.tryParse(item['day_number'].toString());

      if (day == selectedDay) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
  }

  // ==========================================================
  // DAY DETAIL
  // ==========================================================

  Widget buildSelectedDayDetail() {
    final Map<String, dynamic>? dayData = getSelectedDayDetail();

    if (dayData == null) {
      return const Padding(
        padding: EdgeInsets.all(20),

        child: Text('ไม่พบรายละเอียดของวันที่เลือก'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // วันที่
          // ======================================================
          Text(
            'วันที่ $selectedDay',

            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // LOCATION
          // ======================================================
          if (hasText(dayData['location']))
            buildDetailInfo(
              icon: Icons.location_on,
              title: 'สถานที่ท่องเที่ยว',
              value: dayData['location'].toString(),
            ),

          // ======================================================
          // DAY DETAIL
          // ======================================================
          if (hasText(dayData['day_detail']))
            buildDetailInfo(
              icon: Icons.description,
              title: 'รายละเอียดกิจกรรม',
              value: dayData['day_detail'].toString(),
            ),

          // ======================================================
          // TRAVEL
          // ======================================================
          if (hasText(dayData['travel']))
            buildDetailInfo(
              icon: Icons.directions_bus,
              title: 'การเดินทาง',
              value: dayData['travel'].toString(),
            ),

          // ======================================================
          // HOTEL
          // ======================================================
          if (hasText(dayData['hotel']))
            buildDetailInfo(
              icon: Icons.hotel,
              title: 'ที่พัก',
              value: dayData['hotel'].toString(),
            ),

          // ======================================================
          // MEAL
          // ======================================================
          if (hasText(dayData['meal_detail']))
            buildMealInfo(dayData['meal_detail'].toString()),

          // ======================================================
          // RESTAURANT
          // ======================================================
          if (hasText(dayData['restaurant_detail']))
            buildDetailInfo(
              icon: Icons.restaurant,
              title: 'ร้านอาหาร',
              value: dayData['restaurant_detail'].toString(),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAIL INFO
  // ==========================================================

  Widget buildDetailInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 36,
            height: 36,

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),

            child: Icon(icon, size: 20, color: Colors.orange),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MEAL
  // ==========================================================

  Widget buildMealInfo(String mealText) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu, size: 21, color: Colors.orange),

              SizedBox(width: 8),

              Text(
                'มื้ออาหาร',

                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            mealText,

            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HAS TEXT
  // ==========================================================

  bool hasText(dynamic value) {
    if (value == null) {
      return false;
    }

    return value.toString().trim().isNotEmpty;
  }
}
