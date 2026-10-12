import express from "express"; 
import { conn } from "../../config/db.js"; 
import { readFileSync } from 'fs';
import  admin  from "../../config/firebase.js"
import { upload_guide } from "../middleware/upload.js";


const db = admin.firestore();
export const router = express.Router(); 


router.post("/", upload_guide.single('guideimage_profile'), async (req, res) => {
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
    const guideImage =  req.file?.path ?? null;

 let google_id = null;
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
                google_id, guide_code, image_profile, first_name, last_name, email,
                age, birthday, phone, address, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?,?, 'active')
        `;

        const values = [
            google_id, guide_code, guideImage ,first_name, last_name, email,
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
//ถ้าสร้าง Firebase Auth ไปแล้ว แต่ยิง MySQL ไม่สำเร็จ ให้สั่ง Rollback ลบ Firebase Auth ทิ้งทันที
        if (google_id) {
            try {
                await admin.auth().deleteUser(google_id);
                console.log(`Rollback: Deleted orphaned Firebase user (${google_id})`);
            } catch (rollbackError) {
                console.error("Rollback failed:", rollbackError.message);
            }
        }

        // จัดการกรณีอีเมลซ้ำใน Firebase
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
    "/profile/:googleId", upload_guide.single('guideimage_profile'),
    async (req, res) => {
        try {
            const {
                googleId
            } = req.params;

            const {
                first_name,
                last_name,
                email,
                age,
                birthday,
                phone,
                address,
                password
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

            const currentGuide = guideRows[0];

            const newGuideImage = req.file?.path ?? currentGuide.image_profile;

            const firebaseUpdateData = {};

            // ตรวจสอบและอัปเดตอีเมล
            const cleanEmail = email?.toString().trim().toLowerCase();
            if (cleanEmail && cleanEmail !== currentGuide.email) {
                firebaseUpdateData.email = cleanEmail;
            }
           if (password !== null && password !== undefined && password.toString().trim() !== "") {
                const passwordText = password.toString().trim();
                if (passwordText.length < 6) {
                    return res.status(400).json({
                        success: false,
                        message: "รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร"
                    });
                }
                firebaseUpdateData.password = passwordText;
            }
            if (Object.keys(firebaseUpdateData).length > 0) {
                try {
                    await admin.auth().updateUser(googleId, firebaseUpdateData);
                    console.log(`[Firebase Auth] Updated credentials for guide: ${googleId}`);
                } catch (fbError) {
                    console.error("Firebase update user error:", fbError);
                    if (fbError.code === 'auth/email-already-exists') {
                        return res.status(400).json({
                            success: false,
                            message: "อีเมลนี้ถูกใช้งานในระบบ Firebase แล้ว"
                        });
                    }
                    return res.status(500).json({
                        success: false,
                        message: "เกิดข้อผิดพลาดในการอัปเดตข้อมูลบัญชีใน Firebase: " + fbError.message
                    });
                }
            }

            // 📌 อัปเดตข้อมูลลงตาราง guide ใน MySQL
            const updatedEmail = cleanEmail || currentGuide.email;
            // ==================================================
            // UPDATE GUIDE
            // ==================================================

           await conn.query(
                `
                UPDATE guide
                SET 
                    image_profile = ?,
                    first_name = ?,
                    last_name = ?,
                    email = ?,
                    age = ?,
                    birthday = ?,
                    phone = ?,
                    address = ?
                WHERE google_id = ?
                `,
                [
                    newGuideImage,
                    first_name?.toString().trim() || null,
                    last_name?.toString().trim() || null,
                    updatedEmail,
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

            const [updatedRows] = await conn.query(
                `
                SELECT
                    guide_id, guide_code, image_profile, first_name, last_name,
                    email, age, birthday, phone, address, status, google_id
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