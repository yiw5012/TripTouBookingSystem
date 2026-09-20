import 'package:flutter/material.dart';
import 'package:triptour_app/serverApi.dart';

class DetailTour extends StatefulWidget {
  final int tourId;

  const DetailTour({super.key, required this.tourId});

  @override
  State<DetailTour> createState() => _DetailTourState();
}

class _DetailTourState extends State<DetailTour>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // ==========================================================
  // DATA
  // ==========================================================

  Map<String, dynamic>? tour;

  List<dynamic> images = [];
  List<dynamic> rounds = [];
  List<dynamic> details = [];

  bool isLoading = true;
  String? errorMessage;

  int selectedDay = 1;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);

    loadTourDetail();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD TOUR DETAIL
  // ==========================================================

  Future<void> loadTourDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await Serverapi.getTourDetail(widget.tourId);

      if (!mounted) return;

      if (result['statusCode'] == 200 &&
          result['body'] != null &&
          result['body']['success'] == true) {
        final data = result['body']['data'];

        final List<dynamic> loadedDetails = data['details'] ?? [];

        int firstDay = 1;

        if (loadedDetails.isNotEmpty) {
          firstDay =
              int.tryParse(loadedDetails.first['day_number'].toString()) ?? 1;
        }

        setState(() {
          tour = data['tour'];
          images = data['images'] ?? [];
          rounds = data['rounds'] ?? [];
          details = loadedDetails;

          selectedDay = firstDay;

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['body']?['message'] ?? 'ไม่พบข้อมูลทัวร์';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });

      debugPrint('Load tour detail error: $e');
    }
  }

  // ==========================================================
  // GET SELECTED DAY
  // ==========================================================

  Map<String, dynamic>? getSelectedDayDetail() {
    for (final item in details) {
      final int? dayNumber = int.tryParse(item['day_number'].toString());

      if (dayNumber == selectedDay) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
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
  // TOUR SUMMARY
  // ==========================================================

  Widget buildTourSummary() {
    if (tour == null) {
      return const SizedBox();
    }

    final String tourName = tour!['tour_name']?.toString() ?? 'ไม่มีชื่อทัวร์';

    final String tourId = tour!['tour_id']?.toString() ?? '-';

    final String country = tour!['country_name_th']?.toString() ?? '-';

    final String type = tour!['type']?.toString() ?? '-';

    final String duration = tour!['duration_day']?.toString() ?? '-';

    final String price = formatPrice(tour!['price']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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

              const SizedBox(width: 12),

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
  // TAB 1 : BOOKING
  // ==========================================================

  Widget buildBookingTab() {
    if (rounds.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีรอบทัวร์',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rounds.length,
      itemBuilder: (context, index) {
        final round = rounds[index];

        return buildRoundCard(round);
      },
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
          // ------------------------------------------------------
          // รอบที่
          // ------------------------------------------------------
          Text(
            'รอบทัวร์ ${round['round_id'] ?? '-'}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // เส้นทาง
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // วันที่
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // เวลา
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // สายการบิน
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // FLIGHT
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // ราคา
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // สถานะ + ปุ่ม
          // ------------------------------------------------------
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
                        // ยังไม่ทำงาน
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
  // TAB 2 : DETAIL / MEAL
  // ==========================================================

  Widget buildDetailTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          buildDayTimeline(),

          const Divider(height: 1),

          // รายละเอียดวันที่เลือก
          buildSelectedDayDetail(),
        ],
      ),
    );
  }

  // ==========================================================
  // TIMELINE
  // ==========================================================

  Widget buildDayTimeline() {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(children: [buildTimelineRows(days)]),
    );
  }

  // ==========================================================
  // TIMELINE ROWS
  // ==========================================================

  Widget buildTimelineRows(List<int> days) {
    const int itemsPerRow = 5;

    final List<List<int>> rows = [];

    for (int i = 0; i < days.length; i += itemsPerRow) {
      final int end = (i + itemsPerRow > days.length)
          ? days.length
          : i + itemsPerRow;

      List<int> row = days.sublist(i, end);

      // แถวที่ 2, 4, 6...
      // กลับลำดับเพื่อให้ Timeline ต่อเป็นรูปตัว S
      if (rows.length.isOdd) {
        row = row.reversed.toList();
      }

      rows.add(row);
    }

    return Column(
      children: [
        for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          buildTimelineRow(rows[rowIndex]),

          if (rowIndex < rows.length - 1) buildVerticalTimelineLine(),
        ],
      ],
    );
  }

  // ==========================================================
  // ONE TIMELINE ROW
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
                  setState(() {
                    selectedDay = rowDays[i];
                  });
                },
                child: Column(
                  children: [
                    Text(
                      'วันที่ ${rowDays[i]}',
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
  // VERTICAL TIMELINE LINE
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

  // ==========================================================
  // SELECTED DAY DETAIL
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
          // ------------------------------------------------------
          // วันที่
          // ------------------------------------------------------
          Text(
            'วันที่ $selectedDay',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // สถานที่
          // ------------------------------------------------------
          if (hasText(dayData['location']))
            buildDetailInfo(
              icon: Icons.location_on,
              title: 'สถานที่ท่องเที่ยว',
              value: dayData['location'].toString(),
            ),

          // ------------------------------------------------------
          // รายละเอียดกิจกรรม
          // ------------------------------------------------------
          if (hasText(dayData['day_detail']))
            buildDetailInfo(
              icon: Icons.description,
              title: 'รายละเอียดกิจกรรม',
              value: dayData['day_detail'].toString(),
            ),

          // ------------------------------------------------------
          // การเดินทาง
          // ------------------------------------------------------
          if (hasText(dayData['travel']))
            buildDetailInfo(
              icon: Icons.directions_bus,
              title: 'การเดินทาง',
              value: dayData['travel'].toString(),
            ),

          // ------------------------------------------------------
          // โรงแรม
          // ------------------------------------------------------
          if (hasText(dayData['hotel']))
            buildDetailInfo(
              icon: Icons.hotel,
              title: 'ที่พัก',
              value: dayData['hotel'].toString(),
            ),

          // ------------------------------------------------------
          // มื้ออาหาร
          // ------------------------------------------------------
          if (hasText(dayData['meal_detail']))
            buildMealInfo(dayData['meal_detail'].toString()),

          // ------------------------------------------------------
          // ร้านอาหาร
          // ------------------------------------------------------
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
  // TAB 3 : NOTES
  // ==========================================================

  Widget buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'หมายเหตุ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(
            'หมายเหตุของโปรแกรมทัวร์จะแสดงในส่วนนี้',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PRICE ROW
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

    // กรณีเป็น yyyy-MM-dd
    final parts = text.split('-');

    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return text;
  }

  // ==========================================================
  // CHECK TEXT
  // ==========================================================

  bool hasText(dynamic value) {
    if (value == null) {
      return false;
    }

    return value.toString().trim().isNotEmpty;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'รายละเอียดทัวร์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 12),

                    Text(errorMessage!, textAlign: TextAlign.center),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: loadTourDetail,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          : tour == null
          ? const Center(child: Text('ไม่พบข้อมูลทัวร์'))
          : Column(
              children: [
                // ==================================================
                // ส่วนที่ 1 : รูป + ข้อมูลทัวร์
                // ==================================================
                buildTourImage(),

                buildTourSummary(),

                // ==================================================
                // ส่วนที่ 2 : TAB MENU
                // ==================================================
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: TabBar(
                    controller: tabController,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.orange,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'จอง'),
                      Tab(text: 'รายละเอียด / มื้ออาหาร'),
                      Tab(text: 'หมายเหตุ'),
                    ],
                  ),
                ),

                // ==================================================
                // ส่วนที่ 3 : TAB CONTENT
                // ==================================================
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      buildBookingTab(),
                      buildDetailTab(),
                      buildNotesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
