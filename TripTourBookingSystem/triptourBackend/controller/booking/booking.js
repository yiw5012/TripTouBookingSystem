import express from 'express';
import generatePayload from 'promptpay-qr';
import { conn } from '../../config/db.js';
import admin from "../../config/firebase.js";
import { upload as cloudUpload } from '../middleware/upload.js';
import { checkAndUpdateRoundStatus } from '../../controller/booking/checkround_status.js';


export const router = express.Router();
const PROMPTPAY_ID = process.env.PROMPTPAY_ID;
const upload = cloudUpload;

// ==========================================================
// เพิ่มสมาชิกที่ชำระเงินแล้วเข้า Group Chat ของรอบทัวร์
// ==========================================================
async function addMemberToRoundChat(memberUid, roundId) {
  if (!memberUid) {
    throw new Error("ไม่พบ Firebase UID ของสมาชิก");
  }

  if (!roundId) {
    throw new Error("ไม่พบ round_id");
  }

  const roomId = `round_${roundId}`;

  const db = admin.database();

  // ตรวจว่าห้องของรอบนี้มีอยู่จริง
  const roomSnapshot = await db
    .ref(`rooms/${roomId}`)
    .once("value");

  if (!roomSnapshot.exists()) {
    throw new Error(
      `ไม่พบห้อง Chat ของรอบ ${roundId} (${roomId})`
    );
  }

  // เพิ่มสมาชิกเข้า room
  // และเพิ่ม room เข้า user_rooms
  const updates = {
    [`rooms/${roomId}/members/${memberUid}`]: "user",
    [`user_rooms/${memberUid}/${roomId}`]: true,
  };

  await db.ref().update(updates);

  console.log("====================================");
  console.log("ADD MEMBER TO ROUND CHAT SUCCESS");
  console.log("memberUid =", memberUid);
  console.log("roundId =", roundId);
  console.log("roomId =", roomId);
  console.log("====================================");

  return roomId;
}

const ROOM_TYPE_VALUES = ['single', 'double', 'triple', 'shared_double', 'shared_triple', 'child'];

async function getOccupiedSeatCount(connection, roundId, excludeBookingId = null) {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(seat_count), 0) AS occupied
     FROM (
       SELECT 1 + COUNT(p.passenger_id) AS seat_count
       FROM booking b
       LEFT JOIN passenger p ON p.booking_id = b.booking_id
       WHERE b.round_id = ?
         AND (? IS NULL OR b.booking_id <> ?)
         AND LOWER(b.payment_status) NOT IN ('expired', 'cancelled', 'rejected')
         AND LOWER(b.status) NOT IN ('cancelled', 'reject', 'expired')
       GROUP BY b.booking_id
     ) t`,
    [roundId, excludeBookingId, excludeBookingId],
  );

  return Number(rows[0]?.occupied || 0);
}

function normalizeRoomSelections(rawRooms = []) {
  if (!Array.isArray(rawRooms)) return [];

  return rawRooms
    .map((room) => {
      const rawRoomType = String(room?.room_type ?? room?.roomType ?? room?.type ?? '').trim().toLowerCase();
      const quantity = Number(room?.quantity ?? 0);

      if (!ROOM_TYPE_VALUES.includes(rawRoomType) || !Number.isInteger(quantity) || quantity <= 0) {
        return null;
      }

      return [rawRoomType, quantity];
    })
    .filter(Boolean);
}

async function saveBookingRooms(connection, bookingId, rawRooms = []) {
  if (!bookingId) {
    return [];
  }

  const normalizedRooms = normalizeRoomSelections(rawRooms);

  await connection.query('DELETE FROM room WHERE booking_id = ?', [bookingId]);

  if (normalizedRooms.length === 0) {
    return [];
  }

  const values = normalizedRooms.map(([roomType, quantity]) => [bookingId, roomType, quantity]);
   console.log("Saving rooms for bookingId:", bookingId, "Rooms:", values);
  await connection.query(
    'INSERT INTO room (booking_id, room_type, quantity) VALUES ?',
    [values]
  );

  return values;
}

// 1. สร้างรายการจองใหม่ (บันทึกลงตาราง booking)
router.post('/create-order', async (req, res) => {
  let connection;

  try {
    const requestBody = req.body || {};
    const member_id = requestBody.member_id ?? requestBody.booking?.member_id;
    const round_id = requestBody.round_id ?? requestBody.booking?.round_id;
    const total_price = requestBody.total_price ?? requestBody.booking?.total_price;
    const rooms = Array.isArray(requestBody.rooms)
      ? requestBody.rooms
      : Array.isArray(requestBody.booking?.rooms)
        ? requestBody.booking.rooms
        : [];

    console.log("Received create-order request:", { member_id, round_id, total_price, rooms });

    if (!member_id || !round_id || !total_price) {
      return res.status(400).json({
        success: false,
        message: 'member_id, round_id, and total_price are required',
      });
    }

    connection = await conn.getConnection();
    await connection.beginTransaction();

    const [roundRows] = await connection.query(
      `SELECT count, status FROM tour_round WHERE round_id = ? FOR UPDATE`,
      [round_id],
    );

    if (!roundRows || roundRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Round not found',
      });
    }

    const roundCapacity = Number(roundRows[0].count || 0);
    const occupiedSeats = await getOccupiedSeatCount(connection, round_id);
    const remainingSeats = Math.max(roundCapacity - occupiedSeats, 0);

    if (roundRows[0].status === 'closed') {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'ไม่สามารถจองได้เนื่องจากที่นั่งเต็มแล้ว',
      });
    }

    if (remainingSeats === 1) {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'รอบทัวร์เหลือที่นั่งเพียง 1 คน กรุณาทำรายการใหม่อีกครั้ง',
      });
    }

    if (occupiedSeats >= roundCapacity) {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'ไม่สามารถจองได้เนื่องจากที่นั่งเต็มแล้ว',
      });
    }

    const now = new Date();
    const EXPIRE_MINUTES = 3;
    const expireAt = new Date(now.getTime() + EXPIRE_MINUTES * 60 * 1000);

    const [result] = await connection.query(
      `INSERT INTO booking (member_id, round_id, booking_date, total_price, status, payment_status, slip_image, payment_date)
       VALUES (?, ?, ?, ?, 'pending', 'pending', NULL, NULL)`,
      [member_id, round_id, now, total_price],
    );

    const bookingId = result.insertId;

    if (Array.isArray(rooms) && rooms.length > 0) {
      await saveBookingRooms(connection, bookingId, rooms);
    }

    await connection.commit();

    const qrPayload = generatePayload(PROMPTPAY_ID, { amount: Number(total_price) || 0 });

    return res.status(200).json({
      success: true,
      data: {
        order_id: bookingId,
        booking_id: bookingId,
        amount: total_price,
        status: 'pending',
        payment_status: 'pending',
        qr_code: qrPayload,
        created_at: now.toISOString(),
        expire_at: expireAt.toISOString(),
      },
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Create booking error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  } finally {
    if (connection) connection.release();
  }
});

// 2. ดึงสถานะการจองตาม booking_id
router.get('/status/:bookingId', async (req, res) => {
  try {
    const { bookingId } = req.params;
    const [rows] = await conn.query(
      `SELECT booking_id, member_id, round_id, booking_date, total_price, status, payment_status, payment_date, slip_image 
       FROM booking WHERE booking_id = ?`,
      [bookingId]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const booking = rows[0];    
    const EXPIRE_MINUTES = 3; 
    const bookingDate = new Date(booking.booking_date);
    const expireAt = new Date(bookingDate.getTime() + EXPIRE_MINUTES * 60 * 1000);
    const now = new Date();

    let currentPaymentStatus = booking.payment_status;

    // ตรวจสอบหมดอายุเฉพาะเมื่อสถานะยังเป็น pending
    if (now >= expireAt && currentPaymentStatus === 'pending') {
      currentPaymentStatus = 'expired';
      
      await conn.query(
        `UPDATE booking SET status = 'reject', payment_status = 'expired' WHERE booking_id = ?`,
        [bookingId]
      );
    }

    // สร้าง PromptPay QR Code ใหม่เฉพาะเมื่อสถานะยังเป็น pending
    let qrPayload = null;
    if (currentPaymentStatus === 'pending') {
      qrPayload = generatePayload(PROMPTPAY_ID, {
        amount: Number(booking.total_price) || 0,
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        slip_image: booking.slip_image,
        booking_id: booking.booking_id,
        status: booking.status,
        payment_status: currentPaymentStatus,
        total_price: booking.total_price,
        qr_code: qrPayload,
        booking_date: bookingDate.toISOString(),
        created_at: bookingDate.toISOString(),
        expire_at: expireAt.toISOString(),
      },
    });
  } catch (error) {
    console.error('Get booking status error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.post('/confirm-payment', upload.single('slip_image'), async (req, res) => {
  let connection;
  try {

    const booking_id = req.body?.booking_id ?? req.body?.bookingId;
    const uploadedFile = req.file;
    
  
    if (!booking_id || !uploadedFile) {
      return res.status(400).json({
        success: false,
        message: 'booking_id and slip_image are required',
      });
    }

    const slip_image = uploadedFile.path ;
    if (!slip_image) {
      return res.status(400).json({
        success: false,
        message: 'Cloud upload did not return an image URL',
      });
    }

    // 1. ดึง Connection ออกมาจาก Pool เพื่อเริ่ม Transaction
    connection = await conn.getConnection();
    await connection.beginTransaction();

    const [bookingRows] = await connection.query(
      `SELECT b.booking_id, b.round_id, b.payment_status,
              1 + COUNT(p.passenger_id) AS passenger_count
       FROM booking b
       LEFT JOIN passenger p ON p.booking_id = b.booking_id
       WHERE b.booking_id = ?
       GROUP BY b.booking_id, b.round_id, b.payment_status
       FOR UPDATE`,
      [booking_id],
    );

    const booking = bookingRows[0];

    if (!booking) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (booking.payment_status === 'expired') {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Booking has expired' });
    }

    if (booking.payment_status === 'paid') {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Booking is already paid' });
    }

    const [roundRows] = await connection.query(
      `SELECT count, status FROM tour_round WHERE round_id = ? FOR UPDATE`,
      [booking.round_id],
    );

    if (!roundRows || roundRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Tour round not found' });
    }

    const roundCount = Number(roundRows[0].count || 0);
    const occupiedWithoutCurrent = await getOccupiedSeatCount(connection, booking.round_id, booking_id);
    const currentSeatCount = Number(booking.passenger_count || 1);

    if (roundRows[0].status === 'closed' || occupiedWithoutCurrent + currentSeatCount > roundCount) {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'ที่นั่งเต็มแล้ว ไม่สามารถยืนยันการชำระเงินได้',
      });
    }

    await connection.query(
      `UPDATE booking 
       SET slip_image = ?, payment_status = 'paid', payment_date = NOW() 
       WHERE booking_id = ?`,
      [slip_image, booking_id],
    );

    const roundSummary = await checkAndUpdateRoundStatus(connection, booking.round_id);
    await connection.commit();
    console.log('roundtourSummary : ', roundSummary);
    return res.status(200).json({
      success: true,
      message: 'Payment slip submitted successfully',
      data: {
        booking_id,
        slip_image,
        payment_status: 'paid',
        passenger_count: Number(booking.passenger_count),
        round_info: roundSummary,
      },
    });
  } catch (error) {
    console.error('Confirm payment error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// ==========================================================
// 4.0 Admin - ดึงรายการจองทั้งหมด
// ใช้สำหรับหน้า "จัดการการจอง"
// ==========================================================

router.get('/admin/all-bookings', async (req, res) => {
  try {

    const [rows] = await conn.query(`
      SELECT
        b.booking_id,
        b.member_id,
        b.round_id,
        b.booking_date,
        b.total_price,
        b.status,
        b.payment_status,
        b.payment_date,
        b.slip_image,

        t.tour_id,
        t.tour_name,

        r.start_date,
        r.end_date,
        r.departure,
        r.destination,
        r.airline,
        r.flight

      FROM booking b

      LEFT JOIN tour_round r
        ON b.round_id = r.round_id

      LEFT JOIN tour t
        ON r.tour_id = t.tour_id

      ORDER BY b.booking_date DESC
    `);

    return res.status(200).json({
      success: true,
      data: rows,
    });

  } catch (error) {

    console.error(
      '❌ Admin all bookings error:',
      error
    );

    return res.status(500).json({
      success: false,
      message: 'ไม่สามารถดึงรายการจองทั้งหมดได้',
      error: error.message,
    });
  }
});

router.get('/admin/confirmed-members/:roundId', async (req, res) => {
  const roundId = Number(req.params.roundId);

  if (!roundId || Number.isNaN(roundId)) {
    return res.status(400).json({
      success: false,
      message: 'round_id ไม่ถูกต้อง',
    });
  }

  try {
    const [rows] = await conn.query(
      `
      SELECT
        b.booking_id,
        b.member_id,
        b.round_id,
        b.booking_date,
        b.total_price,
        b.status,
        b.payment_status,
        m.first_name,
        m.last_name,
        m.email,
        m.phone,
        m.gender,
        m.number_id,
        m.birthday,
        m.address,
        m.medicine,
        m.congenital_disease,
        m.allergic_list,
        m.others,
        CONCAT_WS(' ', m.first_name, m.last_name) AS display_name
      FROM booking b
      INNER JOIN member m
        ON m.member_id = b.member_id
      WHERE b.round_id = ?
        AND b.status = 'confirmed'
        AND b.payment_status = 'paid'
      ORDER BY b.booking_date ASC, b.booking_id ASC
      `,
      [roundId]
    );

    return res.status(200).json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('❌ Admin confirmed members error:', error);

    return res.status(500).json({
      success: false,
      message: 'ไม่สามารถดึงรายชื่อผู้เดินทางที่ยืนยันแล้วได้',
      error: error.message,
    });
  }
});

// ==========================================================
// 4.1 Admin - ดึงรายการจองที่รอตรวจสอบการชำระเงิน
// ==========================================================
router.get('/admin/pending-payments', async (req, res) => {
  try {
    const [rows] = await conn.query(
      `
      SELECT
  b.booking_id,
  b.member_id,
  b.round_id,
  b.booking_date,
  b.total_price,
  b.status,
  b.payment_status,
  b.payment_date,
  b.slip_image,

  t.tour_id,
  t.tour_name,

  r.start_date,
  r.end_date,
  r.departure,
  r.destination,
  r.airline,
  r.flight

FROM booking b
INNER JOIN tour_round r ON b.round_id = r.round_id
INNER JOIN tour t ON r.tour_id = t.tour_id

WHERE b.payment_status = 'paid'
AND b.status = 'pending'
 	
  
ORDER BY b.booking_date DESC;
      `
    );
    console.log(rows)
    return res.status(200).json({
      success: true,
      data: rows,
    });

  } catch (error) {
    console.error(
      '❌ Admin pending payments error:',
      error
    );

    return res.status(500).json({
      success: false,
      message: 'ไม่สามารถดึงรายการรอตรวจสอบได้',
      error: error.message,
    });
  }
});
// 4. แอดมินตรวจสอบสลิปและกดอนุมัติ/ปฏิเสธ
// ==========================================================
router.post('/admin/verify-slip', async (req, res) => {
  try {
    const { booking_id, action } = req.body || {};

    // ================================================
    // 1. ตรวจข้อมูลที่ส่งเข้ามา
    // ================================================
    if (!booking_id || !action) {
      return res.status(400).json({
        success: false,
        message: 'booking_id and action are required',
      });
    }

    if (action !== 'approve' && action !== 'reject') {
      return res.status(400).json({
        success: false,
        message: "action ต้องเป็น 'approve' หรือ 'reject'",
      });
    }

    // ================================================
    // 2. ดึงข้อมูล Booking + Member Firebase UID
    // ================================================
    const [bookingRows] = await conn.query(
      `
      SELECT
        b.booking_id,
        b.member_id,
        b.round_id,
        b.status,
        b.payment_status,
        b.slip_image,
        m.google_id
      FROM booking b
      INNER JOIN member m
        ON m.member_id = b.member_id
      WHERE b.booking_id = ?
      LIMIT 1
      `,
      [booking_id]
    );

    if (bookingRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบรายการจอง',
      });
    }

    const booking = bookingRows[0];

    // ================================================
    // 3. ต้องมีสลิปก่อนจึงตรวจสอบได้
    // ================================================
    if (!booking.slip_image) {
      return res.status(400).json({
        success: false,
        message: 'รายการจองนี้ยังไม่มีสลิปสำหรับตรวจสอบ',
      });
    }

    // ================================================
    // 4. APPROVE
    // ================================================
    if (action === 'approve') {

      // ต้องมี Firebase UID
      if (!booking.google_id) {
        return res.status(400).json({
          success: false,
          message:
            'ไม่พบ Firebase UID ของสมาชิก (member.google_id)',
        });
      }

      // ----------------------------------------------
      // 4.1 อัปเดตสถานะ MySQL
      // ----------------------------------------------
      await conn.query(
        `
        UPDATE booking
        SET
          payment_status = 'paid',
          status = 'confirmed',
          payment_date = NOW()
        WHERE booking_id = ?
        `,
        [booking_id]
      );

      // ----------------------------------------------
      // 4.2 เพิ่มสมาชิกเข้า Firebase Group Chat
      // ----------------------------------------------
      let chatRoomId;

      try {
        chatRoomId = await addMemberToRoundChat(
          booking.google_id,
          booking.round_id
        );
      } catch (firebaseError) {

        console.error(
          '❌ Firebase add member error:',
          firebaseError
        );

        return res.status(500).json({
          success: false,
          message:
            'อนุมัติการชำระเงินแล้ว แต่ไม่สามารถเพิ่มสมาชิกเข้า Group Chat ได้',
          error: firebaseError.message,
        });
      }

      // ----------------------------------------------
      // 4.3 สำเร็จ
      // ----------------------------------------------
      return res.status(200).json({
        success: true,
        message:
          'อนุมัติการชำระเงินและเพิ่มสมาชิกเข้า Group Chat สำเร็จ',
        data: {
          booking_id: booking.booking_id,
          member_id: booking.member_id,
          round_id: booking.round_id,
          firebase_uid: booking.google_id,
          chat_room_id: chatRoomId,
          status: 'confirmed',
          payment_status: 'paid',
        },
      });
    }

    // ================================================
    // 5. REJECT
    // ================================================
    await conn.query(
      `
      UPDATE booking
      SET
        payment_status = 'cancelled',
        status = 'cancelled'
      WHERE booking_id = ?
      `,
      [booking_id]
    );

    return res.status(200).json({
      success: true,
      message: 'ปฏิเสธการชำระเงินเรียบร้อยแล้ว และที่นั่งถูกปล่อยคืนให้สามารถจองใหม่ได้',
      data: {
        booking_id: booking.booking_id,
        status: 'cancelled',
        payment_status: 'cancelled',
      },
    });

  } catch (error) {

    console.error(
      'Admin verify slip error:',
      error
    );

    return res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการตรวจสอบการชำระเงิน',
      error: error.message,
    });
  }
});

// POST /api/booking/add-passengers
router.post('/add-passengers', upload.single('passpot_passenger'), async (req, res) => {
  let connection;

  try {
    let payload = {};

    // 1. แกะ Payload ให้รองรับทั้งแบบ Multipart 
    if (req.body.payload) {
      if (typeof req.body.payload === 'string') {
        try {
          payload = JSON.parse(req.body.payload);
        } catch (e) {
          return res.status(400).json({ success: false, message: 'รูปแบบ JSON Payload ไม่ถูกต้อง' });
        }
      } else {
        payload = req.body.payload;
      }
    } else {
      payload = req.body || {};
    }

    const bookingId = payload.booking_id;
    const passengers = payload.passengers || [];
    const roomSelections = payload.rooms || payload.booking?.rooms || [];

    //  ตรวจสอบไฟล์รูปภาพอย่างปลอดภัย 
    const passportFile = req.file;
    const uploadedPassportPath = passportFile ? passportFile.path : null;

    // ตรวจสอบความถูกต้องของข้อมูล
    if (!bookingId || !Array.isArray(passengers) || passengers.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'booking_id and at least one passenger are required',
      });
    }

    connection = await conn.getConnection();
    await connection.beginTransaction();

    // 4. เตรียม Data สำหรับ Bulk Insert
    const values = passengers.map((p) => [
      bookingId,
      p.first_name || null,
      p.last_name || null,
      p.id_card || p.number_id || null,            
      p.gender || null,
      uploadedPassportPath || p.passport_image_path || null,
      p.congenital_disease || null,
      p.medicine || null,
      p.allergic_list || null,
      p.other || p.others || null,
      p.phone || null             
    ]);

    const sql = `
      INSERT INTO passenger 
      (booking_id, first_name, last_name, number_id, gender, image_passport, congenital_disease, medicine, allergic_list, others, phone)
      VALUES ?
    `;

    const [result] = await connection.query(sql, [values]);
    await saveBookingRooms(connection, bookingId, roomSelections);
    await connection.commit();

    return res.status(200).json({
      success: true,
      message: 'Passenger details saved successfully',
      data: {
        booking_id: bookingId,
        insertedRows: result.affectedRows,
      },
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Add passengers error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error',
      error: error.message 
    });
  } finally {
    if (connection) connection.release();
  }
});
// POST /api/booking/cancel
router.post('/cancel', async (req, res) => {
  const { booking_id, member_id } = req.body;

  // 1. ตรวจสอบข้อมูลนำเข้า
  if (!booking_id || !member_id) {
    return res.status(400).json({
      success: false,
      message: 'ต้องระบุ booking_id และ member_id',
    });
  }

  let connection;

  try {
    // 2. ดึง connection จาก Pool
    connection = await conn.getConnection();
    await connection.beginTransaction();

    const [bookingRows] = await connection.query(
      'SELECT booking_id, member_id, payment_status, status FROM booking WHERE booking_id = ? FOR UPDATE',
      [booking_id]
    );

    if (!bookingRows || bookingRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'ไม่พบรายการจองนี้ในระบบ',
      });
    }

    const booking = bookingRows[0];

    // เช็กความเป็นเจ้าของรายการจอง
    if (String(booking.member_id) !== String(member_id)) {
      await connection.rollback();
      return res.status(403).json({
        success: false,
        message: 'คุณไม่มีสิทธิ์ในการยกเลิกรายการจองนี้',
      });
    }

    //อนุญาตให้ยกเลิกเฉพาะรายการที่ยังอยู่ในสถานะ pending
    if (booking.payment_status !== 'pending') {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: `ไม่สามารถยกเลิกได้ เนื่องจากรายการจองอยู่ในสถานะ ${booking.payment_status}`,
      });
    }
    
    await connection.query('DELETE FROM passenger WHERE booking_id = ?', [booking_id]);
    await connection.query('DELETE FROM room WHERE booking_id = ?', [booking_id]);
    await connection.query(
      `UPDATE booking 
       SET status = 'reject', payment_status = 'cancelled' 
       WHERE booking_id = ?`,
      [booking_id]
    );

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: 'ยกเลิกรายการจองเรียบร้อยแล้ว',
      data: {
        booking_id: Number(booking_id),
        status: 'cancelled',
        payment_status: 'cancelled',
      },
    });

  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Cancel booking error:', error);

    return res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการยกเลิกรายการจอง',
      error: error.message,
    });
  } finally {
    // คืน connection เข้า Pool เสมอ
    if (connection) connection.release();
  }
});
router.get('/history/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;

    if (!memberId || memberId === 'undefined' || memberId === 'null') {
      return res.status(400).json({
        success: false,
        message: 'Invalid memberId provided'
      });
    }

    const sql = `
      SELECT 
    b.booking_id,
    b.status AS booking_status,  
    b.payment_status,
    b.total_price,
    b.booking_date,
    b.slip_image,
    b.round_id,
    t.tour_id,
    t.tour_name,
    t.video,
    t.include_flight,
    t.pdf_file,
    t.status AS tour_status  
    
      FROM booking b
      LEFT JOIN tour_round r ON b.round_id = r.round_id
      LEFT JOIN tour t ON r.tour_id = t.tour_id
      WHERE b.member_id = ?
      ORDER BY b.booking_date DESC
    `;

    const [rows] = await conn.execute(sql, [memberId]);
    console.log('Booking history rows:', rows);
    // 🎯 3. ส่งข้อมูลกลับ
    return res.status(200).json({
      success: true,
      data: rows
    });

  } catch (error) {
    console.error('❌ Error in /booking/history:', error.message);
    
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: error.message
    });
  }
});

router.get('/booking/all', async (req, res) => {
  try {
    const query = `
      SELECT 
        b.booking_id,
        b.booking_date,
        b.member_id,
        b.round_id,
        b.total_price,
        b.payment_status,
        b.status,
        b.slip_image,
        r.tour_id,
        t.tour_name,
        r.departure,
        r.destination,
        r.start_date,
        r.end_date,
        r.airline,
        r.flight
      FROM booking b
      LEFT JOIN tour_round r ON b.round_id = r.round_id
      LEFT JOIN tour t ON r.tour_id = t.tour_id
      ORDER BY b.booking_id DESC
    `;
    const [rows] = await db.query(query);
    return res.status(200).json({ statusCode: 200, body: rows });
  } catch (error) {
    console.error('Error fetching bookings:', error);
    return res.status(500).json({ statusCode: 500, message: 'Internal Server Error' });
  }
});
export default router;