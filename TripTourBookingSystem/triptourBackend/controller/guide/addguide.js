import express from "express"; 
import { conn } from "../../config/db.js"; 
import { readFileSync } from 'fs';
import  admin  from "../../config/firebase.js"

export const router = express.Router(); 



router.post("/", async (req, res) => {
    const { 
        email, 
        password, 
        first_name, 
        last_name, 
        guide_code, 
        phone, 
        age, 
        birthday, 
        address 
    } = req.body;

    try {
        const userRecord = await admin.auth().createUser({
            email: email,
            password: password,
            displayName: `${first_name} ${last_name}`,
        });

        console.log(`Successfully created new user in Firebase: ${userRecord.uid}`);
        const google_id = userRecord.uid;
        const sql = `
            INSERT INTO guide (
                google_id, guide_code, first_name, last_name, email,
                age, birthday, phone, address, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
        `;

        const values = [
            google_id, guide_code, first_name, last_name, email,
            age, birthday, phone, address
        ];

        await conn.query(sql, values);

        res.status(201).json({
            status: "success",
            message: "สร้างบัญชีไกด์ใน Firebase และบันทึกข้อมูลในระบบสำเร็จ",
            email: email
        });

    } catch (error) {
        console.error("Error creating guide:", error);

        if (error.code === 'auth/email-already-exists') {
            return res.status(400).json({
                status: "error",
                message: "Email นี้ถูกใช้งานในระบบ Firebase แล้ว"
            });
        }

        res.status(500).json({
            status: "error",
            message: "เกิดข้อผิดพลาด: " + error.message
        });
    }
});

// ==========================================================
// GET GUIDE PROFILE
// ==========================================================

router.get(
    "/profile/:googleId",
    async (req, res) => {
        try {
            const {
                googleId
            } = req.params;

            // ==================================================
            // CHECK GOOGLE ID
            // ==================================================

            if (
                !googleId ||
                googleId.trim() === ""
            ) {
                return res.status(400).json({
                    success: false,
                    message:
                        "ไม่พบ google_id"
                });
            }

            // ==================================================
            // FIND GUIDE
            // ==================================================

            const [rows] =
                await conn.query(
                    `
                    SELECT
                        guide_id,
                        guide_code,
                        image_profile,
                        first_name,
                        last_name,
                        email,
                        age,
                        birthday,
                        phone,
                        address,
                        status,
                        google_id
                    FROM guide
                    WHERE google_id = ?
                    LIMIT 1
                    `,
                    [googleId]
                );

            // ==================================================
            // GUIDE NOT FOUND
            // ==================================================

            if (rows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message:
                        "ไม่พบข้อมูลไกด์"
                });
            }

            // ==================================================
            // RESPONSE
            // ==================================================

            return res.status(200).json({
                success: true,
                data: rows[0]
            });

        } catch (error) {
            console.error(
                "Get guide profile error:",
                error
            );

            return res.status(500).json({
                success: false,
                message:
                    "ไม่สามารถโหลดข้อมูลไกด์ได้"
            });
        }
    }
);

// ==========================================================
// UPDATE GUIDE PROFILE
// ==========================================================

router.put(
    "/profile/:googleId",
    async (req, res) => {
        try {
            const {
                googleId
            } = req.params;

            const {
                first_name,
                last_name,
                age,
                birthday,
                phone,
                address
            } = req.body;

            // ==================================================
            // CHECK GOOGLE ID
            // ==================================================

            if (
                !googleId ||
                googleId.trim() === ""
            ) {
                return res.status(400).json({
                    success: false,
                    message:
                        "ไม่พบ google_id"
                });
            }

            // ==================================================
            // CHECK GUIDE EXIST
            // ==================================================

            const [guideRows] =
                await conn.query(
                    `
                    SELECT guide_id
                    FROM guide
                    WHERE google_id = ?
                    LIMIT 1
                    `,
                    [googleId]
                );

            if (guideRows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message:
                        "ไม่พบข้อมูลไกด์"
                });
            }

            // ==================================================
            // VALIDATE AGE
            // ==================================================

            let ageValue = null;

            if (
                age !== null &&
                age !== undefined &&
                age.toString().trim() !== ""
            ) {
                ageValue = Number(age);

                if (
                    !Number.isInteger(
                        ageValue
                    ) ||
                    ageValue < 1 ||
                    ageValue > 120
                ) {
                    return res.status(400).json({
                        success: false,
                        message:
                            "อายุไม่ถูกต้อง"
                    });
                }
            }

            // ==================================================
            // UPDATE GUIDE
            // ==================================================

            await conn.query(
                `
                UPDATE guide
                SET
                    first_name = ?,
                    last_name = ?,
                    age = ?,
                    birthday = ?,
                    phone = ?,
                    address = ?
                WHERE google_id = ?
                `,
                [
                    first_name?.toString().trim() || null,
                    last_name?.toString().trim() || null,
                    ageValue,
                    birthday?.toString().trim() || null,
                    phone?.toString().trim() || null,
                    address?.toString().trim() || null,
                    googleId
                ]
            );

            // ==================================================
            // GET UPDATED GUIDE
            // ==================================================

            const [updatedRows] =
                await conn.query(
                    `
                    SELECT
                        guide_id,
                        guide_code,
                        image_profile,
                        first_name,
                        last_name,
                        email,
                        age,
                        birthday,
                        phone,
                        address,
                        status,
                        google_id
                    FROM guide
                    WHERE google_id = ?
                    LIMIT 1
                    `,
                    [googleId]
                );

            // ==================================================
            // RESPONSE
            // ==================================================

            return res.status(200).json({
                success: true,
                message:
                    "แก้ไขข้อมูลส่วนตัวสำเร็จ",
                data:
                    updatedRows[0]
            });

        } catch (error) {
            console.error(
                "Update guide profile error:",
                error
            );

            return res.status(500).json({
                success: false,
                message:
                    "ไม่สามารถแก้ไขข้อมูลไกด์ได้"
            });
        }
    }
);