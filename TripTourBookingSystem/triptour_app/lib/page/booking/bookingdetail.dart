import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';
import 'package:url_launcher/url_launcher.dart';
// import หน้า TourDetailPage ของโปรเจกต์คุณ เช่น:

class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailPage({super.key, required this.bookingData});

  // ฟังก์ชันสำหรับเปิด URL (PDF หรือ Video)
  Future<void> _openUrl(String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication, // เปิดด้วยแอปภายนอก เช่น Chrome หรือ Drive PDF Viewer
      );

      if (!launched) {
        Get.snackbar('แจ้งเตือน', 'ไม่สามารถเปิดลิงก์นี้ได้');
      }
    } catch (e) {
      debugPrint('UrlLauncher Error: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปิดเอกสารได้ กรุณาตรวจสอบเบราว์เซอร์ในเครื่อง',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ฟังก์ชันแปลงวันที่ ISO String ให้เป็นรูปแบบวันที่อ่านง่าย
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
    if (bStatus == 'finish' || bStatus == 'completed') {
      return const Color(0xFF2E7D32);
    }
    if (bStatus == 'confirmed' || pStatus == 'paid') {
      return const Color(0xFF1FAE74);
    }
    if (pStatus == 'pending') return const Color(0xFFFF9800);
    return const Color(0xFFDC5A5A);
  }

  String _getStatusText(String bStatus, String pStatus) {
    if (bStatus == 'finish' || bStatus == 'completed') {
      return 'การจองเสร็จสมบูรณ์';
    }
    if (bStatus == 'confirmed') return 'ยืนยันการจองแล้ว';
    if (pStatus == 'paid') return 'ชำระเงินสำเร็จ';
    if (pStatus == 'pending') return 'รอชำระเงิน';
    if (pStatus == 'expired' || bStatus == 'expired') return 'หมดอายุ';
    if (pStatus == 'cancelled' || bStatus == 'cancelled') return 'ยกเลิกแล้ว';
    if (pStatus == 'reject' || bStatus == 'reject') return 'ปฏิเสธการจอง';
    return bStatus.isNotEmpty ? bStatus : pStatus;
  }

  // แสดง Modal รูปสลิปขนาดใหญ่เมื่อกดดู
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: const Text('ไม่สามารถโหลดรูปสลิปได้'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

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
    final String? tourType = bookingData['type'];
    final int? durationDay = int.tryParse(
      bookingData['duration_day']?.toString() ?? '',
    );
    final String? departure = bookingData['departure'];
    final String? destination = bookingData['destination'];
    final String? startDate = bookingData['start_date'] != null
        ? _formatOnlyDate(bookingData['start_date']?.toString())
        : null;
    final String? endDate = bookingData['end_date'] != null
        ? _formatOnlyDate(bookingData['end_date']?.toString())
        : null;
    final String? airline = bookingData['airline'];
    final String? flight = bookingData['flight'];
    final String? flightTime = bookingData['flight_time'];
    final String includeFlight = bookingData['include_flight'] ?? 'รวม';
    final String? pdfFile = bookingData['pdf_file'];
    final String? video = bookingData['video'];

    // --- 3. รายละเอียดราคา & จำนวน ---
    final int count =
        int.tryParse(bookingData['count']?.toString() ?? '1') ?? 1;
    final num totalPrice =
        num.tryParse(bookingData['total_price']?.toString() ?? '0') ?? 0;
    final String? basePrice = bookingData['price']?.toString();
    final String? priceSingle = bookingData['price_single']?.toString();
    final String? priceDouble = bookingData['price_double']?.toString();
    final String? priceTriple = bookingData['price_triple']?.toString();
    final String? promotion = bookingData['promotion'];
    final String? conditionDetail = bookingData['condition_detail'];

    final statusColor = _getStatusColor(bStatus, pStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'รายละเอียดการจอง #$bookingId',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. Header Card (ชื่อทัวร์ + สถานะ) =================
            _buildCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tourName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(bStatus, pStatus),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 📌 ปุ่มกดไปดูรายละเอียดทัวร์ที่จอง
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (tourId > 0) {
                          Get.to(() => DetailTour(tourId: tourId));
                        } else {
                          Get.snackbar('แจ้งเตือน', 'ไม่พบรหัสทัวร์นี้');
                        }
                      },
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text('ดูรายละเอียดแพ็กเกจทัวร์นี้'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B4DFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 14),
                  _buildDetailRow('หมายเลขการจอง', '#$bookingId'),
                  if (memberId > 0)
                    _buildDetailRow('รหัสสมาชิก (Member ID)', '#$memberId'),
                  if (roundId > 0)
                    _buildDetailRow('รอบการเดินทาง (Round ID)', '#$roundId'),
                  _buildDetailRow('วันที่ทำรายการจอง', bookingDate),
                  if (paymentDate != null)
                    _buildDetailRow('วันที่ชำระเงิน', paymentDate),

                  // หลักฐานการชำระเงิน (กรณีมี slip_image)
                  if (slipImage != null && slipImage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'หลักฐานการชำระเงิน',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showImageDialog(context, slipImage),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  slipImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text(
                                      'ไม่สามารถโหลดรูปสลิปได้',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'ดูรูปใหญ่',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ================= 2. รายละเอียดแพ็กเกจทัวร์ & การเดินทาง =================
            _buildCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'ข้อมูลโปรแกรมทัวร์',
                    Icons.travel_explore_rounded,
                  ),
                  const SizedBox(height: 12),

                  // Route Banner (แสดงเมื่อมีข้อมูลเส้นทาง)
                  if (departure != null && destination != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4DFF).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flight_takeoff_rounded,
                            color: Color(0xFF5B4DFF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$departure ➔ $destination',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildDetailRow('รหัสทัวร์ (Tour ID)', '#$tourId'),
                  if (tourType != null)
                    _buildDetailRow('ประเภททัวร์', tourType),
                  if (startDate != null && endDate != null)
                    _buildDetailRow(
                      'ช่วงเวลาเดินทาง',
                      '$startDate ถึง $endDate',
                    ),
                  if (durationDay != null && durationDay > 0)
                    _buildDetailRow('ระยะเวลา', '$durationDay วัน'),
                  if (airline != null)
                    _buildDetailRow(
                      'สายการบิน',
                      flight != null ? '$airline ($flight)' : airline,
                    ),
                  if (flightTime != null)
                    _buildDetailRow('เวลาบิน', flightTime),
                  _buildDetailRow('ตั๋วเครื่องบิน', includeFlight),

                  // ปุ่มดาวน์โหลด PDF โปรแกรมทัวร์
                  if (pdfFile != null && pdfFile.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _openUrl(pdfFile),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ดาวน์โหลดเอกสารโปรแกรมทัวร์ (PDF)',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ปุ่มดู Video ตัวอย่างทัวร์
                  if (video != null && video.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openUrl(video),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.blue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'รับชมวิดีโอตัวอย่างทัวร์',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ================= 3. ตารางราคา & จำนวนผู้เดินทาง =================
            _buildCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'รายละเอียดราคาและจำนวน',
                    Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('จำนวนผู้เดินทาง', '$count ท่าน'),
                  if (basePrice != null)
                    _buildDetailRow('ราคาเริ่มต้น/ท่าน', '฿$basePrice'),
                  if (priceSingle != null)
                    _buildDetailRow('พักเดี่ยว (Single)', '฿$priceSingle'),
                  if (priceDouble != null)
                    _buildDetailRow('พักคู่ (Double)', '฿$priceDouble'),
                  if (priceTriple != null)
                    _buildDetailRow('พัก 3 ท่าน (Triple)', '฿$priceTriple'),
                  if (promotion != null && promotion.isNotEmpty)
                    _buildDetailRow('โปรโมชั่น', promotion),

                  const SizedBox(height: 12),
                  // Highlight Total Price Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9E7FF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ราคารวมสุทธิ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '฿${currencyFormat.format(totalPrice)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B4DFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= 4. เงื่อนไขเพิ่มเติม (ถ้ามี) =================
            if (conditionDetail != null && conditionDetail.isNotEmpty)
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'เงื่อนไขและรายละเอียดเพิ่มเติม',
                      Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      conditionDetail,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5B4DFF)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 15 : 13,
                color: isBold
                    ? const Color(0xFF5B4DFF)
                    : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
