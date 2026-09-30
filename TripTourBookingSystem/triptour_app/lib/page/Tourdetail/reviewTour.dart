import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/serverApi.dart';

class ReviewTourPage extends StatefulWidget {
  final int tourId;
  final String tourName;

  const ReviewTourPage({
    super.key,
    required this.tourId,
    required this.tourName,
  });

  @override
  State<ReviewTourPage> createState() => _ReviewTourPageState();
}

class _ReviewTourPageState extends State<ReviewTourPage> {
  int selectedRating = 0;

  bool isLoading = true;
  bool canReview = false;
  bool alreadyReviewed = false;

  String message = "";

  @override
  void initState() {
    super.initState();

    checkEligibility();
  }

  // =====================================================
  // CHECK ELIGIBILITY
  // =====================================================

  Future<void> checkEligibility() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        canReview = false;
        message = "กรุณาเข้าสู่ระบบก่อนรีวิว";
      });

      return;
    }

    final result = await Serverapi.checkReviewEligibility(
      googleId: user.uid,
      tourId: widget.tourId,
    );

    if (!mounted) return;

    final body = result["body"];

    setState(() {
      isLoading = false;

      canReview = body["canReview"] == true;

      alreadyReviewed = body["alreadyReviewed"] == true;

      message = body["message"]?.toString() ?? "";
    });
  }

  // =====================================================
  // SUBMIT REVIEW
  // =====================================================

  Future<void> submitReview() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกคะแนน 1–5 ดาว")));

      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเข้าสู่ระบบก่อน")));

      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await Serverapi.submitReview(
      googleId: user.uid,
      tourId: widget.tourId,
      rating: selectedRating,
    );

    if (!mounted) return;

    final body = result["body"];

    setState(() {
      isLoading = false;
    });

    if (result["statusCode"] == 201 && body["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ส่งรีวิวสำเร็จ")));

      Navigator.pop(context, true);

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body["message"]?.toString() ?? "ส่งรีวิวไม่สำเร็จ"),
      ),
    );
  }

  // =====================================================
  // STAR
  // =====================================================

  Widget buildStar(int index) {
    final bool isSelected = index <= selectedRating;

    return IconButton(
      onPressed: canReview
          ? () {
              setState(() {
                selectedRating = index;
              });
            }
          : null,
      icon: Icon(
        isSelected ? Icons.star : Icons.star_border,
        size: 48,
        color: Colors.amber,
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ให้คะแนนทัวร์"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  const Icon(Icons.rate_review, size: 70, color: Colors.orange),

                  const SizedBox(height: 20),

                  const Text(
                    "ให้คะแนนโปรแกรมทัวร์",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.tourName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),

                  const SizedBox(height: 30),

                  if (!canReview)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  if (canReview) ...[
                    const Text(
                      "ระดับความพึงพอใจ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildStar(1),
                        buildStar(2),
                        buildStar(3),
                        buildStar(4),
                        buildStar(5),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      selectedRating == 0
                          ? "กรุณาเลือกคะแนน"
                          : "$selectedRating / 5 ดาว",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "ส่งรีวิว",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
