import express from "express";
import { conn } from "../../config/db.js";
import admin from "../../config/firebase.js";

export const router = express.Router();

router.post("/", async (req, res) => {
  const {
    google_id,
    email,
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
    other,
    favorite_countries,
    image_passport,
    image_profile,
  } = req.body;

  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({
      status: "error",
      message: "รูปแบบอีเมลไม่ถูกต้อง"
    });
  }
  const cleanEmail = email.toLowerCase().trim();

  //Gender Formatting (Male / Female / Other)
  let genderValue = null;
  if (gender && typeof gender === 'string') {
    const formattedGender = gender.trim().charAt(0).toUpperCase() + gender.trim().slice(1).toLowerCase();
    if (['Male', 'Female', 'Other'].includes(formattedGender)) {
      genderValue = formattedGender;
    }
  }

  const passportImg = image_passport || 'default_passport.jpg';
  const profileImg = image_profile || 'default_profile.jpg';
  const safeNumberId = number_id || '0000000000000';

  const rawCountryList = Array.isArray(favorite_countries)
    ? favorite_countries
    : typeof favorite_countries === 'string'
      ? favorite_countries.split(',')
      : [];

  const countryIds = [...new Set(
    rawCountryList
      .map((item) => Number(String(item).trim()))
      .filter((id) => Number.isInteger(id) && id > 0)
  )];

  try {
    const [memberResult] = await conn.query(
      "INSERT INTO member (google_id, email, first_name, last_name, phone, number_id, image_passport, image_profile, birthday, address, gender, medicine, congenital_disease, allergic_list, others) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [google_id, email, first_name, last_name, phone, safeNumberId, passportImg, profileImg, birthday, address, genderValue, medicine, congenital_disease, allergic_list, other]
    );

    const memberId = memberResult.insertId;

    if (memberId && countryIds.length > 0) {
      for (const countryId of countryIds) {
        await conn.query(
          `INSERT INTO favorite (member_id, country_id)
           VALUES (?, ?)
           ON DUPLICATE KEY UPDATE country_id = country_id`,
          [memberId, countryId]
        );
      }
    }

    const roomUserId = google_id || String(memberId);
    const supportRoomId = roomUserId;
    const supportUserName = [first_name, last_name].filter(Boolean).join(' ').trim() || email;
    const now = Date.now();

    await admin.database().ref(`rooms/${supportRoomId}`).set({
      roomId: supportRoomId,
      roomName: 'Admin Support',
      userId: roomUserId,
      userName: supportUserName,
      lastMessage: 'สวัสดีค่ะ คุณสามารถสอบถามเรื่องที่ต้องการได้เลย',
      lastUpdated: now,
      unreadByAdmin: 0,
      createdAt: now,
      type: 'admin_support',
    });

    await admin.database().ref(`user_rooms/${roomUserId}`).update({
      [supportRoomId]: true,
    });

    await admin.database().ref(`messages/${supportRoomId}`).push().set({
      senderId: 'admin_01',
      senderRole: 'admin',
      senderEmail: "support@triptour.com",
      text: 'สวัสดีค่ะ คุณสามารถสอบถามเรื่องที่ต้องการได้เลย',
      timestamp: now,
    });

    res.json({ status: "success", message: "User registered successfully", userId: memberId });
  } catch (error) {
    console.error("❌ Backend Error Trace:", error);
    // Rollback: ลบ Firebase Auth ทิ้งทันทีหากการบันทึก MySQL หรือ Realtime DB ล้มเหลว
    if (google_id) {
      try {
        await admin.auth().deleteUser(google_id);
        console.log(`Rollback: Deleted orphaned Firebase Auth user (${google_id})`);
      } catch (rollbackErr) {
        console.error("Rollback failed:", rollbackErr.message);
      }
    }
    if (error && error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ status: 'error', message: error.message, sqlMessage: error.sqlMessage });
    }

    res.status(500).json({
      status: "error",
      message: error.message || 'Internal server error',
      sqlMessage: error.sqlMessage || null
    });
  }
});
