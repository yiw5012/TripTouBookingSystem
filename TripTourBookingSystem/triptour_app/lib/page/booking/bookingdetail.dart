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

  String _textValue(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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
    final int bookingId =
        int.tryParse(_textValue(bookingData['booking_id'], '0')) ?? 0;
    final int memberId =
        int.tryParse(_textValue(bookingData['member_id'], '0')) ?? 0;
    final String roundCode = _textValue(bookingData['round_code'], '-');
    final String pStatus = _textValue(
      bookingData['payment_status'],
      '',
    ).toLowerCase();

    final String bStatus = _textValue(
      bookingData['booking_status'],
      '',
    ).toLowerCase();

    final String bookingDateRaw = _textValue(bookingData['booking_date'], '');
    final String bookingDate = _formatDateTime(
      bookingDateRaw.isEmpty ? null : bookingDateRaw,
    );

    final String paymentDateRaw = _textValue(bookingData['payment_date'], '');
    final String? formattedPaymentDate = paymentDateRaw.isEmpty
        ? null
        : _formatDateTime(paymentDateRaw);

    final String slipImageRaw = _textValue(bookingData['slip_image'], '');
    final String? slipImage = slipImageRaw.isEmpty ? null : slipImageRaw;

    // --- 2. ข้อมูลแพ็กเกจทัวร์ & การเดินทาง ---
    final String tourName = _textValue(
      bookingData['tour_name'],
      'แพ็กเกจทัวร์',
    );
    final String tourCode = _textValue(bookingData['tour_code'], '-');
    final String tourType = _textValue(bookingData['type'], '-');
    final int durationDay =
        int.tryParse(_textValue(bookingData['duration_day'], '0')) ?? 0;
    final String departure = _textValue(bookingData['departure'], '-');
    final String destination = _textValue(bookingData['destination'], '-');
    final String startDate = _formatOnlyDate(
      _textValue(bookingData['start_date'], '') == '-'
          ? null
          : _textValue(bookingData['start_date'], ''),
    );
    final String endDate = _formatOnlyDate(
      _textValue(bookingData['end_date'], '') == '-'
          ? null
          : _textValue(bookingData['end_date'], ''),
    );
    final String airline = _textValue(bookingData['airline'], '-');
    final String flight = _textValue(bookingData['flight'], '-');
    final String flightTime = _textValue(bookingData['flight_time'], '-');
    final String includeFlight = _textValue(bookingData['include_flight'], '-');
    final String? guideId = _textValue(bookingData['guide_id'], '') == ''
        ? null
        : _textValue(bookingData['guide_id'], '');

    // --- 3. รายละเอียดราคา & จำนวน ---
    final int count = int.tryParse(_textValue(bookingData['count'], '1')) ?? 1;
    final String totalPrice = _textValue(bookingData['total_price'], '0.00');
    final String basePrice = _textValue(bookingData['price'], '0.00');
    final String priceSingle = _textValue(bookingData['price_single'], '-');
    final String priceDouble = _textValue(bookingData['price_double'], '-');
    final String priceTriple = _textValue(bookingData['price_triple'], '-');
    final String? promotion = _textValue(bookingData['promotion'], '') == ''
        ? null
        : _textValue(bookingData['promotion'], '');
    final String? conditionDetail =
        _textValue(bookingData['condition_detail'], '') == ''
        ? null
        : _textValue(bookingData['condition_detail'], '');
    final Color statusColor = _getStatusColor(bStatus, pStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F7),
      appBar: AppBar(
        title: Text('รายละเอียดการจอง #$bookingId'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E8E5A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E8E5A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E8E5A).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tourName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'รหัสการจอง #$bookingId',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _getStatusText(bStatus, pStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _buildSectionCard(
              title: 'ข้อมูลการจอง',
              children: [
                _buildDetailRow('หมายเลขการจอง', '#$bookingId'),
                _buildDetailRow('รหัสสมาชิก (Member ID)', '#$memberId'),
                _buildDetailRow('รหัสรอบทัวร์', roundCode),
                _buildDetailRow('วันที่ทำรายการจอง', bookingDate),
                if (formattedPaymentDate != null)
                  _buildDetailRow('วันที่ชำระเงิน', formattedPaymentDate),
                if (slipImage != null && slipImage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'หลักฐานการชำระเงิน',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      slipImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Text('ไม่สามารถโหลดรูปสลิปได้'),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'ข้อมูลโปรแกรมทัวร์',
              children: [
                _buildDetailRow('รหัสทัวร์', tourCode),
                _buildDetailRow('ประเภททัวร์', tourType),
                _buildDetailRow('เส้นทาง', '$departure ➔ $destination'),
                _buildDetailRow('ช่วงเวลาเดินทาง', '$startDate ถึง $endDate'),
                _buildDetailRow('ระยะเวลา', '$durationDay วัน'),
                _buildDetailRow('สายการบิน', '$airline ($flight)'),
                _buildDetailRow('เวลาบิน', flightTime),
                _buildDetailRow('การรวมตั๋วเครื่องบิน', includeFlight),
                if (guideId != null)
                  _buildDetailRow('ไกด์ผู้ดูแล', 'Guide #$guideId'),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'รายละเอียดราคาและจำนวน',
              children: [
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF8F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8F0E3)),
                  ),
                  child: _buildDetailRow(
                    'ราคารวมสุทธิ',
                    '฿$totalPrice',
                    isBold: true,
                  ),
                ),
              ],
            ),

            if (conditionDetail != null && conditionDetail.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'เงื่อนไขและรายละเอียดเพิ่มเติม',
                children: [
                  Text(
                    conditionDetail,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4D3A),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 17 : 14,
                color: isBold ? const Color(0xFF1E8E5A) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
