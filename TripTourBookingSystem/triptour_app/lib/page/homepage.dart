import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';
import 'package:triptour_app/page/navbar/booking_history.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/page/navbar/profile.dart';
import 'package:triptour_app/page/SearchPage/searchPage.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';
import 'package:triptour_app/serverApi.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  List<dynamic> tours = [];
  bool isLoading = true;
  bool isSearching = false;
  String _memberId = '';
  @override
  void initState() {
    super.initState();
    loadTours();
    loadData();
  }

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return;

    try {
      final detail = await Serverapi.getMemberDetail(user);
      if (mounted && detail != null) {
        final memberId = detail['member_id'] ?? detail['id'];
        setState(() {
          _memberId = memberId?.toString() ?? user;
        });
      } else {
        if (mounted) setState(() => _memberId = user);
      }
    } catch (e) {
      if (mounted) setState(() => _memberId = user);
    }
  }

  Future<void> loadTours() async {
    final result = await Serverapi.getTours();
    if (result['statusCode'] == 200) {
      final body = result['body'];
      if (body['success'] == true) {
        setState(() {
          tours = body['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void openSearch() {
    if (isSearching) return;
    setState(() => isSearching = true);
  }

  void closeSearch() {
    setState(() => isSearching = false);
  }

  Future<void> sigout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (!mounted) return;
      setState(() {
        _selectedIndex = 0; // รีเซ็ตกลับไปหน้า Home
        _memberId = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ออกจากระบบเรียบร้อย')));
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('เข้าสู่ระบบ'),
        content: const Text(
          'กรุณาเข้าสู่ระบบก่อนใช้งานส่วนนี้หรือทำการจองทัวร์',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // หน้า Home (index 0) ให้เปิดดูได้โดยไม่ต้องล็อกอิน
    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }

    // หากเปิดหน้าล้วยังไม่ได้ล็อกอิน ให้เด้งเตือน
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    // รวมรายการหน้าทั้งหมด โดยหน้า 0 คือเนื้อหา Home
    final List<Widget> pages = [
      _buildHomeContent(),
      BookingHistoryPage(memberId: _memberId),
      const ChatPage(userRole: 'user'),
      const ProfilePage(),
    ];

    //test

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // สลับหน้าตาม _selectedIndex
            IndexedStack(index: _selectedIndex, children: pages),

            // แสดง Search Box และ SearchPage เฉพาะเมื่ออยู่หน้า Home (Index 0)
            if (_selectedIndex == 0) ...[
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                top: isSearching ? 10 : 300,
                left: 12,
                right: 12,
                child: GestureDetector(
                  onTap: openSearch, // เพิ่มการกดเพื่อเปิด Search
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
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
              ),
              if (isSearching)
                const Positioned(
                  top: 75,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SearchPage(),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap:
            _onItemTapped, // 🟢 เปลี่ยนมาเรียกใช้ฟังก์ชันดักจับที่เขียนขึ้นใหม่
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.greenAccent,
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.lightGreen,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Booking",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: sigout,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.logout, color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  // แยก Widget ส่วนเนื้อหาหน้า Home ออกมา
  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: loadTours,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.travel_explore, color: Colors.green, size: 35),
                  SizedBox(width: 8),
                  Text(
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
              const Text(
                "ประกาศข่าว",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              buildPromotionSection(),
              const SizedBox(height: 80), // เว้นพื้นที่สำหรับ Search Box
              const Text(
                "ทริปแนะนำ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              buildTourSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPromotionSection() {
    if (isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }
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
                  Text(
                    "${tour['duration_day'] ?? '-'} วัน",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
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

  Widget buildTourSection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tours.isEmpty) {
      return const Center(child: Text("ยังไม่มีทริป"));
    }

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
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final int tourId = int.parse(tour['tour_id'].toString());

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTour(tourId: tourId),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour['tour_name'] ?? 'ไม่มีชื่อทริป',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "${tour['duration_day'] ?? '-'} วัน",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),

                        const SizedBox(height: 5),

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
            ),
          );
        },
      ),
    );
  }
}
