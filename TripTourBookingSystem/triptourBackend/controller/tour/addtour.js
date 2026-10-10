import express from "express";
import { conn } from "../../config/db.js";
import { tourUpload } from "../middleware/upload.js";
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

// ==========================================================
// POST : เพิ่มข้อมูลทัวร์
// รองรับ
// 1. ข้อมูลทัวร์
// 2. รูปภาพหลายรูป
// 3. วิดีโอ
// 4. PDF
// 5. รายละเอียดรายวัน
// ==========================================================

router.post(
  "/",
  tourUpload.fields([
    {
      name: "tour_images",
      maxCount: 20
    },
    {
      name: "video",
      maxCount: 1
    },
    {
      name: "pdf_file",
      maxCount: 1
    }
  ]),
  async (req, res) => {

    let connection = null;

    try {

      // ======================================================
      // รับไฟล์
      // ======================================================

      const imageFiles =
        req.files?.tour_images ?? [];

      const videoFile =
        req.files?.video?.[0] ?? null;

      const pdfFile =
        req.files?.pdf_file?.[0] ?? null;


      // ======================================================
      // รับข้อมูลจาก FormData
      // ======================================================

      let {
        tour_name,
        country_id,
        type,
        duration_day,
        price,
        promotion,
        condition_detail,
        include_flight,
        status,
        tour_details
      } = req.body;


      // ======================================================
      // รองรับค่าจาก HTML เดิม
      // ต่างประเทศ -> นอกประเทศ
      // Active -> open
      // ======================================================

      if (type === "ต่างประเทศ") {
        type = "นอกประเทศ";
      }

      if (status === "Active") {
        status = "open";
      }


      // ======================================================
      // ตรวจข้อมูลที่จำเป็น
      // ======================================================

      if (!tour_name || String(tour_name).trim() === "") {

        return res.status(400).json({
          success: false,
          message: "กรุณากรอกชื่อทัวร์"
        });

      }


      if (!country_id) {

        return res.status(400).json({
          success: false,
          message: "กรุณาเลือกประเทศ"
        });

      }


      if (!duration_day) {

        return res.status(400).json({
          success: false,
          message: "กรุณาระบุจำนวนวัน"
        });

      }


      if (
        price === undefined ||
        price === null ||
        price === ""
      ) {

        return res.status(400).json({
          success: false,
          message: "กรุณาระบุราคา"
        });

      }


      if (!include_flight) {

        return res.status(400).json({
          success: false,
          message: "กรุณาเลือกว่ารวมตั๋วเครื่องบินหรือไม่"
        });

      }


      if (!status) {

        return res.status(400).json({
          success: false,
          message: "กรุณาเลือกสถานะทัวร์"
        });

      }


      // ======================================================
      // PDF จำเป็น
      // เพราะ tour.pdf_file เป็น NOT NULL
      // ======================================================

      if (!pdfFile) {

        return res.status(400).json({
          success: false,
          message: "กรุณาเลือกไฟล์ PDF ของโปรแกรมทัวร์"
        });

      }


      // ======================================================
      // แปลง tour_details
      // เพราะ FormData จะส่งมาเป็น String
      // ======================================================

      let parsedTourDetails = [];

      if (tour_details) {

        try {

          parsedTourDetails =
            typeof tour_details === "string"
              ? JSON.parse(tour_details)
              : tour_details;

        } catch (error) {

          return res.status(400).json({
            success: false,
            message: "รูปแบบข้อมูลรายละเอียดรายวันไม่ถูกต้อง"
          });

        }

      }


      if (!Array.isArray(parsedTourDetails)) {

        return res.status(400).json({
          success: false,
          message: "ข้อมูลรายละเอียดรายวันต้องเป็น Array"
        });

      }


      // ======================================================
      // URL จาก Cloudinary
      // ======================================================

      const videoUrl =
        videoFile?.path ?? null;

      const pdfUrl =
        pdfFile?.path ?? null;


      // ======================================================
      // DEBUG
      // ======================================================

      console.log("==========================================");
      console.log("ADD TOUR");
      console.log("TOUR NAME =", tour_name);
      console.log("COUNTRY ID =", country_id);
      console.log("TYPE =", type);
      console.log("DURATION =", duration_day);
      console.log("PRICE =", price);
      console.log("VIDEO URL =", videoUrl);
      console.log("PDF URL =", pdfUrl);
      console.log("IMAGE COUNT =", imageFiles.length);
      console.log("TOUR DETAILS COUNT =", parsedTourDetails.length);
      console.log("STATUS =", status);
      console.log("==========================================");


      // ======================================================
      // เชื่อม Database
      // ======================================================

      connection =
        await conn.getConnection();

      await connection.beginTransaction();


      // ======================================================
      // 1. INSERT TOUR
      // ======================================================

      const insertTourQuery = `
        INSERT INTO tour (
          tour_name,
          country_id,
          type,
          duration_day,
          price,
          video,
          promotion,
          condition_detail,
          include_flight,
          pdf_file,
          status
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;


      const tourValues = [

        tour_name,
        Number(country_id),
        type || null,
        Number(duration_day),
        Number(price),
        videoUrl,
        promotion || null,
        condition_detail || null,
        include_flight,
        pdfUrl,
        status

      ];


      const [tourResult] =
        await connection.query(
          insertTourQuery,
          tourValues
        );


      const newTourId =
        tourResult.insertId;


      // ======================================================
      // 2. INSERT TOUR DETAIL
      // ======================================================

      if (parsedTourDetails.length > 0) {

        const insertDetailQuery = `
          INSERT INTO tour_detail (
            tour_id,
            day_number,
            day_detail,
            location,
            travel,
            hotel,
            meal_detail,
            restaurant_detail
          )
          VALUES ?
        `;


        const detailValues =
          parsedTourDetails.map(
            (detail, index) => [

              newTourId,

              detail.day_number ??
                index + 1,

              detail.day_detail ??
                null,

              detail.location ??
                null,

              detail.travel ??
                null,

              detail.hotel ??
                null,

              detail.meal_detail ??
                null,

              detail.restaurant_detail ??
                null

            ]
          );


        await connection.query(
          insertDetailQuery,
          [detailValues]
        );

      }


      // ======================================================
      // 3. INSERT TOUR IMAGE
      // ======================================================

      if (imageFiles.length > 0) {

        const imageValues =
          imageFiles.map(
            (file) => [

              newTourId,
              file.path

            ]
          );


        const insertImageQuery = `
          INSERT INTO tour_image (
            tour_id,
            image
          )
          VALUES ?
        `;


        await connection.query(
          insertImageQuery,
          [imageValues]
        );

      }


      // ======================================================
      // 4. COMMIT
      // ======================================================

      await connection.commit();
      

      // SEND FCM NOTIFICATION TO FAVORED USERS
      try {
        // ดึงข้อมูลประเทศเพื่อเอาชื่อ EN มาทำ Topic 
        const [countryRows] = await conn.query(
          "SELECT country_name_th, country_name_en FROM country WHERE country_id = ? LIMIT 1",
          [Number(country_id)]
        );

        if (countryRows.length > 0) {
          const { country_name_th, country_name_en } = countryRows[0];

          // แปลง
          // (เช่น "South Korea" -> "country_south_korea")
          const cleanName = country_name_en
            .trim()
            .toLowerCase()
            .replace(/[^a-zA-Z0-9]/g, "_");

          const targetTopic = `country_${cleanName}`;
          const formattedPrice = Number(price).toLocaleString();

          const notificationMessage = {
            notification: {
              title: `แพ็กเกจทัวร์${country_name_th || ""}มาใหม่! ✈️`,
              body: `${tour_name} ราคาเริ่มต้นเพียง ฿${formattedPrice}`,
            },
            data: {
              tour_id: String(newTourId),
              type: "new_tour",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            topic: targetTopic,
          };

          await admin.messaging().send(notificationMessage);
          console.log(`✅ FCM Notification sent successfully to topic: ${targetTopic}`);
        }
      } catch (notiError) {
        console.error("⚠️ Send Notification Error:", notiError.message);
      }
      return res.status(201).json({

        success: true,

        message:
          "เพิ่มข้อมูลทัวร์สำเร็จ",

        data: {

          tour_id: newTourId,

          video: videoUrl,

          pdf_file: pdfUrl,

          image_count:
            imageFiles.length,

          detail_count:
            parsedTourDetails.length

        }

      });


    } catch (error) {

      // ======================================================
      // ROLLBACK
      // ======================================================

      if (connection) {

        try {

          await connection.rollback();

        } catch (rollbackError) {

          console.error(
            "Rollback error:",
            rollbackError
          );

        }

      }


      console.error(
        "Add Tour Transaction Error:",
        error
      );


      return res.status(500).json({

        success: false,

        message:
          "เกิดข้อผิดพลาดในการบันทึกข้อมูลทัวร์",

        error:
          error.message

      });


    } finally {

      if (connection) {

        connection.release();

      }

    }

  }
);

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
        t.video,
        t.pdf_file,
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

