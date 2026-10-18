import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triptour_app/page/auth/loginPage.dart';
import 'package:triptour_app/page/navbar/booking_history.dart';
import 'package:triptour_app/page/navbar/chat.dart';
import 'package:triptour_app/page/navbar/profile.dart';
import 'package:triptour_app/page/SearchPage/searchPage.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';
import 'package:triptour_app/services/serverApi.dart';
import 'package:triptour_app/services/severGetApi.dart';

// ---------- Design tokens ----------
const kPrimary = Color(0xFF10B981); // Emerald Green
const kPrimaryDark = Color(
  0xFF047857,
); // ใช้กับตัวอักษร/ไอคอนบนพื้นขาว (contrast ผ่าน)
const kInk = Color(0xFF111827); // Dark Slate
const kSale = Color(0xFFEF4444); // Coral Red
const kSaleDark = Color(0xFFDC2626); // ใช้เป็นพื้น Badge ที่มีตัวอักษรขาว
const kBg = Color(0xFFF9FAFB); // Off-White
const kMuted = Color(0xFF4B5563);

List<BoxShadow> get kCardShadow => [
  BoxShadow(
    color: Colors.black.withOpacity(0.07),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

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
  String _displayName = '';
  String _photoUrl = '';

  // ต่อกับ API แจ้งเตือนสถานะการจอง (สลิปผ่าน/อนุมัติ)
  // int _notificationCount = 0;

  // หมวดหมู่ที่เลือก: null = ทั้งหมด
  String? _selectedCategory;

  // Promo carousel
  final PageController _promoController = PageController();
  int _promoIndex = 0;
  Timer? _promoTimer;

  // แสดงเฉพาะทัวร์ที่ยังเปิดอยู่
  bool _isVisibleTour(dynamic tour) {
    final status = (tour['status'] ?? '').toString().trim().toLowerCase();
    if (status == 'closed') {
      return false;
    }
    return true;
  }

  List<dynamic> get promotionTours {
    final list = tours.where((tour) {
      if (!_isVisibleTour(tour)) return false;
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

  int _reviewCountOf(dynamic t) =>
      int.tryParse(
        (t['review_count'] ?? t['reviews_count'] ?? t['reviewCount'] ?? 0)
            .toString(),
      ) ??
      0;

  double _ratingOf(dynamic t) =>
      double.tryParse((t['average_rating'] ?? t['rating'] ?? 0).toString()) ??
      0;

  List<dynamic> get recommendedTours {
    final list = tours.where(_isVisibleTour).toList();

    list.sort((a, b) {
      final compareReview = _reviewCountOf(b).compareTo(_reviewCountOf(a));
      if (compareReview != 0) return compareReview;
      return _ratingOf(b).compareTo(_ratingOf(a));
    });

    return list;
  }

  Map<String, List<dynamic>> get toursByCountry {
    final grouped = <String, List<dynamic>>{};

    for (final tour in tours.where(_isVisibleTour)) {
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
      final sortedTours = [...entry.value]
        ..sort((a, b) => _reviewCountOf(b).compareTo(_reviewCountOf(a)));
      result[entry.key] = sortedTours;
    }

    return result;
  }

  // รายการที่แสดงใต้ Chips ตามหมวดที่เลือก
  List<dynamic> get displayedTours {
    final cat = _selectedCategory;
    if (cat == null) return recommendedTours;
    return toursByCountry[cat] ?? [];
  }

  String formatRating(dynamic value) {
    final rating = double.tryParse(value?.toString() ?? '') ?? 0.0;
    return rating.toStringAsFixed(1);
  }

  String formatPrice(dynamic value) {
    final raw = value?.toString().replaceAll(',', '').trim() ?? '';
    if (raw.isEmpty || raw == '-') return '0';

    final price = double.tryParse(raw);
    if (price == null) return raw;

    final text = price % 1 == 0
        ? price.toInt().toString()
        : price.toStringAsFixed(2);

    // ใส่ comma คั่นหลักพัน
    final parts = text.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  // ข้อมูล meta: ระยะเวลา + สายการบิน (ถ้ามี)
  List<String> _metaOf(dynamic tour) {
    final duration = (tour['duration'] ?? '').toString().trim();
    final airline = (tour['airline'] ?? '').toString().trim();
    return [duration, airline].where((e) => e.isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    loadTours();
    loadData();

    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final count = promotionTours.length;
      if (!_promoController.hasClients ||
          count < 2 ||
          _selectedIndex != 0 ||
          isSearching) {
        return;
      }
      final next = (_promoIndex + 1) % count;
      _promoController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final user = authUser?.uid;
    if (user == null) return;

    if (mounted) {
      setState(() => _displayName = authUser?.displayName ?? '');
    }

    try {
      final detail = await Serverapi.getMemberDetail(user);
      if (mounted && detail != null) {
        final memberId = detail['member_id'];
        final name = (detail['first_name'] ?? '').toString();
        final photo = (detail['image_profile'] ?? '').toString();
        setState(() {
          _memberId = memberId?.toString() ?? user;
          if (name.trim().isNotEmpty) _displayName = name.trim();
          if (photo.trim().isNotEmpty) _photoUrl = photo.trim();
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

    final visibleTours = enrichedTours.where(_isVisibleTour).toList();

    setState(() {
      tours = visibleTours;
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
        _selectedIndex = 0;
        _memberId = '';
        _displayName = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ออกจากระบบเรียบร้อย')));
    } catch (e) {
      debugPrint("Error signing out: $e");
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
              backgroundColor: kPrimary,
              foregroundColor: kInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('เข้าสู่ระบบ'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }

    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    setState(() => _selectedIndex = index);
  }

  void _openTour(dynamic tour) {
    final tourId = parseTourId(tour['tour_id']);
    if (tourId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ข้อมูลทริปไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailTour(tourId: tourId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      BookingHistoryPage(memberId: _memberId),
      const ChatPage(userRole: 'user'),
      const ProfilePage(),
    ];

    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: GoogleFonts.sarabunTextTheme(base.textTheme),
      ),
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: kPrimaryDark,
            unselectedItemColor: kMuted,
            iconSize: 24,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "หน้าแรก",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: "การจอง",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: "แชท",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "โปรไฟล์",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HOME ----------
  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        const SizedBox(height: 8),
        Expanded(
          child: isSearching
              ? const Material(color: Colors.white, child: SearchPage())
              : RefreshIndicator(
                  color: kPrimary,
                  onRefresh: loadTours,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      const SizedBox(height: 8),
                      _buildPromoCarousel(),
                      const SizedBox(height: 16),
                      _buildCategoryChips(),
                      _buildSectionTitle('ทัวร์แนะนำ'),
                      _buildTourList(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // 1) Header + Greeting
  Widget _buildHeader() {
    final name = _displayName.isEmpty ? 'ผู้เยี่ยมชม' : '$_displayName';
    final photo = _photoUrl.isNotEmpty ? _photoUrl : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onItemTapped(3),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: kPrimary,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? Text(
                      _displayName.isNotEmpty ? _displayName[0] : 'ส',
                      style: const TextStyle(
                        color: kInk,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const Text(
                  'ค้นหาทริปถัดไปของคุณกัน',
                  style: TextStyle(fontSize: 13, color: kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _roundIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'แชทกับเจ้าหน้าที่',
            onTap: () => _onItemTapped(2),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: kCardShadow,
                ),
                child: Icon(icon, color: kInk, size: 22),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: kSaleDark,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  // 2) Search + Filter
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: openSearch,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: kCardShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: kMuted),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ค้นหาประเทศ, เมือง หรือรหัสทริป เช่น JP001...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: kMuted),
                      ),
                    ),
                    if (isSearching)
                      GestureDetector(
                        onTap: closeSearch,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'ตัวกรองขั้นสูง',
            child: GestureDetector(
              onTap:
                  openSearch, // TODO: เปิดหน้า/ชีต Filter (งบ, วันเดินทาง, จำนวนวัน)
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: kInk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3) Promotional Banner Carousel (16:9 + dots)
  Widget _buildPromoCarousel() {
    final width = MediaQuery.of(context).size.width - 40;
    final height = width * 9 / 16;

    if (isLoading) {
      return SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final promotions = promotionTours;
    if (promotions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _promoController,
            itemCount: promotions.length,
            onPageChanged: (i) => setState(() => _promoIndex = i),
            itemBuilder: (context, index) {
              final tour = promotions[index];
              final imageUrl = (tour['image'] ?? '').toString().trim();
              final promotion = tour['promotion'].toString().trim();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => _openTour(tour),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: kCardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _networkImage(imageUrl),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            right: 14,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: kSaleDark,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  promotion,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 28,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (tour['tour_name'] ?? 'ไม่มีชื่อทริป')
                                      .toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '฿${formatPrice(tour['price'])} /คน',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (promotions.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(promotions.length, (i) {
                final active = i == _promoIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? kPrimary : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  // 4) Category Chips (Horizontal Scroll) — สร้างจากประเทศที่มีในข้อมูลจริง
  Widget _buildCategoryChips() {
    final countries = toursByCountry.keys.toList();

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
      String? code,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.fromLTRB(code != null ? 8 : 16, 0, 16, 0),
            decoration: BoxDecoration(
              color: selected ? kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: selected ? null : kCardShadow,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: kInk),
                  const SizedBox(width: 8),
                ],
                if (code != null) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: kInk,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          chip(
            label: 'ทั้งหมด',
            icon: Icons.local_fire_department_rounded,
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          for (final c in countries)
            chip(
              label: c,
              code: c.characters.take(2).toString().toUpperCase(),
              selected: _selectedCategory == c,
              onTap: () => setState(() => _selectedCategory = c),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kInk,
        ),
      ),
    );
  }

  // 5) Recommended Tour Cards
  Widget _buildTourList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final list = displayedTours;
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('ยังไม่มีทริป')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 14,
            children: [
              for (final tour in list)
                SizedBox(width: cardWidth, child: _buildTourCard(tour)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTourCard(dynamic tour) {
    final imageUrl = (tour['image'] ?? '').toString().trim();
    final meta = _metaOf(tour);
    final code = (tour['tour_code'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () => _openTour(tour),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 122,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(imageUrl),

                    if (code.isNotEmpty)
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (tour['tour_name'] ?? 'ไม่มีชื่อทริป').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                      height: 1.35,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta.join('   •   '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: kMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatRating(tour['average_rating'] ?? 0.0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${_reviewCountOf(tour)})',
                        style: const TextStyle(fontSize: 10, color: kMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '฿${formatPrice(tour['price'])}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        const TextSpan(
                          text: ' /เริ่มต้น',
                          style: TextStyle(fontSize: 10, color: kMuted),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _networkImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE5E7EB),
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
