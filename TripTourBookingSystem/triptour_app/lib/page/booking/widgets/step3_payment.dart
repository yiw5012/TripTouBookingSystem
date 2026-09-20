import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:triptour_app/serviceBookingApi.dart';

String _statusText(String paymentStatus) {
  switch (paymentStatus) {
    case 'paid':
      return 'ชำระเงินสำเร็จ';
    case 'pending':
      return 'รอชำระเงิน (กรุณาชำระเงินตามเวลาที่กำหนด)';
    case 'failed':
      return 'สลิปถูกปฏิเสธ';
    case 'expired':
      return 'รายการจองหมดอายุ';
    default:
      return 'รอชำระเงิน';
  }
}

class Step3Payment extends StatefulWidget {
  final int totalPrice;
  final Map<String, dynamic> bookingPayload;
  final String memberId; // หรือ String? memberId
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

  int? _bookingId;
  String? _qrPayload;
  String _paymentStatus = 'pending';
  bool _isLoading = false;
  Duration _remainingTime = const Duration(minutes: 15);
  File? _selectedSlipImage;

  @override
  void initState() {
    super.initState();
    _createBookingOrder();
  }

  // 1. สร้างการจองตาม Schema ใหม่ (member_id, round_id, total_price)
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
        setState(() {
          _bookingId = data['booking_id'];
          _qrPayload = data['qr_code'];
          _paymentStatus = data['payment_status'] ?? 'pending';
          _remainingTime = const Duration(minutes: 15);
        });
        _startCountdown();
        _startPollingStatus();
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

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
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

  // 2. เลือกสลิปโอนเงิน
  Future<void> _pickSlipImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedSlipImage = File(pickedFile.path);
      });
    }
  }

  // 3. แนบสลิปไปยัง Backend (/confirm-payment)
  Future<void> _submitPaidReceipt() async {
    if (_bookingId == null || _selectedSlipImage == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await ServiceBookingApi.confirmPayment(
        bookingId: _bookingId!,
        slipImageFile: _selectedSlipImage!,
      );

      final statusCode = response['statusCode'] ?? 500;
      final body = response['body'];

      if (statusCode == 200 && body is Map && body['success'] == true) {
        final data = body['data'];
        final nextStatus = data['status'] ?? 'processing';

        if (mounted) {
          setState(() {
            _paymentStatus = nextStatus;
          });
        }

        _showProcessingDialog();
        _startPollingStatus();
      } else {
        _showSnackBar('อัปโหลดสลิปไม่สำเร็จ', Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการส่งสลิป: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. Polling เช็ก payment_status ด้วย booking_id
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

            if (nextStatus == 'paid') {
              _statusTimer?.cancel();
              _countdownTimer?.cancel();
              // ส่งข้อมูลผู้โดยสารไปยัง Server
              await _submitPassengersToServer();
              _showSuccessDialog();
            } else if (nextStatus == 'expired') {
              _statusTimer?.cancel();
              _showExpiredDialog();
            } else if (nextStatus == 'failed') {
              _showRejectedDialog();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Status poll error: $e');
    }
  }

  Future<void> _submitPassengersToServer() async {
    if (_bookingId == null) return;

    try {
      final payload = Map<String, dynamic>.from(widget.bookingPayload);
      payload['booking_id'] = _bookingId;
      if (!payload.containsKey('passengers') && payload['booking'] != null) {
        payload['passengers'] = payload['booking']['passengers'] ?? [];
      }

      final response = await ServiceBookingApi.submitPassengers(payload);
      final statusCode = response['statusCode'] ?? 500;
      final body = response['body'];

      if (statusCode == 200 && body is Map && body['success'] == true) {
        _showSnackBar('ส่งข้อมูลผู้โดยสารเรียบร้อยแล้ว', Colors.green);
      } else {
        _showSnackBar('ส่งข้อมูลผู้โดยสารไม่สำเร็จ', Colors.red);
      }
    } catch (e) {
      debugPrint('Submit passengers error: $e');
      _showSnackBar('เกิดข้อผิดพลาดในการส่งข้อมูลผู้โดยสาร', Colors.red);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    widget.onBookingStatusChanged?.call(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('ชำระเงินสำเร็จ'),
        content: Text('รายการจอง #$_bookingId ได้รับการยืนยันชำระเงินแล้ว'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showProcessingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.pending_actions, color: Colors.orange, size: 60),
        title: const Text('กำลังดำเนินการจอง'),
        content: const Text(
          'ส่งสลิปเรียบร้อยแล้ว อยู่ระหว่างการตรวจสอบความถูกต้อง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_off, color: Colors.red, size: 60),
        title: const Text('รายการจองหมดอายุ'),
        content: const Text(
          'หมดเวลาชำระเงิน 15 นาที กรุณาทำรายการใหม่อีกครั้ง',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 60,
        ),
        title: const Text('สลิปถูกปฏิเสธ'),
        content: const Text(
          'สลิปไม่ถูกต้อง หรือยอดเงินไม่ตรง กรุณาแนบสลิปใหม่อีกครั้ง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ยอดชำระทั้งสิ้น:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${widget.totalPrice} THB',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_qrPayload != null) ...[
          Center(
            child: QrImageView(
              data: _qrPayload!,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Booking ID: $_bookingId',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'เวลาที่เหลือ: ${_remainingTime.inMinutes.toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Chip(
              label: Text(
                'สถานะ: ${_statusText(_paymentStatus)}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _paymentStatus == 'paid'
                  ? Colors.green
                  : _paymentStatus == 'processing'
                  ? Colors.orange
                  : _paymentStatus == 'expired' || _paymentStatus == 'failed'
                  ? Colors.red
                  : Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          if (_paymentStatus == 'pending' || _paymentStatus == 'failed') ...[
            if (_selectedSlipImage != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedSlipImage!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickSlipImage,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  _selectedSlipImage == null
                      ? 'แนบรูปภาพสลิปโอนเงิน'
                      : 'เปลี่ยนรูปภาพสลิป',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedSlipImage != null
                    ? _submitPaidReceipt
                    : null,
                icon: const Icon(Icons.send),
                label: const Text('ยืนยันส่งสลิปชำระเงิน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ] else ...[
          const Center(child: Text('กำลังสร้าง QR Code...')),
        ],
      ],
    );
  }
}
