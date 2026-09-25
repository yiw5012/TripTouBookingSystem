import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // ดึงข้อมูลประวัติการจอง
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

  // แปลงสีตามสถานะ
  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // แปลงข้อความสถานะเป็นภาษาไทย
  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'ชำระเงินสำเร็จ';
      case 'pending':
        return 'รอชำระเงิน';
      case 'expired':
        return 'หมดอายุ';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการจองของฉัน'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookingList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ไม่พบประวัติการจอง'),
                  const SizedBox(height: 12),
                  if (widget.memberId.isNotEmpty)
                    ElevatedButton(
                      onPressed: _fetchBookingHistory,
                      child: const Text('รีเฟรชข้อมูล'),
                    ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchBookingHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookingList.length,
                itemBuilder: (context, index) {
                  final item = _bookingList[index];
                  final int bookingId =
                      int.tryParse(item['booking_id']?.toString() ?? '0') ?? 0;
                  final status =
                      item['payment_status'] ?? item['status'] ?? 'pending';
                  final num totalPrice =
                      num.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
                  final tourName = item['tour_name'] ?? 'แพ็กเกจทัวร์';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
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
                          if (status == 'pending') ...[
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
                                          memberId: widget.memberId,
                                          totalPrice: totalPrice,
                                        ),
                                      ),
                                    ),
                                  )?.then((_) => _fetchBookingHistory());
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
