import express from "express";
import { conn } from "../../../config/db.js";
export const router = express.Router();


router.post("/getTourRoundByTourId", async (req, res) => {

  const { tour_id } = req.body;
  try {

    const [rows] = await conn.query("select * from tour_round where tour_id = ?", [tour_id]);
    if(rows.length > 0){
      return res.json({ success: true, data: rows });
    } else {
      return res.status(404).json({ success: false, message: "Tour not found" });
    }
    
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: "Internal server error" });
  }


});

router.post("/getroundById", async (req, res) => {

  const { round_id } = req.body;
  try { 
    const [row] = await conn.query("select * from tour_round where round_id = ?", [round_id]);
    if(row.length > 0){
      return res.json({ success: true, data: row[0] });
    } else {
      return res.status(404).json({ success: false, message: "Round not found" });
    }
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: "Internal server error" });
  }
});