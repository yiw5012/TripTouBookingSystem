import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/serviceBookingApi.dart';

String _statusText(String paymentStatus) {
  switch (paymentStatus) {
    case 'paid':
      return 'ชำระเงินสำเร็จ';
    case 'pending':
      return 'รอชำระเงิน / รอตรวจสอบ';
    case 'failed':
      return 'สลิปไม่ถูกต้อง (กรุณาแนบใหม่)';
    case 'expired':
      return 'รายการจองหมดอายุ';
    default:
      return 'รอชำระเงิน';
  }
}

Color _statusColor(String paymentStatus) {
  switch (paymentStatus) {
    case 'paid':
      return const Color(0xFF2ECC71);
    case 'pending':
      return const Color(0xFFF39C12);
    case 'failed':
    case 'expired':
      return const Color(0xFFE74C3C);
    default:
      return Colors.grey;
  }
}

class Step3Payment extends StatefulWidget {
  final int totalPrice;
  final Map<String, dynamic> bookingPayload;
  final String memberId;
  final String roundId;
  final ValueChanged<bool>? onBookingStatusChanged;

  const Step3Payment({
    super.key,
    required this.totalPrice,
    required this.bookingPayload,
    required this.memberId,
    required this.roundId,
    this.onBookingStatusChanged,
  });

  @override
  State<Step3Payment> createState() => _Step3PaymentState();
}

class _Step3PaymentState extends State<Step3Payment> {
  Timer? _statusTimer;
  Timer? _countdownTimer;
  final GlobalKey _qrkey = GlobalKey();
  int? _bookingId;
  String? _qrPayload;
  String _paymentStatus =
      'pending'; // 'pending' | 'paid' | 'expired' | 'failed'
  bool _isLoading = false;
  Duration _remainingTime = const Duration(minutes: 15);
  File? _selectedSlipImage;
  File? passpot_passenger;
  @override
  void initState() {
    super.initState();
    _createBookingOrder();
  }

  Future<void> _createBookingOrder() async {
    setState(() => _isLoading = true);

    try {
      final response = await ServiceBookingApi.createBookingOrder({
        'member_id': widget.memberId,
        'round_id': widget.roundId,
        'total_price': widget.totalPrice,
      });

      final statusCode = response['statusCode'] ?? 500;
      final body = response['body'];

      if (statusCode == 200 && body is Map && body['success'] == true) {
        final data = body['data'];
        final createdBookingId = data['booking_id'];

        setState(() {
          _bookingId = createdBookingId;
          _qrPayload = data['qr_code'];
          _paymentStatus = data['payment_status'] ?? 'pending';
          _remainingTime = const Duration(minutes: 15);
        });

        _startCountdown();
        _startPollingStatus();

        if (createdBookingId != null) {
          await _submitPassengersToServer(createdBookingId);
        }
      } else {
        final message = body is Map
            ? (body['message'] ?? 'Unable to create order')
            : 'Error';
        _showSnackBar(message, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error creating QR: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPassengersToServer(int bookingId) async {
    try {
      final payload = Map<String, dynamic>.from(widget.bookingPayload);

      final List passengers = payload['passengers'] ?? [];
      payload['booking_id'] = bookingId;
      if (!payload.containsKey('passengers') && payload['booking'] != null) {
        payload['passengers'] = payload['booking']['passengers'] ?? [];
      }

      // 1. ดึงไฟล์รูปภาพพาสปอร์ตจาก passengers
      File? passportFile;
      if (passengers.isNotEmpty) {
        final String? path = passengers[0]['passport_image_path'];
        if (path != null && path.isNotEmpty) {
          passportFile = File(path);
        }
      }
      final response = await ServiceBookingApi.submitPassengers(
        data: payload,
        passpot_passenger: passportFile,
      );
      debugPrint('Submit passengers response: $response');
    } catch (e) {
      debugPrint('Submit passengers error: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        _statusTimer?.cancel();
        if (_paymentStatus == 'pending') {
          setState(() => _paymentStatus = 'expired');
        }
        return;
      }
      setState(() {
        _remainingTime = _remainingTime - const Duration(seconds: 1);
      });
    });
  }

  Future<void> _pickSlipImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedSlipImage = File(pickedFile.path);
      });
    }
  }

  // ฟังก์ชันสำหรับกดปุ่ม "ตรวจสอบสลิป" (ส่งสลิปหรือดึงสถานะล่าสุด)
  Future<void> _checkOrSubmitSlip() async {
    if (_bookingId == null) return;

    // กรณีเลือกสลิปใหม่ -> สั่งอัปโหลดสลิป
    if (_selectedSlipImage != null) {
      setState(() => _isLoading = true);
      try {
        final response = await ServiceBookingApi.confirmPayment(
          bookingId: _bookingId!,
          slipImageFile: _selectedSlipImage!,
        );

        final statusCode = response['statusCode'] ?? 500;
        final body = response['body'];

        if (statusCode == 200 && body is Map && body['success'] == true) {
          _showSnackBar('ส่งสลิปสำเร็จ กำลังตรวจสอบสถานะ...', Colors.blue);
          await _pollOrderStatus(); // ตรวจสอบสถานะทันที
        } else {
          final message = body is Map
              ? body['message']
              : 'อัปโหลดสลิปไม่สำเร็จ';
          _showSnackBar(message ?? 'อัปโหลดสลิปไม่สำเร็จ', Colors.red);
        }
      } catch (e) {
        _showSnackBar('เกิดข้อผิดพลาดในการส่งสลิป: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // กรณียังไม่ได้เลือกสลิป -> กดเพื่อรีเฟรชเช็กสถานะจาก Server
      setState(() => _isLoading = true);
      await _pollOrderStatus();
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('อัปเดตสถานะล่าสุดเรียบร้อย', Colors.green);
      }
    }
  }

  // ดึงสถานะการจองจาก Server (ไม่มีการเปิด Pop-up กวนใจแล้ว)
  Future<void> _pollOrderStatus() async {
    if (_bookingId == null || !mounted) return;

    try {
      final response = await ServiceBookingApi.getBookingStatus(
        _bookingId.toString(),
      );
      final statusCode = response['statusCode'] ?? 500;
      final body = response['body'];

      if (statusCode == 200 && body is Map && body['success'] == true) {
        final data = body['data'];
        if (data != null && data['status'] != null) {
          final nextStatus = data['status'];

          if (_paymentStatus != nextStatus) {
            setState(() => _paymentStatus = nextStatus);

            // แจ้งเตือนเมื่อชำระเงินสำเร็จแล้วเด้งออกอัตโนมัติ
            if (nextStatus == 'paid') {
              _statusTimer?.cancel();
              _countdownTimer?.cancel();
              _handlePaymentSuccessAndExit();
            } else if (nextStatus == 'expired') {
              _statusTimer?.cancel();
              _countdownTimer?.cancel();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Status poll error: $e');
    }
  }

  void _startPollingStatus() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollOrderStatus();
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Pop-up แจ้งเตือนเฉพาะเมื่อชำระเงินสำเร็จ
  void _handlePaymentSuccessAndExit() {
    if (!mounted) return;
    widget.onBookingStatusChanged?.call(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
            Get.to(Homepage());
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 64,
          ),
          title: const Text(
            'ชำระเงินสำเร็จ!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('รายการจอง #$_bookingId ได้รับการยืนยันเรียบร้อยแล้ว'),
              const SizedBox(height: 12),
              const Text(
                'กำลังนำคุณกลับสู่หน้าหลัก...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadQrCode() async {
    if (_qrPayload == null) return;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final boundary =
          _qrkey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _showSnackBar('ไม่พบข้อมูล QR Code', Colors.red);
        return;
      }

      // 3. แปลง Widget เป็นรูปภาพความละเอียดสูง (pixelRatio: 3.0)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List imageBytes = byteData.buffer.asUint8List();

        await Gal.putImageBytes(
          imageBytes,
          name:
              'QR_Booking_${_bookingId ?? DateTime.now().millisecondsSinceEpoch}',
        );

        _showSnackBar(
          'บันทึกรูป QR Code ลงในคลังภาพเรียบร้อยแล้ว',
          Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการบันทึก QR Code: $e', Colors.red);
    }
  }

  void _cancelPayment() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();
    Get.to(Homepage());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D9FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ยอดชำระทั้งสิ้น',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_bookingId != null)
                Text(
                  'Booking #$_bookingId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          Text(
            '฿${widget.totalPrice}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B4DFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF5B4DFF),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'สแกน QR Code เพื่อชำระเงิน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          RepaintBoundary(
            key: _qrkey,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: _qrPayload!,
                size: 190,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _downloadQrCode,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'ดาวน์โหลด QR Code',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B4DFF),
                side: const BorderSide(color: Color(0xFF5B4DFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(_paymentStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: _statusColor(_paymentStatus),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusText(_paymentStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(_paymentStatus),
                      ),
                    ),
                  ],
                ),
              ),
              if (_paymentStatus == 'pending')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'เหลือเวลา ${_remainingTime.inMinutes.toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.mark_chat_unread_rounded,
            color: Color(0xFFF57C00),
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'หมายเหตุ: แอดมินจะตรวจสอบอีกทีแล้วจะดำเนินการจองเสร็จสิ้น โปรดรอการยืนยันจากแอดมิน เมื่อแอดมินตรวจสอบแล้ว จะได้เข้ากลุ่มแชทอัตโนมัติ',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ส่วนแนบสลิป + ปุ่มปฏิบัติการ "ยกเลิก" และ "ตรวจสอบสลิป"
  Widget _buildSlipUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'หลักฐานการชำระเงิน',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),

        if (_selectedSlipImage != null)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(_selectedSlipImage!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: _pickSlipImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickSlipImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 36,
                    color: Color(0xFF5B4DFF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กดที่นี่เพื่อเลือกรูปภาพสลิปโอนเงิน',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'รองรับไฟล์ JPG, PNG',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // แถบปุ่มกด 2 ปุ่ม: "ยกเลิก" และ "ตรวจสอบสลิป"
        Row(
          children: [
            // 1. ปุ่มยกเลิก
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _cancelPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. ปุ่มตรวจสอบสลิป / ส่งสลิป
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _checkOrSubmitSlip,
                  icon: const Icon(Icons.fact_check_rounded, size: 20),
                  label: Text(
                    _selectedSlipImage != null
                        ? 'ส่งและตรวจสอบสลิป'
                        : 'ตรวจสอบสลิป',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4DFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5B4DFF)),
              ),
            )
          else if (_qrPayload != null) ...[
            _buildQrCard(),
            const SizedBox(height: 16),

            _buildAdminNoticeBanner(),
            const SizedBox(height: 20),

            if (_paymentStatus != 'paid' && _paymentStatus != 'expired')
              _buildSlipUploadSection(),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('กำลังสร้าง QR Code...')),
            ),
          ],
        ],
      ),
    );
  }
}
