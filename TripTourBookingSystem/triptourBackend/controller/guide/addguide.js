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

        const sql = `
            INSERT INTO Guide (
                guide_code, first_name, last_name, email,
                age, birthday, phone, address, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Active')
        `;

        const values = [
            guide_code, first_name, last_name, email,
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