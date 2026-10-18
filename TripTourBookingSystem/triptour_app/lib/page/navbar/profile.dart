import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/homepage.dart';
import 'package:triptour_app/services/serverApi.dart';
import 'package:triptour_app/page/navbar/editprofile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? memberData;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> sigout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ออกจากระบบเรียบร้อย')));
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // ==========================================================
  // โหลดข้อมูล Profile ของผู้ใช้ปัจจุบัน
  // ==========================================================
  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      // ยังไม่ได้ Login
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'ไม่พบผู้ใช้งาน';
        });
        return;
      }

      // Firebase UID
      final String uid = user.uid;

      debugPrint('Profile UID: $uid');

      final result = await Serverapi.getMemberDetail(uid);

      if (!mounted) return;

      // โหลดข้อมูลสำเร็จ
      if (result != null) {
        setState(() {
          memberData = result;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'ไม่พบข้อมูลสมาชิก';
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Load profile error: $e');

      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    }
  }

  Future<void> inactiveAccount() async {
    // แสดง Dialog ยืนยันการลบบัญชี
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบบัญชี'),
        content: const Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีผู้ใช้นี้?\n\n'
          'บัญชีของคุณจะถูกปิดใช้งาน และจะไม่สามารถเข้าสู่ระบบได้อีกต่อไป',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),

            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้งาน')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 2. เรียก API ลบบัญชี (Soft Delete)
      final res = await Serverapi.InactiveService(user.uid);

      if (!mounted) return;

      if (res['statusCode'] == 200 && res['body']?['success'] == true) {
        // ถ้าสำเร็จ ทำการ ออกจากระบบ (Firebase + Google)
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบบัญชีผู้ใช้เรียบร้อยแล้ว')),
        );
        Get.offAll(() => const Homepage());
      } else {
        // หากติดเงื่อนไข (เช่น มียอดจอง status = pending/confirmed AND payment_status = paid)
        final String errorMsg =
            res['body']?['message'] ?? 'ไม่สามารถลบบัญชีได้';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบบัญชี: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // ดึงข้อความ ถ้าไม่มีข้อมูลให้เป็น -
  // ==========================================================
  String displayValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    return text;
  }

  // ==========================================================
  // แสดงข้อมูลเป็น Card
  // ==========================================================
  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required dynamic value,
    Color? iconColor,
  }) {
    final Color resolvedColor = iconColor ?? const Color(0xFF0F766E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: resolvedColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: resolvedColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue(value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // หัวข้อแต่ละ Section
  // ==========================================================
  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Profile Header
  // ==========================================================
  Widget buildProfileHeader() {
    final String firstName = displayValue(memberData?['first_name']);

    final String lastName = displayValue(memberData?['last_name']);

    final String fullName = '$firstName $lastName'.trim();

    final String profileImage = displayValue(memberData?['image_profile']);

    final String role = displayValue(memberData?['role']);

    final bool hasProfileImage = profileImage != '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: const Color(0xFFD1FAE5),
            backgroundImage: hasProfileImage
                ? NetworkImage(profileImage)
                : null,
            child: hasProfileImage
                ? null
                : const Icon(Icons.person, size: 52, color: Color(0xFF0F766E)),
          ),
          const SizedBox(height: 14),
          Text(
            fullName == '- -' ? 'ไม่ระบุชื่อ' : fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 190,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (memberData == null) {
                  return;
                }

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfilePage(memberData: memberData!),
                  ),
                );

                if (result == true && mounted) {
                  await loadProfile();
                }
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('แก้ไขข้อมูล'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Section ข้อมูลส่วนตัว
  // ==========================================================
  Widget buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('ข้อมูลส่วนตัว'),

        buildInfoCard(
          icon: Icons.email,
          title: 'อีเมล',
          value: memberData?['email'],
        ),

        buildInfoCard(
          icon: Icons.phone,
          title: 'เบอร์โทรศัพท์',
          value: memberData?['phone'],
        ),

        buildInfoCard(
          icon: Icons.wc,
          title: 'เพศ',
          value: memberData?['gender'],
        ),

        buildInfoCard(
          icon: Icons.cake,
          title: 'วันเกิด',
          value: memberData?['birthday'],
        ),

        buildInfoCard(
          icon: Icons.home,
          title: 'ที่อยู่',
          value: memberData?['address'],
        ),
      ],
    );
  }

  // ==========================================================
  // Section ประเทศที่ชอบ
  // ==========================================================
  Widget buildFavoriteCountrySection() {
    final dynamic countries = memberData?['favorite_countries'];
    print(countries);
    if (countries == null) {
      return const SizedBox();
    }

    String countryText = '-';
    if (countries is List) {
      if (countries.isNotEmpty) {
        final names = countries
            .map((item) {
              if (item is Map) {
                final nameEn = item['country_name_en']?.toString().trim() ?? '';
                final nameTh = item['country_name_th']?.toString().trim() ?? '';
                return nameEn.isNotEmpty ? nameEn : nameTh;
              }
              return item.toString();
            })
            .where((name) => name.isNotEmpty)
            .toList();

        countryText = names.isEmpty ? '-' : names.join(', ');
      }
    } else {
      countryText = countries.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('ประเทศที่ชอบ'),

        buildInfoCard(
          icon: Icons.public,
          title: 'ประเทศที่เลือก',
          value: countryText,
          iconColor: Colors.green,
        ),
      ],
    );
  }

  // ==========================================================
  // Section ข้อมูลสุขภาพ
  // ==========================================================
  Widget buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('ข้อมูลสุขภาพ'),

        buildInfoCard(
          icon: Icons.medical_information,
          title: 'โรคประจำตัว',
          value: memberData?['congenital_disease'],
        ),

        buildInfoCard(
          icon: Icons.medication,
          title: 'ยาที่ใช้ประจำ',
          value: memberData?['medicine'],
        ),

        buildInfoCard(
          icon: Icons.warning_amber_rounded,
          title: 'ประวัติการแพ้ยา/อาหาร',
          value: memberData?['allergic_list'],
          iconColor: Colors.red,
        ),

        buildInfoCard(
          icon: Icons.note,
          title: 'ข้อมูลเพิ่มเติม',
          value: memberData?['others'],
        ),
      ],
    );
  }

  // ==========================================================
  // Section เอกสาร
  // ==========================================================
  Widget buildDocumentSection() {
    final String passportImage = displayValue(memberData?['image_passport']);

    final bool hasPassportImage = passportImage != '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('เอกสารประจำตัว'),

        buildInfoCard(
          icon: Icons.badge,
          title: 'เลขบัตรประชาชน / พาสปอร์ต',
          value: memberData?['number_id'],
        ),

        if (hasPassportImage) ...[
          const SizedBox(height: 10),

          const Text(
            'รูปเอกสาร',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              passportImage,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Center(child: Text('โหลดรูปเอกสารไม่สำเร็จ')),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        centerTitle: true,
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: sigout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: loadProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            )
          : memberData == null
          ? const Center(child: Text('ไม่พบข้อมูลสมาชิก'))
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildProfileHeader(),
                    buildPersonalSection(),
                    buildFavoriteCountrySection(),
                    buildHealthSection(),
                    buildDocumentSection(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: sigout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('ออกจากระบบ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF111827),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: inactiveAccount,
                        child: const Text(
                          'ลบบัญชีผู้ใช้',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
