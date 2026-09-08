import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  late Future<List<dynamic>>
  tours; // ตัวแปร Future สำหรับเก็บข้อมูลทัวร์จาก API
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    HomeContentTab(), // Index 0: หน้า Home (ดึง API)
    Center(child: Text("Booking Page")), // Index 1: หน้า Booking
    ChatPage(userRole: 'user'), // Index 2: หน้า Chat
    Center(child: Text("Profile Page")), // Index 3: หน้า Profile
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // มี body เพียงอันเดียวโดยใช้ IndexedStack
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Booking",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        backgroundColor: Colors.greenAccent,
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.lightGreen,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: sigout,
        child: const Icon(Icons.login_rounded),
      ),
    );
  }
}

class HomeContentTab extends StatefulWidget {
  const HomeContentTab({super.key});

  @override
  State<HomeContentTab> createState() => _HomeContentTabState();
}

class _HomeContentTabState extends State<HomeContentTab> {
  late Future<List<dynamic>> tours;

  @override
  void initState() {
    super.initState();
    tours = Serverapi.getTours();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: tours,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final data = snapshot.data ?? [];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LOGO
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
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

                  /// TOUR LIST
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final tour = data[index];
                      return tourCard(
                        name: tour["tour_name"] ?? "",
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
    );
  }
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(price, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                const Text(
                  "เริ่มต้น ฿1000",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
