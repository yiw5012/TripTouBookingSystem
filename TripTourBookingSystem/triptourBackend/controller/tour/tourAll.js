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

router.post("/getTourById", async (req, res) => {

  const { tour_id } = req.body;
  try {

    const [row] = await conn.query("select * from tour where tour_id = ?", [tour_id]);
    if(row.length > 0){
      return res.json({
        success: true,
        data: row[0],
      });
    } else {
      return res.status(404).json({ error: "Tour not found" });
    }
    
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: "Internal server error" });
  }


});