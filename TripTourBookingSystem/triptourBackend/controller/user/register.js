import express from "express";
import { conn } from "../../config/db.js";

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
      [google_id, email, first_name, last_name, phone, safeNumberId, passportImg, profileImg, birthday, address, gender, medicine, congenital_disease, allergic_list, other]
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

    res.json({ status: "success", message: "User registered successfully", userId: memberId });
  } catch (error) {
    console.error("❌ Backend Error Trace:", error);

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
