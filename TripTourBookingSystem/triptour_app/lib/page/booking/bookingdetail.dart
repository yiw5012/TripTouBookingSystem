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

  dynamic _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is Map && value.isEmpty) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
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
    final Map<String, dynamic> raw = bookingData;
    final Map<String, dynamic> tourMap = (bookingData['tour'] is Map)
        ? Map<String, dynamic>.from(bookingData['tour'])
        : {};
    final Map<String, dynamic> roundMap = (bookingData['round'] is Map)
        ? Map<String, dynamic>.from(bookingData['round'])
        : {};

    final dynamic firstBookingStatus = _firstNonEmpty([
      bookingData['booking_status'],
      bookingData['status'],
      bookingData['bookingStatus'],
      raw['status'],
    ]);

    final int bookingId =
        int.tryParse(_textValue(bookingData['booking_id'], '0')) ?? 0;
    final int memberId =
        int.tryParse(_textValue(bookingData['member_id'], '0')) ?? 0;
    final int roundId =
        int.tryParse(_textValue(bookingData['round_id'], '0')) ?? 0;
    final String pStatus = (_textValue(
      _firstNonEmpty([
        bookingData['payment_status'],
        bookingData['paymentStatus'],
      ]),
      '',
    )).toLowerCase();

    final String bStatus = (_textValue(firstBookingStatus, '')).toLowerCase();

    final String bookingDate = _formatDateTime(
      _textValue(
                _firstNonEmpty([
                  bookingData['booking_date'],
                  bookingData['created_at'],
                ]),
                '',
              ) ==
              '-'
          ? null
          : _textValue(
              _firstNonEmpty([
                bookingData['booking_date'],
                bookingData['created_at'],
              ]),
              '',
            ),
    );
    final dynamic paymentDate = _firstNonEmpty([
      bookingData['payment_date'],
      bookingData['paid_at'],
    ]);
    final String? formattedPaymentDate = paymentDate == null
        ? null
        : _formatDateTime(paymentDate.toString());
    final String? slipImage =
        _textValue(
              _firstNonEmpty([
                bookingData['slip_image'],
                bookingData['slipImage'],
              ]),
              '',
            ) ==
            ''
        ? null
        : _textValue(
            _firstNonEmpty([
              bookingData['slip_image'],
              bookingData['slipImage'],
            ]),
            '',
          );

    // --- 2. ข้อมูลแพ็กเกจทัวร์ & การเดินทาง ---
    final String tourName = _textValue(
      _firstNonEmpty([
        bookingData['tour_name'],
        bookingData['tourName'],
        tourMap['tour_name'],
        tourMap['tourName'],
      ]),
      'แพ็กเกจทัวร์',
    );
    final int tourId =
        int.tryParse(
          _textValue(
            _firstNonEmpty([
              bookingData['tour_id'],
              bookingData['tourId'],
              tourMap['tour_id'],
              tourMap['tourId'],
            ]),
            '0',
          ),
        ) ??
        0;
    final String tourType = _textValue(
      _firstNonEmpty([
        bookingData['type'],
        bookingData['tour_type'],
        tourMap['type'],
        tourMap['tour_type'],
      ]),
      '-',
    );
    final int durationDay =
        int.tryParse(
          _textValue(
            _firstNonEmpty([
              bookingData['duration_day'],
              tourMap['duration_day'],
              roundMap['duration_day'],
            ]),
            '0',
          ),
        ) ??
        0;
    final String departure = _textValue(
      _firstNonEmpty([
        bookingData['departure'],
        roundMap['departure'],
        bookingData['from'],
      ]),
      '-',
    );
    final String destination = _textValue(
      _firstNonEmpty([
        bookingData['destination'],
        roundMap['destination'],
        bookingData['to'],
      ]),
      '-',
    );
    final String startDate = _formatOnlyDate(
      _textValue(
                _firstNonEmpty([
                  bookingData['start_date'],
                  roundMap['start_date'],
                  bookingData['startDate'],
                ]),
                '',
              ) ==
              '-'
          ? null
          : _textValue(
              _firstNonEmpty([
                bookingData['start_date'],
                roundMap['start_date'],
                bookingData['startDate'],
              ]),
              '',
            ),
    );
    final String endDate = _formatOnlyDate(
      _textValue(
                _firstNonEmpty([
                  bookingData['end_date'],
                  roundMap['end_date'],
                  bookingData['endDate'],
                ]),
                '',
              ) ==
              '-'
          ? null
          : _textValue(
              _firstNonEmpty([
                bookingData['end_date'],
                roundMap['end_date'],
                bookingData['endDate'],
              ]),
              '',
            ),
    );
    final String airline = _textValue(
      _firstNonEmpty([bookingData['airline'], roundMap['airline']]),
      '-',
    );
    final String flight = _textValue(
      _firstNonEmpty([bookingData['flight'], roundMap['flight']]),
      '-',
    );
    final String flightTime = _textValue(
      _firstNonEmpty([bookingData['flight_time'], roundMap['flight_time']]),
      '-',
    );
    final String includeFlight = _textValue(
      _firstNonEmpty([
        bookingData['include_flight'],
        tourMap['include_flight'],
      ]),
      '-',
    );
    final String? guideId =
        _textValue(
              _firstNonEmpty([bookingData['guide_id'], roundMap['guide_id']]),
              '',
            ) ==
            ''
        ? null
        : _textValue(
            _firstNonEmpty([bookingData['guide_id'], roundMap['guide_id']]),
            '',
          );

    // --- 3. รายละเอียดราคา & จำนวน ---
    final int count =
        int.tryParse(
          _textValue(
            _firstNonEmpty([
              bookingData['count'],
              bookingData['quantity'],
              roundMap['count'],
            ]),
            '1',
          ),
        ) ??
        1;
    final String totalPrice = _textValue(
      _firstNonEmpty([bookingData['total_price'], bookingData['totalPrice']]),
      '0.00',
    );
    final String basePrice = _textValue(
      _firstNonEmpty([
        bookingData['price'],
        bookingData['tour_price'],
        tourMap['price'],
        tourMap['tour_price'],
      ]),
      '0.00',
    );
    final String priceSingle = _textValue(
      _firstNonEmpty([bookingData['price_single'], roundMap['price_single']]),
      '-',
    );
    final String priceDouble = _textValue(
      _firstNonEmpty([bookingData['price_double'], roundMap['price_double']]),
      '-',
    );
    final String priceTriple = _textValue(
      _firstNonEmpty([bookingData['price_triple'], roundMap['price_triple']]),
      '-',
    );
    final String? promotion =
        _textValue(
              _firstNonEmpty([bookingData['promotion'], tourMap['promotion']]),
              '',
            ) ==
            ''
        ? null
        : _textValue(
            _firstNonEmpty([bookingData['promotion'], tourMap['promotion']]),
            '',
          );
    final String? conditionDetail =
        _textValue(
              _firstNonEmpty([
                bookingData['condition_detail'],
                tourMap['condition_detail'],
              ]),
              '',
            ) ==
            ''
        ? null
        : _textValue(
            _firstNonEmpty([
              bookingData['condition_detail'],
              tourMap['condition_detail'],
            ]),
            '',
          );
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
                _buildDetailRow('รอบการเดินทาง (Round ID)', '#$roundId'),
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
                _buildDetailRow('รหัสทัวร์ (Tour ID)', '#$tourId'),
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
