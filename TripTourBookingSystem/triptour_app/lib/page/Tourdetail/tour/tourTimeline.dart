import 'package:flutter/material.dart';

class TourTimeline extends StatelessWidget {
  final List<dynamic> details;

  final int selectedDay;

  final ValueChanged<int> onDaySelected;

  const TourTimeline({
    super.key,
    required this.details,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),

        child: Center(
          child: Text(
            'ยังไม่มีรายละเอียดโปรแกรมทัวร์',

            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final List<int> days = details
        .map((item) => int.tryParse(item['day_number'].toString()))
        .whereType<int>()
        .toSet()
        .toList();

    days.sort();

    const int itemsPerRow = 5;

    final List<List<int>> rows = [];

    for (int i = 0; i < days.length; i += itemsPerRow) {
      final int end = (i + itemsPerRow > days.length)
          ? days.length
          : i + itemsPerRow;

      List<int> row = days.sublist(i, end);

      // ทำ Timeline เป็นรูป S
      if (rows.length.isOdd) {
        row = row.reversed.toList();
      }

      rows.add(row);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),

      child: Column(
        children: [
          for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            buildTimelineRow(rows[rowIndex]),

            if (rowIndex < rows.length - 1) buildVerticalTimelineLine(),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // ROW
  // ==========================================================

  Widget buildTimelineRow(List<int> rowDays) {
    return SizedBox(
      height: 60,

      child: Row(
        children: [
          for (int i = 0; i < rowDays.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  onDaySelected(rowDays[i]);
                },

                child: Column(
                  children: [
                    Text(
                      'วันที่ '
                      '${rowDays[i]}',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selectedDay == rowDays[i]
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedDay == rowDays[i]
                            ? Colors.green
                            : Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      width: 34,
                      height: 34,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: selectedDay == rowDays[i]
                            ? Colors.greenAccent
                            : Colors.grey.shade300,
                      ),

                      child: selectedDay == rowDays[i]
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            if (i < rowDays.length - 1)
              Expanded(
                child: Container(height: 2, color: Colors.grey.shade300),
              ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // VERTICAL LINE
  // ==========================================================

  Widget buildVerticalTimelineLine() {
    return SizedBox(
      height: 24,

      child: Align(
        alignment: Alignment.centerRight,

        child: Container(width: 2, height: 24, color: Colors.grey.shade300),
      ),
    );
  }
}
