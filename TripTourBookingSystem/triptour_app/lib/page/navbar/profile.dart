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
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blueGrey),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          displayValue(value),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // หัวข้อแต่ละ Section
  // ==========================================================
  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
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

    return Column(
      children: [
        const SizedBox(height: 15),

        CircleAvatar(
          radius: 55,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: hasProfileImage ? NetworkImage(profileImage) : null,
          child: hasProfileImage
              ? null
              : const Icon(Icons.person, size: 55, color: Colors.white),
        ),

        const SizedBox(height: 12),

        Text(
          fullName == '- -' ? 'ไม่ระบุชื่อ' : fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        Chip(
          label: Text(
            role.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: Colors.blueGrey,
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: 180,
          child: OutlinedButton.icon(
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

              // ถ้าบันทึกสำเร็จ
              if (result == true && mounted) {
                await loadProfile();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไขข้อมูล'),
          ),
        ),

        const SizedBox(height: 15),
      ],
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
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.greenAccent,
        actions: [
          IconButton(
            onPressed: sigout,
            icon: const Icon(Icons.refresh),
            tooltip: 'โหลดข้อมูลใหม่',
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildProfileHeader(),

                    const Divider(height: 10),

                    buildPersonalSection(),

                    buildFavoriteCountrySection(),

                    buildHealthSection(),

                    buildDocumentSection(),

                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: sigout,
                        icon: const Icon(Icons.logout),
                        label: const Text('ออกจากระบบ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: inactiveAccount,
                        child: const Text(
                          'ลบบัญชีผู้ใช้',
                          style: TextStyle(color: Colors.red),
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
