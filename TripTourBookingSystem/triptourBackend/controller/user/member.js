import express from "express";
import {conn} from "../../config/db.js";
export const router = express.Router();

router.post("/detail", async (req, res) => {
  try {
    const { targetUid } = req.body;

    if (!targetUid) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุ targetUid ใน request body",
      });
    }

    const [rows] = await conn.query(
      "SELECT * FROM member  WHERE google_id = ?",
      [targetUid]
    );
    const [guiderows] = await conn.query(
      "SELECT * FROM guide  WHERE google_id = ?",
      [targetUid]
    );

    if (rows.length === 0 && guiderows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลสมาชิก",
      });
    }
if (rows.length > 0 && guiderows.length > 0) {
  
      return res.status(400).json({
        success: false,
        message: "พบข้อมูลสมาชิกทั้งในตาราง member และ guide",
      });
    }

    if (rows.length > 0) {

    const member = rows[0];
    try {
     
       const [favoriteRows] = await conn.query(
        `SELECT 
          f.country_id,
          c.country_name_th,
          c.country_name_en
        FROM favorite f
        INNER JOIN country c ON f.country_id = c.country_id
        WHERE f.member_id = ?
        ORDER BY c.country_name_en ASC`,
        [member.member_id]
      );
          console.log("sssssss 11 1  1 2 ")

      return res.json({
        success: true,
        data: {
          ...member,
          favorite_countries: favoriteRows // array ของ [ { country_id, country_name_th, country_name_en }, ... ]
        },
      });
  
 } catch (error) {

     res.status(500).json({
      success: false,
      message: "Database favorite error",
      error: error.message,
    });
 }
      
    }
    if (guiderows.length > 0) {
      res.status(200).json({
      success: true,
      data: guiderows[0]
    });
    }
    // ส่งข้อมูลสมาชิกคนนั้นกลับไป
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Database error",
      error: error.message,
    });
  }
});

router.put("/update", async (req, res) => {
  let connection;
  try {
    const {
      google_id,
      first_name,
      last_name,
      phone,
      number_id,
      birthday,
      address,
      gender,
      medicine,
      congenital_disease,
      allergic_list,
      others,
      image_profile,
      image_passport,
      favorite_countries
    } = req.body;

    // =====================================================
    // ตรวจ google_id
    // =====================================================

    if (!google_id || google_id.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุ google_id",
      });
    }

    // =====================================================
    // ตรวจชื่อ
    // =====================================================

    if (!first_name || first_name.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุชื่อ",
      });
    }
    let formattedGender = null;
    if (gender && typeof gender === 'string') {
      const g = gender.trim().charAt(0).toUpperCase() + gender.trim().slice(1).toLowerCase();
      if (['Male', 'Female', 'Other'].includes(g)) {
        formattedGender = g;
      }
    }

    connection = await conn.getConnection();
    await connection.beginTransaction();

    // =====================================================
    // UPDATE ข้อมูลสมาชิก
    // =====================================================

    const [result] = await connection.query(
      `
      UPDATE member
      SET
        first_name = ?,
        last_name = ?,
        phone = ?,
        number_id = ?,
        birthday = ?,
        address = ?,
        gender = ?,
        medicine = ?,
        congenital_disease = ?,
        allergic_list = ?,
        others = ?,
        image_profile = ?,
        image_passport = ?
      WHERE google_id = ?
      `,
      [
        first_name,
        last_name,
        phone,
        number_id,
        birthday,
        address,
        formattedGender,
        medicine,
        congenital_disease,
        allergic_list,
        others,
        image_profile,
        image_passport,
        google_id,
      ]
    );

    // =====================================================
    // ไม่พบสมาชิก
    // =====================================================

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลสมาชิก",
      });
    }

    // ดึง member_id และจัดการซิงค์รายการประเทศที่ชอบ (favorite)
    const [memberRows] = await connection.query(
      "SELECT member_id FROM member WHERE google_id = ? LIMIT 1",
      [google_id]
    );

    // =====================================================
    // สำเร็จ
    // =====================================================
    if (memberRows.length > 0 && Array.isArray(favorite_countries)) {
      const memberId = memberRows[0].member_id;

      // ลบรายการประเทศเดิมของสมาชิกคนนี้
      await connection.query("DELETE FROM favorite WHERE member_id = ?", [memberId]);

      // กรองเฉพาะ country_id ที่เป็นตัวเลขถูกต้อง
      const cleanCountryIds = [...new Set(
        favorite_countries
          .map(id => Number(id))
          .filter(id => Number.isInteger(id) && id > 0)
      )];

      // Insert รายการใหม่
      if (cleanCountryIds.length > 0) {
        const favValues = cleanCountryIds.map(countryId => [memberId, countryId]);
        await connection.query(
          "INSERT INTO favorite (member_id, country_id) VALUES ?",
          [favValues]
        );
      }
    }

    await connection.commit();


    return res.status(200).json({
      success: true,
      message: "อัปเดตข้อมูลสมาชิกและประเทศที่ชอบสำเร็จ อัปเดตข้อมูลสมาชิกสำเร็จ",
    });

    

  } catch (error) {
    console.error("Update member error:", error);

    res.status(500).json({
      success: false,
      message: "ไม่สามารถอัปเดตข้อมูลสมาชิกได้",
      error: error.message,
    });
  }

});

router.get("/allmember", async (req, res) => {
    try {
      const [rows] = await conn.query("SELECT * FROM member  ");
      const [guiderows] = await conn.query("SELECT * FROM guide  ");

      const combinedRows = [...rows, ...guiderows];

      res.json(combinedRows);
    } catch (err) {
      console.error(err);
      res.status(500).send("Database error");
    }
  });

  
router.patch("/status/:googleId", async (req, res) => {
  try {
    const { googleId } = req.params;
    const { status } = req.body;

    if (!googleId) {
      return res.status(400).json({ success: false, message: "กรุณาระบุ googleId" });
    }

    const allowed = ["active", "inactive"];
    if (!status || !allowed.includes(String(status))) {
      return res.status(400).json({ success: false, message: "status ไม่ถูกต้อง" });
    }

    // เรียกใช้ Helper Function
    const result = await updateUserStatus(googleId, status);
    return res.status(result.statusCode).json(result);

  } catch (error) {
    console.error("Update status error:", error);
    return res.status(500).json({
      success: false,
      message: "ไม่สามารถอัปเดตสถานะได้",
      error: error.message,
    });
  }
});
router.delete("/delete-account", async (req, res) => {
  try {
    const { google_id } = req.body;

    if (!google_id) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุ google_id",
      });
    }

    const result = await updateUserStatus(google_id, "inactive");
    return res.status(result.statusCode).json(result);
  } catch (error) {
    console.error("Delete account error:", error);
    return res.status(500).json({
      success: false,
      message: "เกิดข้อผิดพลาดในการปิดใช้งานบัญชี",
      error: error.message,
    });
  }
});

async function updateUserStatus(googleId, newStatus) {
  let connection;

  try {
    connection = await conn.getConnection();
    await connection.beginTransaction();

    const [memberRows] = await connection.query(
      "SELECT member_id FROM member WHERE google_id = ? LIMIT 1",
      [googleId]
    );

    if (memberRows.length > 0) {
      const memberId = memberRows[0].member_id;

      if (newStatus === "inactive") {
        const [activeBookings] = await connection.query(
          `SELECT COUNT(*) AS active_count
           FROM booking
           WHERE member_id = ?
             AND status IN ('pending', 'confirmed')
             AND LOWER(payment_status) = 'paid'`,
          [memberId]
        );

        if (activeBookings[0].active_count > 0) {
          await connection.rollback();
          return {
            success: false,
            statusCode: 400,
            message: "ไม่สามารถปิดใช้งานบัญชีได้ เนื่องจากมีรายการจองที่ชำระเงินแล้วและกำลังดำเนินอยู่",
          };
        }
      }

      await connection.query(
        "UPDATE member SET status = ? WHERE member_id = ?",
        [newStatus, memberId]
      );

      try {
        await admin.auth().updateUser(googleId, {
          disabled: newStatus === "inactive",
        });
      } catch (fbErr) {
        console.warn(`Firebase Auth update warning (${googleId}):`, fbErr.message);
      }

      await connection.commit();
      return {
        success: true,
        statusCode: 200,
        message: "อัปเดตสถานะสมาชิกสำเร็จ",
        data: { google_id: googleId, status: newStatus, role: "member" },
      };
    }

    const [guideRows] = await connection.query(
      "SELECT guide_id FROM guide WHERE google_id = ? LIMIT 1",
      [googleId]
    );

    if (guideRows.length > 0) {
      await connection.query(
        "UPDATE guide SET status = ? WHERE google_id = ?",
        [newStatus, googleId]
      );

      try {
        await admin.auth().updateUser(googleId, {
          disabled: newStatus === "inactive",
        });
      } catch (fbErr) {
        console.warn(`Firebase Auth update warning (${googleId}):`, fbErr.message);
      }

      await connection.commit();
      return {
        success: true,
        statusCode: 200,
        message: "อัปเดตสถานะไกด์สำเร็จ",
        data: { google_id: googleId, status: newStatus, role: "guide" },
      };
    }

    await connection.rollback();
    return {
      success: false,
      statusCode: 404,
      message: "ไม่พบผู้ใช้ในระบบ",
    };
  } catch (error) {
    if (connection) await connection.rollback();
    throw error;
  } finally {
    if (connection) connection.release();
  }
}
