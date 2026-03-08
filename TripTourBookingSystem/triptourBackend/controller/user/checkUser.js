import express from "express";
import {conn} from "../config/db.js";
export const router = express.Router();
router.get("/", async (req, res) => {
  const { google_id, email } = req.body;

  try {
    
    conn [rows] = await conn.query("SELECT * FROM Member WHERE google_id = ?", [google_id]);
    if (rows.length > 0) {
      res.json({ status: "exist", user: rows[0] });
    } else {
      res.json({ status: "new", message: "User does not exist" });
    }
} catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});