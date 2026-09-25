import express from "express";
import {conn} from "../../config/db.js";
export const router = express.Router();

router.post("/detail", async (req, res) => {
  try {
    const { targetUid } = req.body;

    if (!targetUid) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุ targetUid ใน request body",
      });
    }

    const [rows] = await conn.query(
      "SELECT * FROM member  WHERE google_id = ?",
      [targetUid]
    );
    const [guiderows] = await conn.query(
      "SELECT * FROM guide  WHERE google_id = ?",
      [targetUid]
    );

    if (rows.length === 0 && guiderows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลสมาชิก",
      });
    }
if (rows.length > 0 && guiderows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "พบข้อมูลสมาชิกทั้งในตาราง member และ guide",
      });
    }
    if (rows.length > 0) {
      return res.json({
        success: true,
        data: rows[0],
      });
    }
    if (guiderows.length > 0) {
      return res.json({
        success: true,
        data: guiderows[0],
      });
    }
    // ส่งข้อมูลสมาชิกคนนั้นกลับไป
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Database error",
      error: error.message,
    });
  }
});

router.put("/update", async (req, res) => {
  try {
    const {
      google_id,
      first_name,
      last_name,
      phone,
      number_id,
      birthday,
      address,
      gender,
      medicine,
      congenital_disease,
      allergic_list,
      others,
      image_profile,
      image_passport,
    } = req.body;

    // =====================================================
    // ตรวจ google_id
    // =====================================================

    if (!google_id || google_id.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุ google_id",
      });
    }

    // =====================================================
    // ตรวจชื่อ
    // =====================================================

    if (!first_name || first_name.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุชื่อ",
      });
    }

    // =====================================================
    // UPDATE ข้อมูลสมาชิก
    // =====================================================

    const [result] = await conn.query(
      `
      UPDATE member
      SET
        first_name = ?,
        last_name = ?,
        phone = ?,
        number_id = ?,
        birthday = ?,
        address = ?,
        gender = ?,
        medicine = ?,
        congenital_disease = ?,
        allergic_list = ?,
        others = ?,
        image_profile = ?,
        image_passport = ?
      WHERE google_id = ?
      `,
      [
        first_name,
        last_name,
        phone,
        number_id,
        birthday,
        address,
        gender,
        medicine,
        congenital_disease,
        allergic_list,
        others,
        image_profile,
        image_passport,
        google_id,
      ]
    );

    // =====================================================
    // ไม่พบสมาชิก
    // =====================================================

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลสมาชิก",
      });
    }

    // =====================================================
    // สำเร็จ
    // =====================================================

    res.status(200).json({
      success: true,
      message: "อัปเดตข้อมูลสมาชิกสำเร็จ",
    });

  } catch (error) {
    console.error("Update member error:", error);

    res.status(500).json({
      success: false,
      message: "ไม่สามารถอัปเดตข้อมูลสมาชิกได้",
      error: error.message,
    });
  }
});