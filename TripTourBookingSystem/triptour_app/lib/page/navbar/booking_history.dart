import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:triptour_app/page/Tourdetail/reviewTour.dart';
import 'package:triptour_app/page/booking/bookingdetail.dart';
import 'package:triptour_app/page/booking/widgets/step3_payment.dart';
import 'package:triptour_app/serviceBookingApi.dart';

class BookingHistoryPage extends StatefulWidget {
  final String memberId;

  const BookingHistoryPage({super.key, required this.memberId});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _bookingList = [];

  @override
  void initState() {
    super.initState();
    if (widget.memberId.isNotEmpty) {
      _fetchBookingHistory();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant BookingHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId && widget.memberId.isNotEmpty) {
      _fetchBookingHistory();
    }
  }

  Future<void> _fetchBookingHistory() async {
    if (widget.memberId.isEmpty) return;

    setState(() => _isLoading = true);

    final res = await ServiceBookingApi.getBookingHistory(widget.memberId);

    if (res != null) {
      if (res['statusCode'] == 200) {
        final body = res['body'];
        if (body is Map && body['success'] == true) {
          setState(() {
            _bookingList = body['data'] ?? [];
          });
        }
      } else if (res['statusCode'] == 404) {
        setState(() {
          _bookingList = [];
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --- กรองเฉพาะรายการปัจจุบัน (pending และ paid ที่ยังไม่ finish) ---
  List<dynamic> get _activeBookings => _bookingList.where((item) {
    final pStatus = (item['payment_status'] ?? '').toString().toLowerCase();
    final status = (item['booking_status'] ?? '').toString().toLowerCase();
    final isPending = pStatus == 'pending' || status == 'pending';
    final isPaidNotCompleted = pStatus == 'paid' && status != 'finish';
    return isPending || isPaidNotCompleted;
  }).toList();

  void _navigateToAllBookings() {
    Get.to(
      () => AllBookingsPage(
        bookingList: _bookingList,
        memberId: widget.memberId,
        onRefresh: _fetchBookingHistory,
      ),
    )?.then((_) => _fetchBookingHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การจองปัจจุบัน'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToAllBookings,
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติการจองทั้งหมด',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // แบนเนอร์ปุ่มกดไปหน้าการจองทั้งหมด
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: _navigateToAllBookings,
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'ดูการจองทั้งหมด',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBookingListWidget(
                    _activeBookings,
                    _fetchBookingHistory,
                    widget.memberId,
                  ),
                ),
              ],
            ),
    );
  }
}

// ==========================================
class AllBookingsPage extends StatelessWidget {
  final List<dynamic> bookingList;
  final String memberId;
  final Future<void> Function() onRefresh;

  const AllBookingsPage({
    super.key,
    required this.bookingList,
    required this.memberId,
    required this.onRefresh,
  });

  // แท็บ 1: ชำระเงินเสร็จสิ้น (paid)
  List<dynamic> get _paidBookings => bookingList.where((item) {
    final pStatus = (item['payment_status'] ?? '').toString().toLowerCase();
    final status = (item['booking_status'] ?? '').toString().toLowerCase();
    return pStatus == 'paid' && status != 'finish';
  }).toList();

  // แท็บ 2: การจองเสร็จสมบูรณ์ (admin status: finish)
  List<dynamic> get _completedBookings => bookingList.where((item) {
    final bookingStatus = (item['booking_status'] ?? '')
        .toString()
        .toLowerCase();

    return bookingStatus == 'finish';
  }).toList();

  // แท็บ 3: ยกเลิก / หมดอายุ (expired, cancelled, failed, reject)
  List<dynamic> get _cancelledOrExpiredBookings => bookingList.where((item) {
    final pStatus = (item['payment_status'] ?? '').toString().toLowerCase();
    final status = (item['booking_status'] ?? '').toString().toLowerCase();
    const invalidStatuses = ['expired', 'cancelled', 'reject'];

    return invalidStatuses.contains(pStatus) ||
        invalidStatuses.contains(status);
  }).toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('การจองทั้งหมด'),
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'ชำระเงินเสร็จสิ้น'),
              Tab(text: 'การจองเสร็จสมบูรณ์'),
              Tab(text: 'ยกเลิก / หมดอายุ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingListWidget(_paidBookings, onRefresh, memberId),
            _buildBookingListWidget(_completedBookings, onRefresh, memberId),
            _buildBookingListWidget(
              _cancelledOrExpiredBookings,
              onRefresh,
              memberId,
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildReviewButton(BuildContext context, Map<String, dynamic> item) {
  final status = (item['booking_status'] ?? '').toString().toLowerCase();
  final tourId = int.tryParse(item['tour_id']?.toString() ?? '');
  final tourName = item['tour_name']?.toString() ?? 'ทัวร์';

  if (status != 'finish' && status != 'completed') return const SizedBox();
  if (tourId == null) return const SizedBox();

  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ReviewTourPage(tourId: tourId, tourName: tourName),
            ),
          );
        },
        icon: const Icon(Icons.star_rate, size: 18),
        label: const Text('ให้คะแนนทัวร์'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
  );
}

Widget _buildBookingListWidget(
  List<dynamic> list,
  Future<void> Function() onRefresh,
  String memberId,
) {
  // กำหนดสี: แสดงเฉพาะสีเขียว (ผ่าน/สำเร็จ) และสีแดง (อื่นๆ ทั้งหมด)
  Color getStatusColor(String status, String pStatus) {
    if (status == 'confirmed' || pStatus == 'paid') {
      return Colors.green;
    }
    return Colors.red;
  }

  String getStatusText(String bStatus, String pStatus) {
    if (bStatus == 'finish') return 'การจองเสร็จสมบูรณ์';
    if (bStatus == 'confirmed') return 'ยืนยันการจองแล้ว';
    if (pStatus == 'paid') return 'ชำระเงินสำเร็จ (รอการยืนยัน)';
    if (pStatus == 'pending') return 'รอชำระเงิน';
    if (pStatus == 'expired') return 'หมดอายุ';
    if (bStatus == 'cancelled') return 'ยกเลิกแล้ว';
    if (bStatus == 'reject') return 'ปฏิเสธการจอง';
    return bStatus.isNotEmpty ? bStatus : pStatus;
  }

  if (list.isEmpty) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Center(child: Text('ไม่พบประวัติการจองในหมวดนี้')),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final int bookingId =
            int.tryParse(item['booking_id']?.toString() ?? '0') ?? 0;
        final pStatus = (item['payment_status'] ?? '').toString().toLowerCase();
        final status = (item['booking_status'] ?? '').toString().toLowerCase();
        final num totalPrice =
            num.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
        final tourName = item['tour_name'] ?? 'แพ็กเกจทัวร์';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Get.to(
                () => BookingDetailPage(bookingData: item),
              )?.then((_) => onRefresh());
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booking #$bookingId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        getStatusText(status, pStatus),
                        style: TextStyle(
                          color: getStatusColor(status, pStatus),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(tourName, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    'ยอดรวม: ฿$totalPrice',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B4DFF),
                    ),
                  ),
                  if (pStatus == 'pending') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(
                            () => Scaffold(
                              appBar: AppBar(
                                title: Text('ชำระเงินต่อ #$bookingId'),
                              ),
                              body: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Step3Payment.fromHistory(
                                  bookingId: bookingId,
                                  memberId: memberId,
                                  totalPrice: totalPrice,
                                ),
                              ),
                            ),
                          )?.then((_) => onRefresh());
                        },
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('ชำระเงินต่อ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4DFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  buildReviewButton(context, item),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
