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