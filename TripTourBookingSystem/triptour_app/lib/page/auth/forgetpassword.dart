import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/services/serverApi.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  final emailCtl = TextEditingController();
  final otpCtl = TextEditingController();
  final newPasswordCtl = TextEditingController();
  final confirmPasswordCtl = TextEditingController();
  bool _isSubmitting = false;
  int _currentStep = 0;

  final List<String> _steps = ['อีเมล', 'OTP', 'รหัส', 'เสร็จสิ้น'];

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final email = emailCtl.text.trim();
    if (email.isEmpty) {
      _showSnack('กรุณากรอกอีเมล');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final otpSent = await Serverapi.sendOtp(email);
      if (!mounted) return;

      if (!otpSent) {
        _showSnack('ไม่สามารถส่ง OTP ได้ กรุณาลองอีกครั้ง');
        return;
      }

      setState(() {
        _currentStep = 1;
        otpCtl.clear();
      });
      _showSnack('ส่ง OTP แล้ว กรุณาตรวจสอบอีเมล');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = otpCtl.text.trim();
    if (otp.length != 6) {
      _showSnack('กรุณากรอ OTP ให้ครบ 6 หลัก');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final verified = await Serverapi.verifyOtp(emailCtl.text.trim(), otp);
      if (!mounted) return;

      if (!verified) {
        _showSnack('OTP ไม่ถูกต้อง');
        return;
      }

      setState(() => _currentStep = 2);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = newPasswordCtl.text.trim();
    final confirmPassword = confirmPasswordCtl.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnack('กรุณากรอรหัสผ่านให้ครบ');
      return;
    }

    if (newPassword.length < 6) {
      _showSnack('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnack('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await Serverapi.resetpassword(
        emailCtl.text.trim(),
        newPassword,
      );

      if (!mounted) return;

      if (result) {
        setState(() => _currentStep = 3);
        _showSnack('เปลี่ยนรหัสผ่านสำเร็จ');
      } else {
        _showSnack('ไม่สามารถเปลี่ยนรหัสผ่านได้ กรุณาลองอีกครั้ง');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStepItem(int index, String label) {
    final active = _currentStep >= index;
    final completed = _currentStep > index;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: completed || active
                  ? const Color(0xFF1FAE5B)
                  : Colors.white,
              border: Border.all(
                color: completed || active
                    ? const Color(0xFF1FAE5B)
                    : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: (completed || active)
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1FAE5B).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: completed || active
                      ? Colors.white
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF1B8E4B) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    return Row(
      children: List.generate(_steps.length, (index) {
        if (index < _steps.length - 1) {
          return Expanded(
            child: Row(
              children: [
                _buildStepItem(index, _steps[index]),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _currentStep > index
                            ? [const Color(0xFF1FAE5B), const Color(0xFF1FAE5B)]
                            : [Colors.grey.shade300, Colors.grey.shade300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildStepItem(index, _steps[index]);
      }),
    );
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'อีเมลของคุณ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+-]')),
              ],
              decoration: InputDecoration(
                hintText: 'example@email.com',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF1FAE5B),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _sendOtp,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ส่ง OTP'),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ใส่รหัส OTP',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'เราได้ส่งรหัสยืนยัน 6 หลักไปที่ ${emailCtl.text.trim()}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpCtl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'OTP 6 หลัก',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => setState(() => _currentStep = 0),
                    child: const Text('กลับ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF1FAE5B),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _verifyOtp,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ยืนยัน OTP'),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ตั้งรหัสผ่านใหม่',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordCtl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'รหัสผ่านใหม่',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordCtl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'ยืนยันรหัสผ่านใหม่',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_reset_rounded),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF1FAE5B),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _resetPassword,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ยืนยัน'),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'รีเซ็ตรหัสผ่านสำเร็จ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'คุณสามารถเข้าสู่ระบบด้วยรหัสผ่านใหม่ได้ทันที',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF1FAE5B),
                  elevation: 0,
                ),
                onPressed: () => Get.offAll(() => const Wrapper()),
                child: const Text('กลับสู่หน้าเข้าสู่ระบบ'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.green.shade50, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1FAE5B).withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          'ลืมรหัสผ่าน',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'กู้คืนรหัสผ่านให้เร็วและปลอดภัย',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStepProgress(),
                        const SizedBox(height: 22),
                        _buildContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
