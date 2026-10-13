import express from "express";
import { conn } from "../../config/db.js";
import { tourUpload, resolveTourCloudImages, } from "../middleware/upload.js"; 
export const router = express.Router();

const DEFAULT_CONDITION_DETAIL =
  "เงื่อนไขการเดินทางและการให้บริการเป็นไปตามรายละเอียดโปรแกรมทัวร์ที่ระบุไว้ กรุณาตรวจสอบข้อมูลและเอกสารการเดินทางให้ครบถ้วนก่อนยืนยันการจอง";

/*
==========================================================
GET /manage-tour/list
ดึงรายการทัวร์ทั้งหมดสำหรับ Admin
==========================================================
*/
router.get("/list", async (req, res) => {
  try {
    const [rows] = await conn.query(`
      SELECT
        t.tour_id,
        t.tour_code,
        t.tour_name,
        t.country_id,
        c.country_name_th,
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
          LIMIT 1
        ) AS image,

        (
          SELECT COUNT(*)
          FROM tour_image ti2
          WHERE ti2.tour_id = t.tour_id
        ) AS image_count,

        (
          SELECT COUNT(*)
          FROM tour_detail td
          WHERE td.tour_id = t.tour_id
        ) AS detail_count,

        (
          SELECT COUNT(*)
          FROM tour_round tr
          WHERE tr.tour_id = t.tour_id
        ) AS round_count

      FROM tour t

      LEFT JOIN country c
        ON c.country_id = t.country_id

      ORDER BY t.tour_id DESC
    `);

    return res.status(200).json({
      success: true,
      data: rows,
    });

  } catch (error) {
    console.error("❌ GET /manage-tour/list error:", error);

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถโหลดรายการทัวร์ได้",
    });
  }
});


/*
==========================================================
GET /manage-tour/:tourId
ดึงข้อมูลทัวร์แบบละเอียด
รวม:
- tour
- tour_image
- tour_detail
- tour_round
==========================================================
*/
router.get("/:tourId", async (req, res) => {
  const tourId = Number(req.params.tourId);

  if (!tourId || Number.isNaN(tourId)) {
    return res.status(400).json({
      success: false,
      message: "tour_id ไม่ถูกต้อง",
    });
  }

  try {
    // ================================================
    // TOUR
    // ================================================
    const [tourRows] = await conn.query(
      `
      SELECT
        t.*,
        c.country_name_th
      FROM tour t
      LEFT JOIN country c
        ON c.country_id = t.country_id
      WHERE t.tour_id = ?
      LIMIT 1
      `,
      [tourId]
    );

    if (tourRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลทัวร์",
      });
    }

    // ================================================
    // TOUR IMAGE
    // ================================================
    const [imageRows] = await conn.query(
      `
      SELECT *
      FROM tour_image
      WHERE tour_id = ?
      `,
      [tourId]
    );

    // ================================================
    // TOUR DETAIL
    // ================================================
    const [detailRows] = await conn.query(
      `
      SELECT *
      FROM tour_detail
      WHERE tour_id = ?
      ORDER BY day_number ASC
      `,
      [tourId]
    );

    // ================================================
    // TOUR ROUND
    // ================================================
    const [roundRows] = await conn.query(
      `
      SELECT
        tr.*,
        g.guide_code,
        g.first_name AS guide_first_name,
        g.last_name AS guide_last_name
      FROM tour_round tr
      LEFT JOIN guide g
        ON g.guide_id = tr.guide_id
      WHERE tr.tour_id = ?
      ORDER BY tr.start_date ASC, tr.round_id ASC
      `,
      [tourId]
    );

    return res.status(200).json({
      success: true,
      data: {
        tour: tourRows[0],
        images: imageRows,
        details: detailRows,
        rounds: roundRows,
      },
    });

  } catch (error) {
    console.error("❌ GET /manage-tour/:tourId error:", error);

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถโหลดรายละเอียดทัวร์ได้",
    });
  }
});




// ==========================================================
// PUT : แก้ไขข้อมูล Tour
// ==========================================================
router.put("/:tourId",
  tourUpload.fields([
    { name: "tour_images", maxCount: 20 },
    { name: "video", maxCount: 1 },
    { name: "pdf_file", maxCount: 1 },
  ]),
  async (req, res) => {
    const connection = await conn.getConnection();

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
      // 2. รับข้อมูลจาก FormData
      // ==========================================================

      const {
        tour_name,
        tour_code,
        country_id,
        type,
        duration_day,
        price,
        promotion,
        condition_detail,
        condition_mode,
        include_flight,
        status,
        tour_details,
        keep_image_ids,
        cloud_image_ids,
      } = req.body || {};
      console.log("====================================");
      console.log("EDIT TOUR REQUEST");
      console.log("tourId =", tourId);
      console.log("req.body =", req.body);
      console.log("req.files =", req.files);
      console.log("====================================");

      // ==========================================================
      // 3. ตรวจสอบข้อมูลหลัก
      // ==========================================================

      if (!tour_name || tour_name.trim() === "") {
        return res.status(400).json({
          success: false,
          message: "กรุณากรอกชื่อทัวร์",
        });
      }

      if (!country_id || isNaN(Number(country_id))) {
        return res.status(400).json({
          success: false,
          message: "กรุณาเลือกประเทศ",
        });
      }

      if (!duration_day || Number(duration_day) < 1) {
        return res.status(400).json({
          success: false,
          message: "จำนวนวันไม่ถูกต้อง",
        });
      }

      if (
        price === undefined ||
        price === null ||
        price === "" ||
        isNaN(Number(price))
      ) {
        return res.status(400).json({
          success: false,
          message: "ราคาทัวร์ไม่ถูกต้อง",
        });
      }

      const normalizedType =
        type === "ต่างประเทศ" ? "นอกประเทศ" : type || "ในประเทศ";

      const normalizedStatus =
        status === "Active" ? "open" : status || "open";

      const normalizedIncludeFlight =
        include_flight || "ไม่รวม";

      // ==========================================================
      // 4. แปลง tour_details
      // ==========================================================

      let details = [];

      if (tour_details) {
        try {
          details =
            typeof tour_details === "string"
              ? JSON.parse(tour_details)
              : tour_details;
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: "รูปแบบ tour_details ไม่ถูกต้อง",
          });
        }
      }

      if (!Array.isArray(details)) {
        details = [];
      }

      // ==========================================================
      // 5. แปลง keep_image_ids
      // ==========================================================

      let keepImageIds = [];

      if (keep_image_ids) {
        try {
          const parsed =
            typeof keep_image_ids === "string"
              ? JSON.parse(keep_image_ids)
              : keep_image_ids;

          if (Array.isArray(parsed)) {
            keepImageIds = parsed
              .map((id) => Number(id))
              .filter((id) => Number.isInteger(id) && id > 0);
          }
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: "รูปแบบ keep_image_ids ไม่ถูกต้อง",
          });
        }
      }

      // ==========================================================
// รูปที่เลือกจาก Cloudinary สำหรับทัวร์ที่กำลังแก้ไข
// ==========================================================

let cloudImageIds = [];

if (cloud_image_ids) {
  try {
    const parsed =
      typeof cloud_image_ids === "string"
        ? JSON.parse(cloud_image_ids)
        : cloud_image_ids;

    if (!Array.isArray(parsed)) {
      return res.status(400).json({
        success: false,
        message: "รูปแบบรายการรูปภาพ Cloudinary ไม่ถูกต้อง",
      });
    }

    cloudImageIds = parsed;
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: "ไม่สามารถอ่านรายการรูปภาพ Cloudinary ได้",
    });
  }
}

let selectedCloudImages = [];

try {
  selectedCloudImages =
    await resolveTourCloudImages(cloudImageIds);
} catch (error) {
  console.error("Resolve Cloudinary images error:", error);

  return res.status(400).json({
    success: false,
    message:
      "มีรูปภาพจาก Cloudinary ที่ไม่ถูกต้องหรือไม่สามารถใช้งานได้",
  });
}

      // ==========================================================
      // 6. ดึงข้อมูลเดิมของ Tour
      // ==========================================================

const [existingTourRows] = await connection.query(
  `
  SELECT
    tour_id,
    tour_code,
    condition_detail,
    status,
    video,
    pdf_file
  FROM tour
  WHERE tour_id = ?
  LIMIT 1
  `,
  [tourIdNumber]
);

      if (existingTourRows.length === 0) {
        return res.status(404).json({
          success: false,
          message: "ไม่พบข้อมูลทัวร์",
        });
      }

      const existingTour = existingTourRows[0];

      // ตรวจสอบรหัสโปรแกรมทัวร์
const normalizedTourCode = String(
  tour_code ?? existingTour.tour_code ?? ""
).trim();

if (!normalizedTourCode) {
  return res.status(400).json({
    success: false,
    message: "กรุณากรอกรหัสโปรแกรมทัวร์",
  });
}

if (normalizedTourCode.length > 50) {
  return res.status(400).json({
    success: false,
    message: "รหัสโปรแกรมทัวร์ต้องไม่เกิน 50 ตัวอักษร",
  });
}

// ตรวจรหัสซ้ำ โดยไม่นับทัวร์รายการที่กำลังแก้ไข
const [duplicateTourCodes] = await connection.query(
  `
  SELECT tour_id
  FROM tour
  WHERE tour_code = ?
    AND tour_id <> ?
  LIMIT 1
  `,
  [normalizedTourCode, tourIdNumber]
);

if (duplicateTourCodes.length > 0) {
  return res.status(409).json({
    success: false,
    message: "รหัสโปรแกรมทัวร์นี้มีอยู่แล้ว กรุณาใช้รหัสอื่น",
  });
}

// เลือกเงื่อนไขสำหรับบันทึก
const submittedCondition =
  typeof condition_detail === "string"
    ? condition_detail.trim()
    : "";

let normalizedConditionDetail;

if (condition_mode === "default") {
  normalizedConditionDetail = DEFAULT_CONDITION_DETAIL;
} else if (condition_mode === "custom") {
  normalizedConditionDetail =
    submittedCondition || DEFAULT_CONDITION_DETAIL;
} else {
  // รองรับกรณีที่ยังมี Client รุ่นเก่าส่งข้อมูลมา
  normalizedConditionDetail =
    submittedCondition ||
    String(existingTour.condition_detail ?? "").trim() ||
    DEFAULT_CONDITION_DETAIL;
}

      // ==========================================================
      // 7. รับไฟล์ใหม่จาก Cloudinary
      // ==========================================================

      const imageFiles = req.files?.tour_images || [];
const videoFiles = req.files?.video || [];
const pdfFiles = req.files?.pdf_file || [];

const removeExistingVideo =
  req.body?.remove_existing_video === "true";

const removeExistingPdf =
  req.body?.remove_existing_pdf === "true";

const videoUrl = videoFiles.length > 0
  ? videoFiles[0].path
  : removeExistingVideo
    ? null
    : existingTour.video || null;

const pdfUrl = pdfFiles.length > 0
  ? pdfFiles[0].path
  : removeExistingPdf
    ? null
    : existingTour.pdf_file || null;

      // ==========================================================
      // 8. เริ่ม Transaction
      // ==========================================================

      await connection.beginTransaction();

      // ==========================================================
// ตรวจสอบเงื่อนไขก่อนปิดโปรแกรมทัวร์
// ==========================================================

if (
  normalizedStatus === "closed" &&
  existingTour.status !== "closed"
) {
  const [blockedRounds] = await connection.query(
    `
    SELECT
      tr.round_id,
      tr.status,
      COUNT(b.booking_id) AS booking_count
    FROM tour_round tr
    LEFT JOIN booking b
      ON b.round_id = tr.round_id
    WHERE tr.tour_id = ?
    GROUP BY tr.round_id, tr.status
    HAVING NOT (
      tr.status = 'success'
      OR (
        tr.status = 'open'
        AND COUNT(b.booking_id) = 0
      )
    )
    `,
    [tourIdNumber]
  );

  if (blockedRounds.length > 0) {
    await connection.rollback();

    return res.status(409).json({
      success: false,
      message:
        "ไม่สามารถปิดโปรแกรมทัวร์ได้ เนื่องจากมีรอบทัวร์ที่ไม่ผ่านเงื่อนไข กรุณาตรวจสอบสถานะรอบทัวร์และรายการจอง",
      data: blockedRounds,
    });
  }
}

      // ==========================================================
      // 9. Update ตาราง tour
      // ==========================================================

      await connection.query(
  `
  UPDATE tour
  SET
    tour_name = ?,
    tour_code = ?,
    country_id = ?,
    type = ?,
    duration_day = ?,
    price = ?,
    video = ?,
    promotion = ?,
    condition_detail = ?,
    include_flight = ?,
    pdf_file = ?,
    status = ?
  WHERE tour_id = ?
  `,
  [
    tour_name.trim(),
    normalizedTourCode,
    Number(country_id),
    normalizedType,
    Number(duration_day),
    Number(price),
    videoUrl,
    promotion || null,
    normalizedConditionDetail,
    normalizedIncludeFlight,
    pdfUrl,
    normalizedStatus,
    tourIdNumber,
  ]
);

      // ==========================================================
      // 10. ลบรูปเก่าที่ผู้ใช้เอาออก
      // ==========================================================

      if (keepImageIds.length === 0) {
        await connection.query(
          `
          DELETE FROM tour_image
          WHERE tour_id = ?
          `,
          [tourIdNumber]
        );
      } else {
        const placeholders = keepImageIds.map(() => "?").join(",");

        await connection.query(
          `
          DELETE FROM tour_image
          WHERE tour_id = ?
            AND img_id NOT IN (${placeholders})
          `,
          [tourIdNumber, ...keepImageIds]
        );
      }

      // ==========================================================
// 11. เพิ่มรูปจากเครื่องและ Cloudinary
// โดยไม่เพิ่ม URL ซ้ำกับรูปที่ยังเก็บอยู่
// ==========================================================

// หลังจากลบรูปที่ไม่ต้องการแล้ว รูปที่ยังอยู่ในตารางคือรูปที่เก็บไว้
const [retainedImageRows] = await connection.query(
  `
  SELECT image
  FROM tour_image
  WHERE tour_id = ?
  `,
  [tourIdNumber]
);

const retainedImageUrls = new Set(
  retainedImageRows.map((row) => row.image)
);

const candidateImageUrls = [
  ...(imageFiles ?? []).map((file) => file.path),
  ...selectedCloudImages.map((image) => image.secure_url),
].filter(Boolean);

const newImageUrls = [
  ...new Set(candidateImageUrls)
].filter((imageUrl) => !retainedImageUrls.has(imageUrl));

// เพิ่มรูปใหม่เป็นชุด ๆ โดยไม่จำกัดไว้แค่ 20 รูปจาก Cloudinary
for (let i = 0; i < newImageUrls.length; i += 500) {
  const batch = newImageUrls.slice(i, i + 500);

  const imageValues = batch.map((imageUrl) => [
    tourIdNumber,
    imageUrl,
  ]);

  await connection.query(
    `
    INSERT INTO tour_image (
      tour_id,
      image
    )
    VALUES ?
    `,
    [imageValues]
  );
}

      // ==========================================================
      // 12. ลบรายละเอียดรายวันเดิม
      // ==========================================================

      await connection.query(
        `
        DELETE FROM tour_detail
        WHERE tour_id = ?
        `,
        [tourIdNumber]
      );

      // ==========================================================
      // 13. เพิ่มรายละเอียดรายวันใหม่
      // ==========================================================

      if (details.length > 0) {
        const detailValues = details.map((detail, index) => [
          tourIdNumber,
          Number(detail.day_number) || index + 1,
          detail.day_detail || null,
          detail.location || null,
          detail.travel || null,
          detail.hotel || null,
          detail.meal_detail || null,
          detail.restaurant_detail || null,
        ]);

        await connection.query(
          `
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
          `,
          [detailValues]
        );
      }

      // ==========================================================
      // 14. Commit
      // ==========================================================

      await connection.commit();

      console.log("====================================");
      console.log("UPDATE TOUR SUCCESS");
      console.log("tour_id =", tourIdNumber);
      console.log("image_count =", imageFiles.length);
      console.log("detail_count =", details.length);
      console.log("====================================");

      return res.status(200).json({
        success: true,
        message: "แก้ไขข้อมูลทัวร์สำเร็จ",
        data: {
          tour_id: tourIdNumber,
          video: videoUrl,
          pdf_file: pdfUrl,
          image_count: imageFiles.length,
          detail_count: details.length,
        },
      });
    } catch (error) {
      await connection.rollback();

      console.error("Update Tour Error:", error);

      return res.status(500).json({
        success: false,
        message: "เกิดข้อผิดพลาดในการแก้ไขข้อมูลทัวร์",
        error: error.message,
      });
    } finally {
      connection.release();
    }
  }
);
/*
==========================================================
DELETE /manage-tour/:tourId
ลบทัวร์แบบปลอดภัย

เงื่อนไข:
1. ถ้ามี booking -> ห้ามลบ
2. ถ้ามี review  -> ห้ามลบ
3. ถ้าไม่มี -> ลบข้อมูลที่เกี่ยวข้องแล้วลบ tour
==========================================================
*/
router.delete("/:tourId", async (req, res) => {
  const tourId = Number(req.params.tourId);

  if (!tourId || Number.isNaN(tourId)) {
    return res.status(400).json({
      success: false,
      message: "tour_id ไม่ถูกต้อง",
    });
  }

  const connection = await conn.getConnection();

  try {
    // ================================================
    // ตรวจว่า Tour มีอยู่หรือไม่
    // ================================================
    const [tourRows] = await connection.query(
      `
      SELECT tour_id, tour_name
      FROM tour
      WHERE tour_id = ?
      LIMIT 1
      `,
      [tourId]
    );

    if (tourRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลทัวร์",
      });
    }

    // ================================================
    // ตรวจ Booking
    // ================================================
    const [bookingRows] = await connection.query(
      `
      SELECT COUNT(*) AS total
      FROM booking b
      INNER JOIN tour_round tr
        ON tr.round_id = b.round_id
      WHERE tr.tour_id = ?
      `,
      [tourId]
    );

    const bookingCount = Number(bookingRows[0].total || 0);

    if (bookingCount > 0) {
      return res.status(409).json({
        success: false,
        message:
          "ไม่สามารถลบทัวร์นี้ได้ เพราะมีประวัติการจองอยู่แล้ว กรุณาเปลี่ยนสถานะทัวร์เป็น closed แทน",
        booking_count: bookingCount,
      });
    }

    // ================================================
    // ตรวจ Review
    // ================================================
    const [reviewRows] = await connection.query(
      `
      SELECT COUNT(*) AS total
      FROM review
      WHERE tour_id = ?
      `,
      [tourId]
    );

    const reviewCount = Number(reviewRows[0].total || 0);

    if (reviewCount > 0) {
      return res.status(409).json({
        success: false,
        message:
          "ไม่สามารถลบทัวร์นี้ได้ เพราะมีรีวิวอยู่แล้ว กรุณาเปลี่ยนสถานะทัวร์เป็น closed แทน",
        review_count: reviewCount,
      });
    }

    // ================================================
    // เริ่ม Transaction
    // ================================================
    await connection.beginTransaction();

    // ================================================
    // ลบ Favorite ก่อน
    // ================================================
    

    // ================================================
    // ลบรูป
    // ================================================
    await connection.query(
      `
      DELETE FROM tour_image
      WHERE tour_id = ?
      `,
      [tourId]
    );

    // ================================================
    // ลบรายละเอียดแต่ละวัน
    // ================================================
    await connection.query(
      `
      DELETE FROM tour_detail
      WHERE tour_id = ?
      `,
      [tourId]
    );

    // ================================================
    // ลบรอบทัวร์
    // ================================================
    await connection.query(
      `
      DELETE FROM tour_round
      WHERE tour_id = ?
      `,
      [tourId]
    );

    // ================================================
    // ลบทัวร์
    // ================================================
    await connection.query(
      `
      DELETE FROM tour
      WHERE tour_id = ?
      `,
      [tourId]
    );

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: "ลบทัวร์สำเร็จ",
      tour_id: tourId,
    });

  } catch (error) {

    await connection.rollback();

    console.error("❌ DELETE /manage-tour/:tourId error:", error);

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถลบทัวร์ได้",
      error: error.message,
      code: error.code,
      sqlMessage: error.sqlMessage,
    });

  } finally {
    connection.release();
  }
});