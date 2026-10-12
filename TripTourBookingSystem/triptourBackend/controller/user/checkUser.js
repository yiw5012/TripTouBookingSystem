import express from "express";
import { conn } from "../../config/db.js";
export const router = express.Router();

router.post("/", async (req, res) => {
  const { google_id, email } = req.body;

  try {
    const [MemberRows] = await conn.query(
      "SELECT email, status FROM member WHERE google_id = ?",
      [google_id]
    );

    if (MemberRows.length > 0) {
      if (MemberRows[0].status === "inactive") {
        return res.status(403).json({
          status: "inactive",
          message: "บัญชีผู้ใช้นี้ถูกปิดใช้งานแล้ว",
        });
      }

      return res.json({
        status: "exist",
        role: "user",
        user: MemberRows[0],
      });
    }

    const cleanEmail = email ? String(email).toLowerCase().trim() : null;

    const [guideRows] = await conn.query(
      "SELECT email, status FROM guide WHERE email = ?",
      [cleanEmail]
    );

    if (guideRows.length > 0) {
      if (guideRows[0].status === "inactive") {
        return res.status(403).json({
          status: "inactive",
          message: "บัญชีไกด์นี้ถูกปิดใช้งานแล้ว",
        });
      }

      return res.json({
        status: "exist",
        role: "guide",
        user: guideRows[0],
      });
    }

    res.json({
      status: "new",
      message: "User does not exist",
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "Internal server error" });
  }
});