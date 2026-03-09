import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/loginPage.dart';
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

  sigout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
        result: (route) => false,
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    tours = Serverapi.getTours(); // เรียก API ตอนเริ่มต้น
  }

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
}

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
        // รูปภาพทัวร์
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 120,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),

        // ข้อมูลทัวร์
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
                  "เริ่มต้น ฿1000", // ตัวอย่างข้อความเพิ่มเติม
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
