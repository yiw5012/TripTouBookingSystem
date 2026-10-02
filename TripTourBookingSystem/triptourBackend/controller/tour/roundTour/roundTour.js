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

router.get("/guide/:guideId", async (req, res) => {
  const guideId = Number(req.params.guideId);

  if (!guideId || Number.isNaN(guideId)) {
    return res.status(400).json({
      success: false,
      message: "guide_id ไม่ถูกต้อง",
    });
  }

  try {
    const [rows] = await conn.query(
      `
        SELECT
          tr.round_id,
          tr.tour_id,
          tr.departure,
          tr.destination,
          tr.start_date,
          tr.end_date,
          tr.status,
          tr.count,
          tr.guide_id,
          t.tour_name,
          t.duration_day,
          c.country_name_th
        FROM tour_round tr
        LEFT JOIN tour t
          ON t.tour_id = tr.tour_id
        LEFT JOIN country c
          ON c.country_id = t.country_id
        WHERE tr.guide_id = ?
        ORDER BY tr.start_date DESC, tr.round_id DESC
      `,
      [guideId],
    );

    return res.status(200).json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: "ไม่สามารถโหลดรอบทัวร์ของไกด์ได้",
    });
  }
});
// router.put('/:roundId/finish', async (req, res) => {
//   const roundId = Number(req.params.roundId);
//   const guideId = Number(req.body.guide_id ?? req.query.guide_id);

//   if (!roundId || Number.isNaN(roundId)) {
//     return res.status(400).json({
//       success: false,
//       message: 'round_id ไม่ถูกต้อง',
//     });
//   }

//   if (!guideId || Number.isNaN(guideId)) {
//     return res.status(400).json({
//       success: false,
//       message: 'guide_id ไม่ถูกต้อง',
//     });
//   }

//   try {
//     // ตรวจสอบว่าไกด์ดูแลรอบทัวร์นี้จริงหรือไม่
//     const [ownershipRows] = await conn.query(
//       `SELECT round_id
//        FROM tour_round
//        WHERE round_id = ? AND guide_id = ?
//        LIMIT 1`,
//       [roundId, guideId],
//     );

//     if (!ownershipRows || ownershipRows.length === 0) {
//       return res.status(404).json({
//         success: false,
//         message: 'ไม่พบรอบทัวร์ที่ไกด์ควบคุม',
//       });
//     }
    

//     // อัปเดตเฉพาะ booking ที่:
//     //    - ผ่านการชำระเงินแล้ว (payment_status = 'paid')
//     //    - แอดมินอนุมัติแล้ว (b.status = 'confirmed')
//     const [result] = await conn.query(
//       `UPDATE booking b
//        JOIN tour_round tr ON tr.round_id = b.round_id
//        SET b.status = 'finish'
//        WHERE tr.round_id = ? 
//          AND tr.guide_id = ?
//          AND b.payment_status = 'paid'
//          AND b.status = 'confirmed'`,
//       [roundId, guideId],
//     );
//     await conn.query(
//       `UPDATE tour_round
//        SET status = 'success'
//        WHERE round_id = ? AND guide_id = ?`,
//       [roundId, guideId],
//     );
//     const [updatedRows] = await conn.query(
//       `SELECT * FROM tour_round WHERE round_id = ?`,
//       [roundId],
//     );

//     return res.status(200).json({
//       success: true,
//       message: 'ปิดรอบทัวร์สำเร็จ',
//       data: updatedRows[0],
//     });

   
//   } catch (error) {
//     console.error('❌ Error finishing bookings:', error);
//     return res.status(500).json({
//       success: false,
//       message: 'ไม่สามารถอัปเดตสถานะการจองได้',
//     });
//   }
// });


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