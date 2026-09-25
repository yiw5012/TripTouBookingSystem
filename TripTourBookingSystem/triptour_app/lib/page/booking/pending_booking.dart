// lib/page/booking/pending_booking_manager.dart

class PendingBookingManager {
  // Singleton instance
  static final PendingBookingManager _instance =
      PendingBookingManager._internal();
  factory PendingBookingManager() => _instance;
  PendingBookingManager._internal();

  int? bookingId;
  String? memberId;
  DateTime? expireTime;
  bool isPending = false;

  void setPendingBooking({
    required int bookingId,
    required String memberId,
    int minutes = 3,
  }) {
    this.bookingId = bookingId;
    this.memberId = memberId;
    this.expireTime = DateTime.now().add(Duration(minutes: minutes));
    this.isPending = true;
  }

  // เช็กว่ายังมีรายการค้างและยังไม่หมดอายุหรือไม่
  bool hasActivePending() {
    if (!isPending) return false;
    if (expireTime != null && DateTime.now().isAfter(expireTime!)) {
      clearPending(); // หมดอายุแล้ว ล้างค่าทิ้ง
      return false;
    }
    return true;
  }

  // คำนวณเวลาคงเหลือเป็นวินาที
  int get remainingSeconds {
    if (expireTime == null) return 0;
    final diff = expireTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  // ล้างข้อมูลเมื่อชำระเงินเสร็จหรือยกเลิกรายการ
  void clearPending() {
    bookingId = null;
    memberId = null;
    expireTime = null;
    isPending = false;
  }
}
