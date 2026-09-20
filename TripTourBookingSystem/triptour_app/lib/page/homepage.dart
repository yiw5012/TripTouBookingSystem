import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/page/searchPage.dart';
import 'package:triptour_app/page/detailTour.dart';
import 'package:triptour_app/serverApi.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  List<dynamic> tours = [];
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    loadTours();
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // รวมรายการหน้าทั้งหมด โดยหน้า 0 คือเนื้อหา Home
    final List<Widget> pages = [
      _buildHomeContent(),
      const Center(child: Text("booking Page")),
      const ChatPage(userRole: 'user'),
      const Center(child: Text("Profile Page")),
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
      floatingActionButton: FloatingActionButton(
        onPressed: sigout,
        child: const Icon(Icons.logout),
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
