import express from "express";
import {conn} from "../../config/db.js";
export const router = express.Router();

router.post("/", async (req, res) => {
  const { google_id, email, firstname, lastname, phone } = req.body;

  try{
    
    const [result] = await conn.query(
      "INSERT INTO Member (google_id, email, first_name, last_name, phone) VALUES (?, ?, ?, ?, ?)",
      [google_id, email, firstname, lastname, phone]
    );

    res.json({ status: "success", message: "User registered successfully", userId: result.insertId });
  } catch (error) {
    res.status(500).json({ status: "error", message: "Internal server error" });
  }
});
