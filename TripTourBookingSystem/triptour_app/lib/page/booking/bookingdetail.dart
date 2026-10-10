import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailPage({super.key, required this.bookingData});

  // ฟังก์ชันแปลงวันที่ ISO String ให้เป็นรูปแบบวันที่อ่านง่าย (เช่น 01/10/2026 17:28)
  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm น.').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatOnlyDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  // แปลงสีตามสถานะ
  Color _getStatusColor(String bStatus, String pStatus) {
    if (bStatus == 'completed') return Colors.blue;
    if (pStatus == 'paid') return Colors.green;
    if (pStatus == 'pending') return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(String bStatus, String pStatus) {
    if (bStatus == 'completed') return 'การจองเสร็จสมบูรณ์';
    if (pStatus == 'paid') return 'ชำระเงินสำเร็จ';
    if (pStatus == 'pending') return 'รอชำระเงิน';
    if (pStatus == 'expired' || bStatus == 'expired') return 'หมดอายุ';
    if (pStatus == 'cancelled' || bStatus == 'cancelled') return 'ยกเลิกแล้ว';
    if (pStatus == 'reject' || bStatus == 'reject') return 'ปฏิเสธการจอง';
    return bStatus.isNotEmpty ? bStatus : pStatus;
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. ข้อมูลหลักการจอง ---
    final int bookingId =
        int.tryParse(bookingData['booking_id']?.toString() ?? '0') ?? 0;
    final int memberId =
        int.tryParse(bookingData['member_id']?.toString() ?? '0') ?? 0;
    final int roundId =
        int.tryParse(bookingData['round_id']?.toString() ?? '0') ?? 0;
    final String pStatus = (bookingData['payment_status'] ?? '')
        .toString()
        .toLowerCase();

    // รองรับ booking_status ป้องกันการซ้ำกับ status ของทัวร์
    final String bStatus =
        (bookingData['booking_status'] ?? bookingData['status'] ?? '')
            .toString()
            .toLowerCase();

    final String bookingDate = _formatDateTime(
      bookingData['booking_date']?.toString(),
    );
    final String? paymentDate = bookingData['payment_date'] != null
        ? _formatDateTime(bookingData['payment_date']?.toString())
        : null;
    final String? slipImage = bookingData['slip_image'];

    // --- 2. ข้อมูลแพ็กเกจทัวร์ & การเดินทาง ---
    final String tourName = bookingData['tour_name'] ?? 'แพ็กเกจทัวร์';
    final int tourId =
        int.tryParse(bookingData['tour_id']?.toString() ?? '0') ?? 0;
    final String tourType = bookingData['type'] ?? '-';
    final int durationDay =
        int.tryParse(bookingData['duration_day']?.toString() ?? '0') ?? 0;
    final String departure = bookingData['departure'] ?? '-';
    final String destination = bookingData['destination'] ?? '-';
    final String startDate = _formatOnlyDate(
      bookingData['start_date']?.toString(),
    );
    final String endDate = _formatOnlyDate(bookingData['end_date']?.toString());
    final String airline = bookingData['airline'] ?? '-';
    final String flight = bookingData['flight'] ?? '-';
    final String flightTime = bookingData['flight_time'] ?? '-';
    final String includeFlight = bookingData['include_flight'] ?? '-';
    final String? guideId = bookingData['guide_id']?.toString();
    final String? pdfFile = bookingData['pdf_file'];
    final String? video = bookingData['video'];

    // --- 3. รายละเอียดราคา & จำนวน ---
    final int count =
        int.tryParse(bookingData['count']?.toString() ?? '1') ?? 1;
    final String totalPrice = bookingData['total_price']?.toString() ?? '0.00';
    final String basePrice = bookingData['price']?.toString() ?? '0.00';
    final String priceSingle = bookingData['price_single']?.toString() ?? '-';
    final String priceDouble = bookingData['price_double']?.toString() ?? '-';
    final String priceTriple = bookingData['price_triple']?.toString() ?? '-';
    final String? promotion = bookingData['promotion'];
    final String? conditionDetail = bookingData['condition_detail'];

    return Scaffold(
      appBar: AppBar(title: Text('รายละเอียดการจอง #$bookingId'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. สถานะ & ข้อมูลการจอง =================
            Card(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tourName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              bStatus,
                              pStatus,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(bStatus, pStatus),
                            style: TextStyle(
                              color: _getStatusColor(bStatus, pStatus),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('หมายเลขการจอง', '#$bookingId'),
                    _buildDetailRow('รหัสสมาชิก (Member ID)', '#$memberId'),
                    _buildDetailRow('รอบการเดินทาง (Round ID)', '#$roundId'),
                    _buildDetailRow('วันที่ทำรายการจอง', bookingDate),
                    if (paymentDate != null)
                      _buildDetailRow('วันที่ชำระเงิน', paymentDate),

                    // หากมีหลักฐานการโอนเงิน (สลิป)
                    if (slipImage != null && slipImage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'หลักฐานการชำระเงิน:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          slipImage,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Text('ไม่สามารถโหลดรูปสลิปได้'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= 2. รายละเอียดแพ็กเกจทัวร์ & การเดินทาง =================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลโปรแกรมทัวร์',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('รหัสทัวร์ (Tour ID)', '#$tourId'),
                    _buildDetailRow('ประเภททัวร์', tourType),
                    _buildDetailRow('เส้นทาง', '$departure ➔ $destination'),
                    _buildDetailRow(
                      'ช่วงเวลาเดินทาง',
                      '$startDate ถึง $endDate',
                    ),
                    _buildDetailRow('ระยะเวลา', '$durationDay วัน'),
                    _buildDetailRow('สายการบิน', '$airline ($flight)'),
                    _buildDetailRow('เวลาบิน', flightTime),
                    _buildDetailRow('การรวมตั๋วเครื่องบิน', includeFlight),
                    if (guideId != null)
                      _buildDetailRow('ไกด์ผู้ดูแล', 'Guide #$guideId'),

                    // ปุ่มเปิด PDF / Video / Promotion
                    if (pdfFile != null && pdfFile.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // โค้ดเปิดไฟล์ PDF
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                        label: Text('ดูดาวน์โหลดโปรแกรม ($pdfFile)'),
                      ),
                    ],
                    if (video != null && video.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // โค้ดเปิดคลิป Video
                        },
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.blue,
                        ),
                        label: const Text('รับชมวิดีโอตัวอย่างทัวร์'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= 3. ตารางราคา & จำนวนผู้เดินทาง =================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รายละเอียดราคาและจำนวน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'จำนวนผู้เดินทาง (รับได้สูงสุด)',
                      '$count ท่าน',
                    ),
                    _buildDetailRow('ราคาเริ่มต้น/ท่าน', '฿$basePrice'),
                    _buildDetailRow('พักเดี่ยว (Single)', '฿$priceSingle'),
                    _buildDetailRow('พักคู่ (Double)', '฿$priceDouble'),
                    _buildDetailRow('พัก 3 ท่าน (Triple)', '฿$priceTriple'),

                    if (promotion != null && promotion.isNotEmpty)
                      _buildDetailRow('โปรโมชั่น', promotion),

                    const Divider(height: 24),
                    _buildDetailRow(
                      'ราคารวมสุทธิ',
                      '฿$totalPrice',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            // ================= 4. เงื่อนไขเพิ่มเติม (ถ้ามี) =================
            if (conditionDetail != null && conditionDetail.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เงื่อนไขและรายละเอียดเพิ่มเติม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        conditionDetail,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget ตัวช่วยสร้างแถวข้อมูล Detail
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 18 : 14,
                color: isBold ? const Color(0xFF5B4DFF) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
