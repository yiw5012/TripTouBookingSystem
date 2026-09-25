import express from "express";
import { conn } from "../../../config/db.js";
import { checkAndUpdateRoundStatus } from '../../booking/checkround_status.js';

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
    const [roundRows] = await conn.query(
      `SELECT * FROM tour_round WHERE round_id = ?`,
      [round_id]
    );

    if (!roundRows || roundRows.length === 0) {
      return res.status(404).json({
        statusCode: 404,
        body: {
          success: false,
          message: 'Tour round not found',
        },
      });
    }

    const statusSummary = await checkAndUpdateRoundStatus(conn, round_id);
    
    const responseData = {
      ...roundRows[0],
      total_paid: statusSummary.total_paid,
      status: statusSummary.status,
    };

    console.log("responseData:", responseData);

    return res.status(200).json({
      statusCode: 200, 
      body: {
        success: true,
        data: responseData, 
      },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      statusCode: 500,
      body: {
        success: false,
        message: "Internal server error",
      },
    });
  }
});