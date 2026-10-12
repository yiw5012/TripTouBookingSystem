import express from "express";
import { conn } from "../../config/db.js";

export const router = express.Router();

// =====================================================
// REVIEW : CHECK ELIGIBILITY
// ตรวจสอบว่าสมาชิกมีสิทธิ์รีวิวหรือไม่
// =====================================================

router.post("/check", async (req, res) => {
  try {
    const { google_id, tour_id } = req.body;

    if (!google_id || google_id.trim() === "") {
      return res.status(400).json({
        success: false,
        canReview: false,
        message: "ไม่พบ google_id",
      });
    }

    if (!tour_id || isNaN(Number(tour_id))) {
      return res.status(400).json({
        success: false,
        canReview: false,
        message: "tour_id ไม่ถูกต้อง",
      });
    }

    const tourIdNumber = Number(tour_id);

    // =====================================================
    // ตรวจสอบว่ามีการชำระเงินของทัวร์นี้แล้วหรือไม่
    // =====================================================

    const [bookingRows] = await conn.query(
      `
      SELECT
        m.member_id,
        b.booking_id,
        b.payment_status,
        tr.round_id,
        tr.tour_id
      FROM member m
      INNER JOIN booking b
        ON b.member_id = m.member_id
      INNER JOIN tour_round tr
        ON tr.round_id = b.round_id
      WHERE m.google_id = ?
        AND tr.tour_id = ?
        AND b.payment_status = 'paid'
      LIMIT 1
      `,
      [google_id, tourIdNumber]
    );

    // ยังไม่ได้จ่ายเงิน
    if (bookingRows.length === 0) {
      return res.status(200).json({
        success: true,
        canReview: false,
        alreadyReviewed: false,
        message: "ยังไม่มีสิทธิ์รีวิว เนื่องจากยังไม่พบการชำระเงินของทัวร์นี้",
      });
    }

    const memberId = bookingRows[0].member_id;

    // =====================================================
    // ตรวจสอบว่าเคยรีวิวแล้วหรือยัง
    // =====================================================

    const [reviewRows] = await conn.query(
      `
      SELECT
        review_id,
        rating
      FROM review
      WHERE member_id = ?
        AND tour_id = ?
      LIMIT 1
      `,
      [memberId, tourIdNumber]
    );

    if (reviewRows.length > 0) {
      return res.status(200).json({
        success: true,
        canReview: false,
        alreadyReviewed: true,
        rating: reviewRows[0].rating,
        message: "คุณรีวิวโปรแกรมทัวร์นี้ไปแล้ว",
      });
    }

    return res.status(200).json({
      success: true,
      canReview: true,
      alreadyReviewed: false,
      memberId: memberId,
      message: "สามารถรีวิวโปรแกรมทัวร์นี้ได้",
    });
  } catch (error) {
    console.error("Check review eligibility error:", error);

    return res.status(500).json({
      success: false,
      canReview: false,
      message: "เกิดข้อผิดพลาดในการตรวจสอบสิทธิ์รีวิว",
    });
  }
});

// =====================================================
// REVIEW : SUBMIT REVIEW
// บันทึกคะแนน 1-5 ดาว
// =====================================================

router.post("/", async (req, res) => {
  try {
    const {
      google_id,
      tour_id,
      rating,
    } = req.body;

    // =====================================================
    // ตรวจ google_id
    // =====================================================

    if (!google_id || google_id.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "ไม่พบ google_id",
      });
    }

    // =====================================================
    // ตรวจ tour_id
    // =====================================================

    if (!tour_id || isNaN(Number(tour_id))) {
      return res.status(400).json({
        success: false,
        message: "tour_id ไม่ถูกต้อง",
      });
    }

    // =====================================================
    // ตรวจ rating
    // ต้องเป็น 1-5 และเป็นจำนวนเต็ม
    // =====================================================

    const ratingNumber = Number(rating);

    if (
      !Number.isInteger(ratingNumber) ||
      ratingNumber < 1 ||
      ratingNumber > 5
    ) {
      return res.status(400).json({
        success: false,
        message: "คะแนนต้องอยู่ระหว่าง 1 ถึง 5 ดาว",
      });
    }

    const tourIdNumber = Number(tour_id);

    // =====================================================
    // ตรวจว่าชำระเงินแล้วหรือไม่
    // =====================================================

    const [bookingRows] = await conn.query(
      `
      SELECT
        m.member_id,
        b.booking_id,
        b.payment_status,
        tr.round_id,
        tr.tour_id
      FROM member m
      INNER JOIN booking b
        ON b.member_id = m.member_id
      INNER JOIN tour_round tr
        ON tr.round_id = b.round_id
      WHERE m.google_id = ?
        AND tr.tour_id = ?
        AND b.payment_status = 'paid'
      LIMIT 1
      `,
      [google_id, tourIdNumber]
    );

    if (bookingRows.length === 0) {
      return res.status(403).json({
        success: false,
        message: "คุณยังไม่มีสิทธิ์รีวิว เนื่องจากยังไม่ได้ชำระเงินของทัวร์นี้",
      });
    }

    const memberId = bookingRows[0].member_id;

    // =====================================================
    // ตรวจว่าเคยรีวิวแล้วหรือยัง
    // =====================================================

    const [existingReview] = await conn.query(
      `
      SELECT review_id
      FROM review
      WHERE member_id = ?
        AND tour_id = ?
      LIMIT 1
      `,
      [memberId, tourIdNumber]
    );

    if (existingReview.length > 0) {
      return res.status(409).json({
        success: false,
        message: "คุณรีวิวโปรแกรมทัวร์นี้ไปแล้ว",
      });
    }

    // =====================================================
    // INSERT REVIEW
    // =====================================================

    const [result] = await conn.query(
      `
      INSERT INTO review (
        member_id,
        tour_id,
        rating
      )
      VALUES (?, ?, ?)
      `,
      [
        memberId,
        tourIdNumber,
        ratingNumber,
      ]
    );

    return res.status(201).json({
      success: true,
      message: "บันทึกรีวิวสำเร็จ",
      review_id: result.insertId,
      rating: ratingNumber,
    });
  } catch (error) {
    console.error("Submit review error:", error);

    return res.status(500).json({
      success: false,
      message: "เกิดข้อผิดพลาดในการบันทึกรีวิว",
    });
  }
});

// =====================================================
// REVIEW : GET TOUR REVIEW
// ดึงคะแนนเฉลี่ยและจำนวน Review ของ Tour
// =====================================================

router.get("/tour/:tourId", async (req, res) => {
  try {
    const { tourId } = req.params;

    if (!tourId || isNaN(Number(tourId))) {
      return res.status(400).json({
        success: false,
        message: "tour_id ไม่ถูกต้อง",
      });
    }

    const tourIdNumber = Number(tourId);

    // =====================================================
    // SUMMARY
    // =====================================================

    const [summaryRows] = await conn.query(
      `
      SELECT
        COUNT(*) AS review_count,
        COALESCE(AVG(rating), 0) AS average_rating
      FROM review
      WHERE tour_id = ?
      `,
      [tourIdNumber]
    );

    // =====================================================
    // REVIEW LIST
    // =====================================================

    const [reviewRows] = await conn.query(
      `
      SELECT
        r.review_id,
        r.member_id,
        r.tour_id,
        r.rating,
        m.first_name,
        m.last_name,
        m.image_profile
      FROM review r
      INNER JOIN member m
        ON m.member_id = r.member_id
      WHERE r.tour_id = ?
      ORDER BY r.review_id DESC
      `,
      [tourIdNumber]
    );

    return res.status(200).json({
      success: true,
      data: {
        review_count: Number(summaryRows[0].review_count),
        average_rating: Number(summaryRows[0].average_rating),
        reviews: reviewRows,
      },
    });
  } catch (error) {
    console.error("Get tour review error:", error);

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถดึงข้อมูลรีวิวได้",
    });
  }
});