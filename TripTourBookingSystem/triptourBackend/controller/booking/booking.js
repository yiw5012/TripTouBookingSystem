import express from 'express';
import multer from 'multer';
import generatePayload from 'promptpay-qr';
import { conn } from '../../config/db.js';
import { upload as cloudUpload } from '../middleware/upload.js';

export const router = express.Router();
const PROMPTPAY_ID = process.env.PROMPTPAY_ID || '0842985195';
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

    // Insert ลงตาราง booking ตาม Schema จริง
    // slip_image และ payment_date ต้องมีค่าเริ่มต้นเป็น NULL เพื่อให้รายการ pending ทำงานได้ก่อนแนบสลิป
    const [result] = await conn.query(
      `INSERT INTO booking (member_id, round_id, booking_date, total_price, status, payment_status, slip_image, payment_date)
       VALUES (?, ?, NOW(), ?, 'pending', 'pending', NULL, NULL)`,
      [member_id, round_id, total_price]
    );

    const bookingId = result.insertId;

    // สร้าง PromptPay QR Code
    const qrPayload = generatePayload(PROMPTPAY_ID, { amount: Number(total_price) || 0 });

    // ตั้งเวลา Timeout 15 นาที หากไม่มีการแนบสลิปจะปรับสถานะเป็น expired
    // ลบออกเจาก database เมื่อครบเวลา เด้งออก 
    setTimeout(async () => {
      await conn.query(
        `UPDATE booking SET payment_status = 'expired'
         WHERE booking_id = ? AND payment_status = 'pending'`,
        [bookingId]
      );
    }, 15 * 60 * 1000);

    return res.status(200).json({
      success: true,
      data: {
        order_id: bookingId, // ส่งกลับในชื่อ order_id หรือ booking_id เพื่อให้ Flutter ใช้งานต่อได้
        booking_id: bookingId,
        amount: total_price,
        status: 'pending',
        payment_status: 'pending',
        qr_code: qrPayload,
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
      `SELECT booking_id, member_id, round_id, total_price, status, payment_status, payment_date, slip_image 
       FROM booking WHERE booking_id = ?`,
      [bookingId]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const booking = rows[0];
    console.log(booking.payment_status)
    
    
    return res.status(200).json({
      success: true,
      data: {
        booking_id: booking.booking_id,
        status: booking.payment_status, // ส่ง payment_status กลับไปเช็กใน Flutter (pending, processing, paid, expired, rejected)
        booking_status: booking.status,
        amount: booking.total_price,
        slip_image: booking.slip_image,
        payment_date: booking.payment_date,
      },
    });
  } catch (error) {
    console.error('Get booking status error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// 3. แนบสลิปชำระเงิน (อัปเดต slip_image, payment_date และเปลี่ยน payment_status เป็น processing)
router.post('/confirm-payment', upload.single('slip_image'), async (req, res) => {
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

    const [rows] = await conn.query(
      'SELECT payment_status FROM booking WHERE booking_id = ?',
      [booking_id],
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (rows[0].payment_status === 'expired') {
      return res.status(400).json({ success: false, message: 'Booking has expired' });
    }

    await conn.query(
      `UPDATE booking 
       SET slip_image = ?, payment_status = 'paid', payment_date = NOW() 
       WHERE booking_id = ?`,
      [slip_image, booking_id],
    );

    return res.status(200).json({
      success: true,
      message: 'Payment slip submitted successfully',
      data: {
        booking_id,
        status: 'processing',
        payment_status: 'processing',
        slip_image,
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
      // ถ้ามีไฟล์อัปโหลดใหม่ให้ใช้ไฟล์อัปโหลด ถ้าไม่มีให้ใช้ path เดิมใน object
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

export default router;