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
      sortBy,
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

      LEFT JOIN tour_round tr
        ON tr.tour_id = t.tour_id
        AND tr.status = 'open'

      WHERE t.status = 'open'
    `;

    const params = [];

    // ============================================
// กำหนดการเรียงผลลัพธ์
// ============================================

let orderBy = `
  tr.start_date IS NULL ASC,
  tr.start_date ASC,
  t.tour_id ASC
`;

if (sortBy === 'price_asc') {
  orderBy = `
    t.price ASC,
    tr.start_date IS NULL ASC,
    tr.start_date ASC,
    t.tour_id ASC
  `;
}

if (sortBy === 'price_desc') {
  orderBy = `
    t.price DESC,
    tr.start_date IS NULL ASC,
    tr.start_date ASC,
    t.tour_id ASC
  `;
}

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
    // ค้นจาก tour.country_id
    // ============================================
    if (countryId != null) {
      sql += `
        AND t.country_id = ?
      `;

      params.push(countryId);
    }

    // ============================================
    // 3. Airline
    // ค้นจาก tour_round.airline
    // ============================================
    if (Array.isArray(airlines) && airlines.length > 0) {
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
    // ค้นจาก tour_round
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
    // 5. เรียงข้อมูล
    // ทัวร์ที่ไม่มีรอบให้อยู่ท้าย
    // ============================================
    sql += `
  ORDER BY ${orderBy}
`;

    console.log("SQL:", sql);
    console.log("PARAMS:", params);
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

router.get("/detail/:tourId", async (req, res) => {
  try {
    const { tourId } = req.params;

    // ==========================================================
    // 1. ตรวจสอบ tour_id
    // ==========================================================

    if (!tourId || isNaN(Number(tourId))) {
      return res.status(400).json({
        success: false,
        message: "tour_id ไม่ถูกต้อง",
      });
    }

    const tourIdNumber = Number(tourId);

    // ==========================================================
    // 2. ดึงข้อมูลหลักของทัวร์
    // ==========================================================

    const [tourRows] = await conn.query(
      `
      SELECT
        t.tour_id,
        t.tour_name,
        t.country_id,
        c.country_name_th,
        c.country_name_en,
        t.type,
        t.duration_day,
        t.price,
        t.promotion,
        t.status
      FROM tour t
      INNER JOIN country c
        ON c.country_id = t.country_id
      WHERE t.tour_id = ?
      LIMIT 1
      `,
      [tourIdNumber]
    );

    // ถ้าไม่เจอทัวร์
    if (tourRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลทัวร์",
      });
    }

    // ==========================================================
    // 3. ดึงรูปภาพทัวร์
    // ==========================================================

    const [imageRows] = await conn.query(
      `
      SELECT
        image
      FROM tour_image
      WHERE tour_id = ?
      `,
      [tourIdNumber]
    );

    // ==========================================================
    // 4. ดึงรอบทัวร์ทั้งหมด
    // ==========================================================

    const [roundRows] = await conn.query(
      `
      SELECT
        round_id,
        tour_id,
        departure,
        destination,
        start_date,
        end_date,
        airline,
        flight,
        flight_time,
        price_single,
        price_double,
        price_triple,
        status,
        guide_id
      FROM tour_round
      WHERE tour_id = ?
      ORDER BY start_date ASC, round_id ASC
      `,
      [tourIdNumber]
    );

    // ==========================================================
    // 5. ดึงรายละเอียดรายวัน
    // ==========================================================

    const [detailRows] = await conn.query(
      `
      SELECT
        td_id,
        tour_id,
        day_number,
        day_detail,
        location,
        travel,
        hotel,
        meal_detail,
        restaurant_detail
      FROM tour_detail
      WHERE tour_id = ?
      ORDER BY day_number ASC, td_id ASC
      `,
      [tourIdNumber]
    );

    // ==========================================================
    // 6. ส่งข้อมูลกลับ Flutter
    // ==========================================================

    res.status(200).json({
      success: true,
      data: {
        tour: tourRows[0],
        images: imageRows,
        rounds: roundRows,
        details: detailRows,
      },
    });
  } catch (error) {
    console.error("Get tour detail error:", error);

    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
});