import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/navbar/booking_history.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/page/navbar/profile.dart';
import 'package:triptour_app/page/SearchPage/searchPage.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';
import 'package:triptour_app/services/serverApi.dart';
import 'package:triptour_app/services/severGetApi.dart';

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

  // แสดงเฉพาะทัวร์ที่มีโปรโมชั่น
  List<dynamic> get promotionTours {
    final list = tours.where((tour) {
      final promotion = tour['promotion'];
      return promotion != null && promotion.toString().trim().isNotEmpty;
    }).toList();

    list.sort((a, b) {
      final aId = int.tryParse((a['tour_id'] ?? '0').toString()) ?? 0;
      final bId = int.tryParse((b['tour_id'] ?? '0').toString()) ?? 0;
      return bId.compareTo(aId);
    });

    return list;
  }

  List<dynamic> get recommendedTours {
    final list = [...tours];

    list.sort((a, b) {
      final aReview =
          int.tryParse(
            (a['review_count'] ?? a['reviews_count'] ?? a['reviewCount'] ?? 0)
                .toString(),
          ) ??
          0;
      final bReview =
          int.tryParse(
            (b['review_count'] ?? b['reviews_count'] ?? b['reviewCount'] ?? 0)
                .toString(),
          ) ??
          0;

      final compareReview = bReview.compareTo(aReview);
      if (compareReview != 0) return compareReview;

      final aRating =
          double.tryParse(
            (a['average_rating'] ?? a['rating'] ?? 0).toString(),
          ) ??
          0;
      final bRating =
          double.tryParse(
            (b['average_rating'] ?? b['rating'] ?? 0).toString(),
          ) ??
          0;

      return bRating.compareTo(aRating);
    });

    return list;
  }

  Map<String, List<dynamic>> get toursByCountry {
    final grouped = <String, List<dynamic>>{};

    for (final tour in tours) {
      final countryName =
          (tour['country_name_th'] ??
                  tour['country_name_en'] ??
                  tour['country'] ??
                  tour['country_id'] ??
                  'Other')
              .toString();
      final key = countryName.trim().isEmpty ? 'Other' : countryName;
      grouped.putIfAbsent(key, () => <dynamic>[]).add(tour);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    final result = <String, List<dynamic>>{};
    for (final entry in sortedEntries) {
      final sortedTours = [...entry.value];
      sortedTours.sort((a, b) {
        final aReview =
            int.tryParse(
              (a['review_count'] ?? a['reviews_count'] ?? a['reviewCount'] ?? 0)
                  .toString(),
            ) ??
            0;
        final bReview =
            int.tryParse(
              (b['review_count'] ?? b['reviews_count'] ?? b['reviewCount'] ?? 0)
                  .toString(),
            ) ??
            0;
        return bReview.compareTo(aReview);
      });
      result[entry.key] = sortedTours;
    }

    return result;
  }

  String formatRating(dynamic value) {
    final rating = double.tryParse(value?.toString() ?? '') ?? 0.0;
    return rating.toStringAsFixed(1);
  }

  String formatPrice(dynamic value) {
    final raw = value?.toString().replaceAll(',', '').trim() ?? '';
    if (raw.isEmpty || raw == '-') {
      return '0';
    }

    final price = double.tryParse(raw);
    if (price == null) {
      return raw;
    }

    if (price % 1 == 0) {
      return price.toInt().toString();
    }

    return price.toStringAsFixed(2);
  }

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
    if (result['statusCode'] != 200) {
      setState(() => isLoading = false);
      return;
    }

    final body = result['body'];
    if (body['success'] != true) {
      setState(() => isLoading = false);
      return;
    }

    final rawTours = List.from(body['data'] ?? []);
    final enrichedTours = await Future.wait(
      rawTours.map((tour) async {
        final tourId = int.tryParse((tour['tour_id'] ?? '').toString());
        if (tourId == null) {
          return {...tour, 'review_count': 0, 'average_rating': 0.0};
        }

        try {
          final reviewResult = await Severgetapi.getTourReview(tourId);
          final reviewBody = reviewResult['body'] ?? {};
          final reviewData = reviewBody['data'] ?? {};

          return {
            ...tour,
            'review_count':
                int.tryParse((reviewData['review_count'] ?? 0).toString()) ?? 0,
            'average_rating':
                double.tryParse(
                  (reviewData['average_rating'] ?? 0.0).toString(),
                ) ??
                0.0,
          };
        } catch (_) {
          return {...tour, 'review_count': 0, 'average_rating': 0.0};
        }
      }),
    );

    if (!mounted) return;

    setState(() {
      tours = enrichedTours;
      isLoading = false;
    });
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
    // final currentUser = FirebaseAuth.instance.currentUser;
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
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: IconButton(
                                onPressed: closeSearch,
                                icon: const Icon(Icons.close, size: 20),
                                splashRadius: 18,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isSearching)
                Positioned(
                  top: 75,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight > 0
                          ? constraints.maxHeight
                          : MediaQuery.of(context).size.height - 75;

                      return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: const Material(
                          color: Colors.white,
                          child: SearchPage(),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
      // floatingActionButton: currentUser != null
      //     ? FloatingActionButton(
      //         onPressed: sigout,
      //         backgroundColor: Colors.redAccent,
      //         child: const Icon(Icons.logout, color: Colors.white),
      //       )
      //     : FloatingActionButton.extended(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => const LoginPage()),
      //           );
      //         },
      //         backgroundColor: Colors.green,
      //         icon: const Icon(Icons.login, color: Colors.white),
      //         label: const Text(
      //           'เข้าสู่ระบบ',
      //           style: TextStyle(color: Colors.white),
      //         ),
      //       ),
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
                  Expanded(
                    child: Text(
                      "Trip Tour",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: const [
                  Icon(
                    Icons.local_offer_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ทัวร์ที่มีโปรโมชั่น",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildPromotionSection(),
              const SizedBox(height: 28),
              Row(
                children: const [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ทริปแนะนำ",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildTourSection(),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Icon(Icons.map_rounded, color: Colors.teal, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ทัวร์แต่ละประเทศ",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildCountryTourSection(),
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
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final promotions = promotionTours;

    if (promotions.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'ยังไม่มีทัวร์ที่มีโปรโมชั่นในตอนนี้',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final tour = promotions[index];
          final imageUrl = (tour['image'] ?? '').toString().trim();
          final promotion = tour['promotion'].toString().trim();

          return GestureDetector(
            onTap: () {
              final tourId = parseTourId(tour['tour_id']);
              if (tourId == null) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailTour(tourId: tourId),
                ),
              );
            },
            child: Container(
              width: 290,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (tour['tour_name'] ?? 'ไม่มีชื่อทริป').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              promotion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${formatPrice(tour['price'] ?? '-')} บาท',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

    final recommended = recommendedTours;
    if (recommended.isEmpty) {
      return const Center(child: Text("ยังไม่มีทริป"));
    }

    return SizedBox(
      height: 238,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommended.length,
        itemBuilder: (context, index) {
          final tour = recommended[index];
          final imageUrl = (tour['image'] ?? '').toString().trim();
          final reviewCount =
              int.tryParse(
                (tour['review_count'] ??
                        tour['reviews_count'] ??
                        tour['reviewCount'] ??
                        0)
                    .toString(),
              ) ??
              0;

          return Container(
            width: 180,
            height: 238,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                final tourId = parseTourId(tour['tour_id']);
                if (tourId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ข้อมูลทริปไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง',
                      ),
                    ),
                  );
                  return;
                }

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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Container(
                      height: 116,
                      width: double.infinity,
                      color: const Color(0xFFEDEDED),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 118,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 38,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image,
                                size: 38,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 38,
                            child: Text(
                              tour['tour_name'] ?? 'ไม่มีชื่อทริป',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatRating(tour['average_rating'] ?? 0.0),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.mode_comment_outlined,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$reviewCount',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'เริ่มต้น',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const Spacer(),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${formatPrice(tour['price'] ?? '-')} บาท',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget buildCountryTourSection() {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final countries = toursByCountry;
    if (countries.isEmpty) {
      return const Center(child: Text('ยังไม่มีทัวร์ตามประเทศ'));
    }

    return Column(
      children: countries.entries.map((entry) {
        final countryName = entry.key;
        final countryTours = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  countryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 182,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: countryTours.length,
                  itemBuilder: (context, index) {
                    final tour = countryTours[index];
                    final tourId = parseTourId(tour['tour_id']);
                    final imageUrl = (tour['image'] ?? '').toString().trim();

                    return GestureDetector(
                      onTap: () {
                        if (tourId == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailTour(tourId: tourId),
                          ),
                        );
                      },
                      child: Container(
                        width: 165,
                        height: 182,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Container(
                                height: 94,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 92,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 32,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      ),
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        formatRating(
                                          tour['average_rating'] ?? 0.0,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.mode_comment_outlined,
                                        size: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${int.tryParse((tour['review_count'] ?? tour['reviews_count'] ?? tour['reviewCount'] ?? 0).toString()) ?? 0}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 18,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'เริ่มต้น',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '${formatPrice(tour['price'] ?? '-')} บาท',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
