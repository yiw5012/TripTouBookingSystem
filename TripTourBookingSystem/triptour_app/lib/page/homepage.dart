import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/loginPage.dart';
import 'package:triptour_app/page/searchPage.dart';
import 'package:triptour_app/serverApi.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/page/wrapper.dart';
import 'package:triptour_app/serverApi.dart'; // import service ที่เรียก API backend

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
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    HomeContentTab(), // Index 0: หน้า Home (ดึง API)
    Center(child: Text("Booking Page")), // Index 1: หน้า Booking
    ChatPage(userRole: 'user'), // Index 2: หน้า Chat
    Center(child: Text("Profile Page")), // Index 3: หน้า Profile
  ];

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
  Future<void> sigout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
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
      // แถบ navigation ด้านล่าง
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Booking",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      // เนื้อหาในหน้า
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          // ใช้ FutureBuilder โหลดข้อมูลจาก API
          future: tours,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // กำลังโหลด → แสดงวงกลมหมุน
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // ถ้า error → แสดงข้อความ error
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              // ถ้าโหลดเสร็จ → แสดงข้อมูล
              final data = snapshot.data ?? [];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// LOGO
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          Icon(Icons.travel_explore, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Trip Tour",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// SEARCH BAR
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "search trip",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),

                    /// TITLE "Popular"
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "Popular",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    /// TOUR LIST จาก API
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final tour = data[index];
                        return tourCard(
                          name: tour["tour_name"],
                          price: tour["price"].toString(),
                          imageUrl:
                              tour["imageUrl"] ?? "https://picsum.photos/200",
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => sigout(),
        child: const Icon(Icons.login_rounded),
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

}

// 3. Tour Card Widget
Widget tourCard({
  required String name,
  required String price,
  required String imageUrl,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        ClipRRect(
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

          child: Image.network(
            imageUrl,
            width: 120,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
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
