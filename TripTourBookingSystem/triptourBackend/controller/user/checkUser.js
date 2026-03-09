import express from "express";
import {conn} from "../../config/db.js";
export const router = express.Router();
router.post("/", async (req, res) => {
  const { google_id ,email} = req.body;

  try {
    
    const [MemberRows] = await conn.query("SELECT email FROM Member WHERE google_id = ?", [google_id]);


     if (MemberRows.length > 0) {
      return res.json({
        status: "exist",
        role: "user",
        user: MemberRows[0]
      });
    }
     const [guideRows] = await conn.query(
      "SELECT email FROM Guide WHERE email = ?",
      [email]
    );

     if (guideRows.length > 0) {
      return res.json({
        status: "exist",
        role: "guide",
        user: guideRows[0]
      });
    }

    // ไม่พบ user
    res.json({
      status: "new",
      message: "User does not exist"
    });

} catch (error) {
    console.log(error)
    res.status(500).json({ error: "Internal server error" });
  }
});