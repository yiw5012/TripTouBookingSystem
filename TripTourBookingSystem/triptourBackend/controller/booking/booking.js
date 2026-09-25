import express from 'express';
import multer from 'multer';
import generatePayload from 'promptpay-qr';
import { conn } from '../../config/db.js';
import { upload as cloudUpload } from '../middleware/upload.js';
import { checkAndUpdateRoundStatus } from '../../controller/booking/checkround_status.js';


export const router = express.Router();
const PROMPTPAY_ID = process.env.PROMPTPAY_ID;
const upload = cloudUpload;
// 1. สร้างรายการจองใหม่ (บันทึกลงตาราง booking)
router.post('/create-order', async (req, res) => {
  try {
    const { member_id, round_id, total_price } = req.body || {};

    if (!member_id || !round_id || !total_price) {
      return res.status(400).json({
        success: false,
        message: 'member_id, round_id, and total_price are required',
      });
    }

    const now = new Date();
    const EXPIRE_MINUTES = 3; 
    const expireAt = new Date(now.getTime() + EXPIRE_MINUTES * 60 * 1000);

    const [result] = await conn.query(
      `INSERT INTO booking (member_id, round_id, booking_date, total_price, status, payment_status, slip_image, payment_date)
       VALUES (?, ?, ?, ?, 'pending', 'pending', NULL, NULL)`,
      [member_id, round_id, now, total_price]
    );

    const bookingId = result.insertId;

    // สร้าง PromptPay QR Code
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
    console.error('Create booking error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
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

// 3. แนบสลิปชำระเงิน (อัปเดต slip_image, payment_date และเปลี่ยน payment_status เป็น processing)
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

    // 2. ดึงข้อมูลรายการจอง พร้อมสั่ง ล็อก Row (FOR UPDATE)
   const [rows] = await connection.query(
  `SELECT b.booking_id, b.round_id, b.payment_status, 
          (1 + COUNT(p.passenger_id)) AS passenger_count
   FROM booking b
   LEFT JOIN passenger p ON b.booking_id = p.booking_id
   WHERE b.booking_id = ?
   GROUP BY b.booking_id, b.round_id, b.payment_status
   FOR UPDATE`,
  [booking_id],
);
   

    const booking = rows[0];

    if (booking.payment_status === 'expired') {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Booking has expired' });
    }

    if (booking.payment_status === 'paid') {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Booking is already paid' });
    }

    await connection.query(
      `UPDATE booking 
       SET slip_image = ?, payment_status = 'paid', payment_date = NOW() 
       WHERE booking_id = ?`,
      [slip_image, booking_id],
    );

    const roundSummary = await checkAndUpdateRoundStatus(connection, booking.round_id);
    await connection.commit();
    console.log("roundtourSummary : ",roundSummary)
    return res.status(200).json({
      success: true,
      message: 'Payment slip submitted successfully',
      data: {
        booking_id,
        slip_image,
        payment_status: 'paid',
        passenger_count: Number(booking.passenger_count),
        round_info: roundSummary, // ส่งสถานะรอบล่าสุดกลับไปด้วย
      },
    });
  } catch (error) {
    console.error('Confirm payment error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// 4. แอดมิน ตรวจสอบสลิปและกดอนุมัติ/ปฏิเสธ
router.post('/admin/verify-slip', async (req, res) => {
  try {
    const { booking_id, action } = req.body || {}; // action: 'approve' หรือ 'reject'

    if (!booking_id || !action) {
      return res.status(400).json({ success: false, message: 'booking_id and action are required' });
    }

    const nextPaymentStatus = action === 'approve' ? 'paid' : 'rejected';
    const nextBookingStatus = action === 'approve' ? 'confirmed' : 'cancelled';

    await conn.query(
      `UPDATE booking 
       SET payment_status = ?, status = ? 
       WHERE booking_id = ?`,
      [nextPaymentStatus, nextBookingStatus, booking_id]
    );

    return res.status(200).json({
      success: true,
      message: `Booking status updated to ${nextPaymentStatus}`,
      data: {
        booking_id,
        payment_status: nextPaymentStatus,
        status: nextBookingStatus,
      },
    });
  } catch (error) {
    console.error('Admin verify slip error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }



});
// POST /api/booking/add-passengers
router.post('/add-passengers', upload.single('passpot_passenger'), async (req, res) => {
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

    // 2. ตรวจสอบไฟล์รูปภาพอย่างปลอดภัย 
    const passportFile = req.file;
    const uploadedPassportPath = passportFile ? passportFile.path : null;

    // 3. ตรวจสอบความถูกต้องของข้อมูล
    if (!bookingId || !Array.isArray(passengers) || passengers.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'booking_id and at least one passenger are required',
      });
    }

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

    const [result] = await conn.query(sql, [values]);

    return res.status(200).json({
      success: true,
      message: 'Passenger details saved successfully',
      data: {
        booking_id: bookingId,
        insertedRows: result.affectedRows,
      },
    });
  } catch (error) {
    console.error('Add passengers error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error',
      error: error.message 
    });
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
        b.member_id,
        b.total_price,
        b.payment_status,
        b.booking_date,
        t.tour_name
      FROM booking b
      LEFT JOIN tour_round r ON b.round_id = r.round_id
      LEFT JOIN tour t ON r.tour_id = t.tour_id
      WHERE b.member_id = ?
      ORDER BY b.booking_date DESC
    `;

    const [rows] = await conn.execute(sql, [memberId]);

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
export default router;