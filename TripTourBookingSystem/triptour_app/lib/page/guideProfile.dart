import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/editGuideProfile.dart';
import 'package:triptour_app/serverApi.dart';

class GuideProfile extends StatefulWidget {
  const GuideProfile({super.key});

  @override
  State<GuideProfile> createState() => _GuideProfileState();
}

class _GuideProfileState extends State<GuideProfile> {
  // ==========================================================
  // GUIDE DATA
  // ==========================================================

  Map<String, dynamic>? guide;

  // ==========================================================
  // STATE
  // ==========================================================

  bool isLoading = true;
  String? errorMessage;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadGuideProfile();
  }

  // ==========================================================
  // LOAD GUIDE PROFILE
  // ==========================================================

  Future<void> loadGuideProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    // ========================================================
    // CHECK LOGIN
    // ========================================================

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'กรุณาเข้าสู่ระบบก่อน';
      });

      return;
    }

    // ========================================================
    // START LOADING
    // ========================================================

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // ======================================================
      // GET GUIDE PROFILE
      // ======================================================

      final result = await Serverapi.getGuideProfile(googleId: user.uid);

      if (!mounted) return;

      // ======================================================
      // SUCCESS
      // ======================================================

      if (result['statusCode'] == 200 &&
          result['body'] != null &&
          result['body']['success'] == true) {
        final data = result['body']['data'];

        if (data is Map<String, dynamic>) {
          setState(() {
            guide = data;
            isLoading = false;
            errorMessage = null;
          });

          debugPrint('Guide profile loaded: $guide');
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'รูปแบบข้อมูลไกด์ไม่ถูกต้อง';
          });
        }
      }
      // ======================================================
      // FAILED
      // ======================================================
      else {
        setState(() {
          isLoading = false;
          errorMessage = result['body']?['message'] ?? 'ไม่พบข้อมูลไกด์';
        });

        debugPrint('Get guide profile failed: ${result['body']}');
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Load guide profile error: $e');

      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    }
  }

  // ==========================================================
  // GET FULL NAME
  // ==========================================================

  String getFullName() {
    final String firstName = guide?['first_name']?.toString().trim() ?? '';

    final String lastName = guide?['last_name']?.toString().trim() ?? '';

    final String fullName = '$firstName $lastName'.trim();

    if (fullName.isEmpty) {
      return 'ยังไม่ได้ระบุชื่อ';
    }

    return fullName;
  }

  // ==========================================================
  // GET VALUE OR DASH
  // ==========================================================

  String getValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

    return text;
  }

  // ==========================================================
  // FORMAT BIRTHDAY
  // ==========================================================

  String formatBirthday(dynamic value) {
    if (value == null) {
      return '-';
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

    // ========================================================
    // YYYY-MM-DD
    // ========================================================

    if (text.length >= 10) {
      final String dateText = text.substring(0, 10);

      final List<String> parts = dateText.split('-');

      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    return text;
  }

  // ==========================================================
  // EDIT PROFILE
  // ==========================================================

  Future<void> openEditProfile() async {
    if (guide == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditGuideProfile(guide: guide!)),
    );

    // ========================================================
    // RELOAD AFTER EDIT
    // ========================================================

    if (result == true) {
      await loadGuideProfile();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text(
          'โปรไฟล์ไกด์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        actions: [
          IconButton(
            onPressed: isLoading ? null : openEditProfile,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'แก้ไขข้อมูลส่วนตัว',
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? buildError()
          : guide == null
          ? const Center(child: Text('ไม่พบข้อมูลไกด์'))
          : buildProfile(),
    );
  }

  // ==========================================================
  // BUILD PROFILE
  // ==========================================================

  Widget buildProfile() {
    final String imageProfile = getValue(guide?['image_profile']);

    final String guideCode = getValue(guide?['guide_code']);

    final String firstName = getValue(guide?['first_name']);

    final String lastName = getValue(guide?['last_name']);

    final String email = getValue(guide?['email']);

    final String age = getValue(guide?['age']);

    final String phone = getValue(guide?['phone']);

    final String address = getValue(guide?['address']);

    final String status = getValue(guide?['status']);

    return RefreshIndicator(
      onRefresh: loadGuideProfile,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

        child: Column(
          children: [
            // ==================================================
            // PROFILE IMAGE
            // ==================================================
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.amber,

              backgroundImage: imageProfile != '-'
                  ? NetworkImage(imageProfile)
                  : null,

              child: imageProfile == '-'
                  ? const Icon(Icons.explore, size: 62, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 18),

            // ==================================================
            // FULL NAME
            // ==================================================
            Text(
              getFullName(),
              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // ==================================================
            // GUIDE CODE
            // ==================================================
            Text(
              'รหัสไกด์: $guideCode',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // INFORMATION CARD
            // ==================================================
            Card(
              elevation: 1,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),

              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  children: [
                    // ========================================
                    // FIRST NAME
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      title: 'ชื่อ',
                      value: firstName,
                    ),

                    const Divider(),

                    // ========================================
                    // LAST NAME
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      title: 'นามสกุล',
                      value: lastName,
                    ),

                    const Divider(),

                    // ========================================
                    // EMAIL
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      title: 'อีเมล',
                      value: email,
                    ),

                    const Divider(),

                    // ========================================
                    // BIRTHDAY
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.cake_outlined,
                      title: 'วันเกิด',
                      value: formatBirthday(guide?['birthday']),
                    ),

                    const Divider(),

                    // ========================================
                    // AGE
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.numbers_outlined,
                      title: 'อายุ',
                      value: age,
                    ),

                    const Divider(),

                    // ========================================
                    // PHONE
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      title: 'เบอร์โทรศัพท์',
                      value: phone,
                    ),

                    const Divider(),

                    // ========================================
                    // ADDRESS
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.home_outlined,
                      title: 'ที่อยู่',
                      value: address,
                    ),

                    const Divider(),

                    // ========================================
                    // STATUS
                    // ========================================
                    _buildInfoRow(
                      icon: Icons.circle,
                      title: 'สถานะ',
                      value: status,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // EDIT BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton.icon(
                onPressed: openEditProfile,

                icon: const Icon(Icons.edit),

                label: const Text('แก้ไขข้อมูลส่วนตัว'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,

                  foregroundColor: Colors.black,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INFO ROW
  // ==========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: Colors.amber.shade50,

            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, color: Colors.amber.shade700),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, size: 55, color: Colors.grey),

            const SizedBox(height: 14),

            Text(errorMessage ?? 'เกิดข้อผิดพลาด', textAlign: TextAlign.center),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: loadGuideProfile,

              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
