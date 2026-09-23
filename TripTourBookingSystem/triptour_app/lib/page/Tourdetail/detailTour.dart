import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:triptour_app/serverApi.dart';

import 'tour/tourHeader.dart';
import 'tour/tourBookingSection.dart';
import 'tour/tourDetailSection.dart';
import 'tour/tourNoteSection.dart';

class DetailTour extends StatefulWidget {
  final int tourId;

  const DetailTour({super.key, required this.tourId});

  @override
  State<DetailTour> createState() => _DetailTourState();
}

class _DetailTourState extends State<DetailTour>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // TAB
  // ==========================================================

  late TabController tabController;

  // ==========================================================
  // SCROLL
  // ==========================================================

  final ScrollController scrollController = ScrollController();

  final GlobalKey stickyTabKey = GlobalKey();

  final List<GlobalKey> sectionKeys = [
    GlobalKey(), // 0 = จอง
    GlobalKey(), // 1 = รายละเอียด / มื้ออาหาร
    GlobalKey(), // 2 = หมายเหตุ
  ];

  static const double stickyTabHeight = 52;

  int activeTab = 0;

  // ==========================================================
  // DATA
  // ==========================================================

  Map<String, dynamic>? tour;

  List<dynamic> images = [];
  List<dynamic> rounds = [];
  List<dynamic> details = [];

  bool isLoading = true;
  String? errorMessage;

  int selectedDay = 1;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);

    scrollController.addListener(handleScrollSpy);

    loadTourDetail();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    scrollController.removeListener(handleScrollSpy);

    scrollController.dispose();
    tabController.dispose();

    super.dispose();
  }

  // ==========================================================
  // LOAD TOUR DETAIL
  // ==========================================================

  Future<void> loadTourDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await Serverapi.getTourDetail(widget.tourId);

      if (!mounted) return;

      if (result['statusCode'] == 200 &&
          result['body'] != null &&
          result['body']['success'] == true) {
        final data = result['body']['data'];

        final List<dynamic> loadedDetails = data['details'] ?? [];

        int firstDay = 1;

        if (loadedDetails.isNotEmpty) {
          firstDay =
              int.tryParse(loadedDetails.first['day_number'].toString()) ?? 1;
        }

        setState(() {
          tour = data['tour'];

          images = data['images'] ?? [];

          rounds = data['rounds'] ?? [];

          details = loadedDetails;

          selectedDay = firstDay;

          isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleScrollSpy();
        });
      } else {
        setState(() {
          isLoading = false;

          errorMessage = result['body']?['message'] ?? 'ไม่พบข้อมูลทัวร์';
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Load tour detail error: $e');

      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    }
  }

  // ==========================================================
  // SCROLL SPY
  // ==========================================================

  void handleScrollSpy() {
    if (!scrollController.hasClients) {
      return;
    }

    final stickyContext = stickyTabKey.currentContext;

    if (stickyContext == null) {
      return;
    }

    final stickyRenderObject = stickyContext.findRenderObject();

    if (stickyRenderObject == null || stickyRenderObject is! RenderBox) {
      return;
    }

    final RenderBox stickyBox = stickyRenderObject;

    final Offset stickyPosition = stickyBox.localToGlobal(Offset.zero);

    final double stickyBottom = stickyPosition.dy + stickyBox.size.height;

    int newActiveTab = 0;

    for (int i = 0; i < sectionKeys.length; i++) {
      final context = sectionKeys[i].currentContext;

      if (context == null) {
        continue;
      }

      final renderObject = context.findRenderObject();

      if (renderObject == null || renderObject is! RenderBox) {
        continue;
      }

      final RenderBox sectionBox = renderObject;

      final Offset sectionPosition = sectionBox.localToGlobal(Offset.zero);

      final double sectionTop = sectionPosition.dy;

      if (sectionTop <= stickyBottom + 10) {
        newActiveTab = i;
      }
    }

    if (newActiveTab != activeTab) {
      setState(() {
        activeTab = newActiveTab;
      });

      tabController.animateTo(
        newActiveTab,
        duration: const Duration(milliseconds: 180),
      );
    }
  }

  // ==========================================================
  // TAB -> SCROLL TO SECTION
  // ==========================================================

  Future<void> scrollToSection(int index) async {
    final context = sectionKeys[index].currentContext;

    if (context == null) {
      return;
    }

    final renderObject = context.findRenderObject();

    if (renderObject == null) {
      return;
    }

    final RenderAbstractViewport viewport = RenderAbstractViewport.of(
      renderObject,
    );

    double targetOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;

    targetOffset -= stickyTabHeight;

    if (targetOffset < 0) {
      targetOffset = 0;
    }

    final double maxScroll = scrollController.position.maxScrollExtent;

    if (targetOffset > maxScroll) {
      targetOffset = maxScroll;
    }

    setState(() {
      activeTab = index;
    });

    tabController.animateTo(index, duration: const Duration(milliseconds: 180));

    await scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ==========================================================
  // STICKY TAB
  // ==========================================================

  Widget buildStickyTabBar() {
    return Container(
      key: stickyTabKey,
      height: stickyTabHeight,

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: TabBar(
        controller: tabController,

        onTap: (index) {
          scrollToSection(index);
        },

        labelColor: Colors.orange,

        unselectedLabelColor: Colors.grey.shade600,

        indicatorColor: Colors.orange,

        indicatorWeight: 3,

        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),

        unselectedLabelStyle: const TextStyle(fontSize: 12),

        tabs: const [
          Tab(text: 'จอง'),
          Tab(text: 'รายละเอียด / มื้ออาหาร'),
          Tab(text: 'หมายเหตุ'),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'รายละเอียดทัวร์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? buildError()
          : tour == null
          ? const Center(child: Text('ไม่พบข้อมูลทัวร์'))
          : CustomScrollView(
              controller: scrollController,

              slivers: [
                // ==================================================
                // HEADER
                // ==================================================
                SliverToBoxAdapter(
                  child: TourHeader(tour: tour!, images: images),
                ),

                // ==================================================
                // STICKY TAB
                // ==================================================
                SliverPersistentHeader(
                  pinned: true,

                  delegate: StickyTabDelegate(
                    height: stickyTabHeight,
                    child: buildStickyTabBar(),
                  ),
                ),

                // ==================================================
                // SECTION 1
                // จอง
                // ==================================================
                SliverToBoxAdapter(
                  child: TourBookingSection(
                    key: sectionKeys[0],
                    rounds: rounds,
                  ),
                ),

                // ==================================================
                // SECTION 2
                // รายละเอียด / มื้ออาหาร
                // ==================================================
                SliverToBoxAdapter(
                  child: TourDetailSection(
                    key: sectionKeys[1],

                    details: details,

                    selectedDay: selectedDay,

                    onDaySelected: (day) {
                      setState(() {
                        selectedDay = day;
                      });
                    },
                  ),
                ),

                // ==================================================
                // SECTION 3
                // หมายเหตุ
                // ==================================================
                SliverToBoxAdapter(child: TourNoteSection(key: sectionKeys[2])),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.grey),

            const SizedBox(height: 12),

            Text(errorMessage ?? 'เกิดข้อผิดพลาด', textAlign: TextAlign.center),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadTourDetail,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STICKY TAB DELEGATE
// ============================================================

class StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  StickyTabDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,

      elevation: overlapsContent ? 2 : 0,

      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyTabDelegate oldDelegate) {
    return oldDelegate.height != height;
  }
}
