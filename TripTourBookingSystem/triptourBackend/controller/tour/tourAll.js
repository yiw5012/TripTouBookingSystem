import express from "express";
import { conn } from "../../config/db.js";
export const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const [rows] = await conn.query("SELECT * FROM Tour");
    res.json(rows); // ส่งข้อมูลกลับไป
  } catch (err) {
    console.error(err);
    res.status(500).send("Database error");
  }
});