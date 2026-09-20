import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Android Emulator ใช้ 10.0.2.2 สำหรับ localhost ของเครื่อง host
  final String _baseUrl = 'http://10.0.2.2:4000';
  late IO.Socket _socket;
  Timer? _statusTimer;

  String? _orderId;
  String? _qrPayload;
  double? _amount;
  String _status = 'pending';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  // เชื่อมต่อ Web Socket เพื่อรอรับ Push Notification สดจาก Backend
  void _initSocket() {
    _socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.on('payment_status', (data) {
      if (data['order_id'] == _orderId) {
        setState(() {
          _status = data['status'];
        });

        if (_status == 'paid') {
          _showSuccessDialog();
        }
      }
    });
  }

  // เรียก API สร้าง Order
  Future<void> _createBookingOrder() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/booking/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'booking': {
            'user_id': 'usr_999',
            'tour_id': 'T001',
            'round_id': 'R001',
            'route': 'Bangkok → Chiang Mai',
            'trip_dates': '2026-10-01 ถึง 2026-10-05',
            'airline': 'Thai Airways',
            'room_summary': 'ผู้ใหญ่ 2 พัก 1 ห้อง: 1 ห้อง',
            'traveler_count': 1,
            'total_price': 2500,
            'currency': 'THB',
            'contact': {
              'name': 'John Doe',
              'phone': '0812345678',
              'email': 'john@example.com',
            },
            'payment': {'method': 'QR', 'status': 'pending'},
          },
          'passengers': [
            {
              'passenger_number': 1,
              'type': 'ผู้ใหญ่ 2 พัก 1 ห้อง',
              'name': 'John Doe',
              'gender': 'Male',
              'id_card': '1234567890123',
              'birthday': '1990-01-01',
              'phone': '0812345678',
              'address': 'Bangkok',
            },
          ],
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];
        setState(() {
          _orderId = data['order_id'];
          _qrPayload = data['qr_code'];
          _amount = (data['amount'] as num).toDouble();
          _status = 'pending';
        });

        _socket.emit('join_order', _orderId);
        _startPollingStatus();
      } else {
        final message = result['message'] ?? 'Unable to create order';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pollOrderStatus() async {
    if (_orderId == null || !mounted) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/booking/status/$_orderId'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final data = result['data'];
        if (data != null && data['status'] != null) {
          setState(() {
            _status = data['status'];
          });

          if (data['status'] == 'paid') {
            _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('ชำระเงินสำเร็จ'),
        content: Text('รายการ $_orderId ได้รับการชำระเงินเรียบร้อยแล้ว'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน PromptPay')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) const CircularProgressIndicator(),

              if (_qrPayload != null && !_isLoading) ...[
                Text(
                  'ยอดชำระ: $_amount THB',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ID: $_orderId',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // สแกนจ่ายด้วยแอปธนาคารไทยได้ทันที
                QrImageView(
                  data: _qrPayload!,
                  size: 240,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 20),
                Chip(
                  avatar: Icon(
                    _status == 'paid' ? Icons.check_circle : Icons.sync,
                    color: Colors.white,
                  ),
                  label: Text(
                    'สถานะ: $_status',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _status == 'paid'
                      ? Colors.green
                      : Colors.orange,
                ),
              ],

              if (_qrPayload == null && !_isLoading)
                ElevatedButton(
                  onPressed: _createBookingOrder,
                  child: const Text('จองตั๋วและสร้าง QR Code (2,500 บาท)'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
