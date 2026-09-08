import express from "express";
import { conn } from "../../config/db.js";
export const router = express.Router();

// GET : ดึงข้อมูล Tour มาแสดง
// ==========================================
router.get("/", async (req, res) => {
    try {
        const [rows] = await conn.query(`
            SELECT
                t.tour_id,
                t.tour_name,
                t.country_id,
                c.country_name_th,
                c.country_name_en,
                t.type,
                t.duration_day,
                t.price,
                t.video,
                t.promotion,
                t.condition_detail,
                t.include_flight,
                t.pdf_file,
                t.status,

                (
                    SELECT ti.image
                    FROM tour_image ti
                    WHERE ti.tour_id = t.tour_id
                    ORDER BY ti.img_id ASC
                    LIMIT 1
                ) AS image

            FROM tour t

            LEFT JOIN country c
                ON t.country_id = c.country_id

            WHERE t.status = 'open'

            ORDER BY t.tour_id DESC
        `);

        res.status(200).json({
            success: true,
            data: rows
        });

    } catch (error) {
        console.error("Get Tour Error:", error);

        res.status(500).json({
            success: false,
            message: "ไม่สามารถดึงข้อมูลทัวร์ได้",
            error: error.message
        });
    }
});

router.post("/", async (req, res) => {
    const connection = await conn.getConnection();  
    try {
        await connection.beginTransaction();

        const {
            tour_name, country_id, type, duration_day, price, video, 
            promotion, condition_detail, include_flight, pdf_file, status,
            tour_details
        } = req.body;

        const insertTourQuery = `
            INSERT INTO Tour (
                tour_name, country_id, type, duration_day, price, video, 
                promotion, condition_detail, include_flight, pdf_file, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const tourValues = [
            tour_name, country_id, type, duration_day, price, video, 
            promotion, condition_detail, include_flight, pdf_file, status
        ];

        const [tourResult] = await connection.query(insertTourQuery, tourValues);
        const newTourId = tourResult.insertId; 

        if (tour_details && tour_details.length > 0) {
            const insertDetailQuery = `
                INSERT INTO TourDetail (
                    tour_id, day_number, day_detail, location, 
                    travel, hotel, meal_detail, restaurant_detail
                ) VALUES ?
            `;
            
            const detailValues = tour_details.map(detail => [
                newTourId, 
                detail.day_number, 
                detail.day_detail, 
                detail.location, 
                detail.travel, 
                detail.hotel, 
                detail.meal_detail, 
                detail.restaurant_detail
            ]);

            await connection.query(insertDetailQuery, [detailValues]);
        }

        await connection.commit();
        res.status(201).json({ 
            message: "เพิ่มข้อมูลทัวร์สำเร็จ", 
            tour_id: newTourId 
        });

    } catch (error) {
        await connection.rollback();
        console.error("Add Tour Transaction Error:", error);
        res.status(500).json({ 
            message: "เกิดข้อผิดพลาดในการบันทึกข้อมูลทัวร์", 
            error: error.message 
        });
    } finally {
        connection.release();
    }
});

router.get("/search-options/countries", async (req, res) => {
  try {
    const [rows] = await conn.query(`
      SELECT DISTINCT
        c.country_id,
        c.country_name_th,
        c.country_name_en
      FROM country c
      INNER JOIN tour t
        ON t.country_id = c.country_id
      ORDER BY c.country_name_th
    `);

    res.json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error("Get countries error:", error);

    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
});

router.get("/search-options/airlines", async (req, res) => {
  try {
    const [rows] = await conn.query(`
      SELECT DISTINCT
        airline
      FROM tour_round
      WHERE airline IS NOT NULL
        AND TRIM(airline) <> ''
      ORDER BY airline
    `);

    res.json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error("Get airlines error:", error);

    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
});

router.post("/search-tour", async (req, res) => {
  try {
    const {
      keyword,
      countryId,
      airlines,
      startDate,
      endDate,
    } = req.body;

    let sql = `
      SELECT DISTINCT
        t.tour_id,
        t.tour_name,
        t.country_id,
        c.country_name_th,
        c.country_name_en,
        t.type,
        t.duration_day,
        t.price,
        t.promotion,
        t.status,

        tr.round_id,
        tr.departure,
        tr.destination,
        tr.start_date,
        tr.end_date,
        tr.airline,
        tr.flight,
        tr.flight_time,
        tr.price_single,
        tr.price_double,
        tr.price_triple

      FROM tour t

      INNER JOIN country c
        ON c.country_id = t.country_id

      INNER JOIN tour_round tr
        ON tr.tour_id = t.tour_id

      WHERE 1 = 1
    `;

    const params = [];

    // ============================================
    // 1. Keyword
    // ค้นจาก tour_id หรือ tour_name
    // ============================================

    if (keyword && keyword.trim() !== "") {
      const searchKeyword = keyword.trim();

      sql += `
        AND (
          CAST(t.tour_id AS CHAR) LIKE ?
          OR t.tour_name LIKE ?
        )
      `;

      params.push(
        `%${searchKeyword}%`,
        `%${searchKeyword}%`
      );
    }

    // ============================================
    // 2. Country
    // ============================================

    if (countryId != null) {
      sql += `
        AND t.country_id = ?
      `;

      params.push(countryId);
    }

    // ============================================
    // 3. Airline Multi-select
    // ============================================

    if (
      Array.isArray(airlines) &&
      airlines.length > 0
    ) {
      const placeholders = airlines
        .map(() => "?")
        .join(",");

      sql += `
        AND tr.airline IN (${placeholders})
      `;

      params.push(...airlines);
    }

    // ============================================
    // 4. Date Range
    //
    // รอบทัวร์ต้องอยู่ภายในช่วงวันที่ผู้ใช้เลือก
    // ============================================

    if (startDate && endDate) {
      sql += `
        AND tr.start_date >= ?
        AND tr.end_date <= ?
      `;

      params.push(
        startDate,
        endDate
      );
    }

    // ============================================
    // 5. เอาเฉพาะรอบที่เปิด
    // ============================================

    sql += `
      AND tr.status = 'open'
    `;

    // ============================================
    // เรียงข้อมูล
    // ============================================

    sql += `
      ORDER BY
        tr.start_date ASC,
        t.tour_id ASC
    `;

    const [rows] = await conn.query(
      sql,
      params
    );

    res.json({
      success: true,
      data: rows,
    });

  } catch (error) {
    console.error(
      "Search tour error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
});