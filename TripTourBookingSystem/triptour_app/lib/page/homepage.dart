import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/loginPage.dart';
import 'package:triptour_app/page/searchPage.dart';
import 'package:triptour_app/serverApi.dart';

// Homepage เป็น StatefulWidget เพราะเราจะโหลดข้อมูลจาก API แล้วอัปเดต UI
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  //late Future<List<dynamic>>
  //tours; // ตัวแปร Future สำหรับเก็บข้อมูลทัวร์จาก API
  final user = FirebaseAuth.instance.currentUser;

  // =====================================================
  // ข้อมูลทริป
  // =====================================================

  List<dynamic> tours = [];
  bool isLoading = true;

  // =====================================================
  // Search
  // =====================================================

  bool isSearching = false;

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();

    loadTours();
  }

  // =====================================================
  // ดึงข้อมูลทริปจาก Backend
  // =====================================================

  Future<void> loadTours() async {
    final result = await Serverapi.getTours();

    print("Homepage tours: $result");

    if (result['statusCode'] == 200) {
      final body = result['body'];

      if (body['success'] == true) {
        setState(() {
          tours = body['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // เปิด Search
  // =====================================================

  void openSearch() {
    if (isSearching) {
      return;
    }

    setState(() {
      isSearching = true;
    });
  }

  // =====================================================
  // ปิด Search
  // =====================================================

  void closeSearch() {
    setState(() {
      isSearching = false;
    });
  }

  // =====================================================
  // Logout
  // =====================================================

  Future<void> sigout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    super.dispose();
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Stack(
          children: [
            // =================================================
            // Homepage หลัก
            // =================================================
            Column(
              children: [
                // =============================================
                // ส่วนเนื้อหา
                // =============================================
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadTours,

                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // =================================
                            // Logo
                            // =================================
                            Row(
                              children: [
                                const Icon(
                                  Icons.travel_explore,
                                  color: Colors.green,
                                  size: 35,
                                ),

                                const SizedBox(width: 8),

                                const Text(
                                  "Trip Tour",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            // =================================
                            // ส่วนที่ 1
                            // ทริป / โปรโมชั่นชั่วคราว
                            // =================================
                            const Text(
                              "ประกาศข่าว",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            buildPromotionSection(),

                            const SizedBox(height: 20),

                            // =================================
                            // ส่วนที่ 2
                            // Search
                            // =================================

                            // เว้นพื้นที่สำหรับ Search Box
                            // เนื่องจาก Search Box จริงอยู่ใน Stack
                            const SizedBox(height: 60),

                            const SizedBox(height: 15),

                            // =================================
                            // ส่วนที่ 3
                            // ทริปแนะนำ
                            // =================================
                            const Text(
                              "ทริปแนะนำ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            buildTourSection(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // =============================================
                // ส่วนที่ 4
                // Navbar
                // =============================================
                buildBottomNavbar(),
              ],
            ),

            // =================================================
            // Search Box
            // =================================================
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,

              top: isSearching ? 10 : 300,

              left: 12,
              right: 12,

              child: Material(
                elevation: isSearching ? 6 : 2,
                borderRadius: BorderRadius.circular(12),

                child: Container(
                  height: 52,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: Colors.green),
                  ),

                  child: Row(
                    children: [
                      const SizedBox(width: 16),

                      const Icon(Icons.search, color: Colors.grey),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'ค้นหาทริป',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      ),

                      // =====================================
                      // ปุ่ม X ตอนเปิด Search
                      // =====================================
                      if (isSearching)
                        IconButton(
                          onPressed: closeSearch,
                          icon: const Icon(Icons.close),
                        ),

                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),

            // =================================================
            // หน้าค้นหา
            // =================================================
            if (isSearching)
              const Positioned(
                top: 75,
                left: 0,
                right: 0,
                bottom: 0,
                child: SearchPage(),
              ),
          ],
        ),
      ),

      // =====================================================
      // Logout ชั่วคราว
      // =====================================================
      floatingActionButton: FloatingActionButton(
        onPressed: sigout,

        child: const Icon(Icons.logout),
      ),
    );
  }

  // =====================================================
  // ส่วนที่ 1
  // แสดงทริปด้านบนแทน Promotion
  // =====================================================

  Widget buildPromotionSection() {
    // กำลังโหลด
    if (isLoading) {
      return const SizedBox(
        height: 150,

        child: Center(child: CircularProgressIndicator()),
      );
    }

    // ยังไม่มีข้อมูล
    if (tours.isEmpty) {
      return Container(
        height: 150,

        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.grey.shade200,

          borderRadius: BorderRadius.circular(12),
        ),

        child: const Center(child: Text("ยังไม่มีข้อมูลทริป")),
      );
    }

    // มีข้อมูลทริป
    return SizedBox(
      height: 160,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        itemCount: tours.length,

        itemBuilder: (context, index) {
          final tour = tours[index];

          return Container(
            width: 280,

            margin: const EdgeInsets.only(right: 12),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),

              color: Colors.grey.shade200,
            ),

            child: Padding(
              padding: const EdgeInsets.all(15),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  // ชื่อทริป
                  Text(
                    tour['tour_name'] ?? 'ไม่มีชื่อทริป',

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // จำนวนวัน
                  Text(
                    "${tour['duration_day'] ?? '-'} วัน",

                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 5),

                  // ราคา
                  Text(
                    "${tour['price'] ?? '-'} บาท",

                    style: const TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // ส่วนที่ 3
  // แสดงรายการทริป
  // =====================================================

  Widget buildTourSection() {
    // กำลังโหลด
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ไม่มีทริป
    if (tours.isEmpty) {
      return const Center(child: Text("ยังไม่มีทริป"));
    }

    // มีทริป
    return SizedBox(
      height: 220,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        itemCount: tours.length,

        itemBuilder: (context, index) {
          final tour = tours[index];

          return Container(
            width: 180,

            margin: const EdgeInsets.only(right: 12),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: Colors.grey.shade300),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================
                // รูปภาพชั่วคราว
                // =================================
                Container(
                  height: 100,

                  width: double.infinity,

                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),

                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),

                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),

                // =================================
                // ข้อมูลทริป
                // =================================
                Padding(
                  padding: const EdgeInsets.all(8),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ชื่อทริป
                      Text(
                        tour['tour_name'] ?? 'ไม่มีชื่อทริป',

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),

                      // จำนวนวัน
                      Text(
                        "${tour['duration_day'] ?? '-'} วัน",

                        style: TextStyle(color: Colors.grey.shade600),
                      ),

                      const SizedBox(height: 5),

                      // ราคา
                      Text(
                        "${tour['price'] ?? '-'} บาท",

                        style: const TextStyle(
                          color: Colors.orange,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // ส่วนที่ 4
  // Navbar UI อย่างเดียว
  // =====================================================

  Widget buildBottomNavbar() {
    return Container(
      height: 65,

      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),

        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          buildNavItem(Icons.home, "Home", true),

          buildNavItem(Icons.chat_bubble, "Chat", false),

          buildNavItem(Icons.receipt_long, "Booking", false),

          buildNavItem(Icons.person, "Profile", false),
        ],
      ),
    );
  }

  // =====================================================
  // Navbar Item
  // =====================================================

  Widget buildNavItem(IconData icon, String title, bool selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Icon(icon, size: 27, color: selected ? Colors.black : Colors.grey),

        Text(
          title,

          style: TextStyle(
            fontSize: 11,

            color: selected ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}
